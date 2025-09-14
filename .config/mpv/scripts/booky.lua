-- booky.lua
--
-- A bookmark menu for mpv
--
-- Usage:
--   b                    - Add current video to bookmarks
--   B                    - Show bookmarks menu
--   ctrl+shift+b         - Clear all bookmarks
--
-- Script messages:
--   script-message booky-add                   - Add current video to bookmarks
--   script-message booky-remove <path>        - Remove specific bookmark by path
--   script-message booky-clear-all            - Clear all bookmarks
--
-- Configuration: script-opts/booky.conf

local options = {
    -- File path gets expanded, leave empty for in-memory bookmarks
    bookmarks_path = "~~/bookmarks.log",

    -- How many entries to display in menu
    entries = 20,

    -- Display navigation to older/newer entries
    pagination = true,

    -- Check if files still exist
    hide_deleted = true,

    -- Date format https://www.lua.org/pil/22.1.html
    timestamp_format = "%Y-%m-%d %H:%M:%S",

    -- Display titles instead of filenames when available
    use_titles = true,

    -- Truncate titles to n characters, 0 to disable
    truncate_titles = 60,

    -- Meant for use in auto profiles
    enabled = true,

    -- Keybinds for vanilla menu
    up_binding = "UP WHEEL_UP",
    down_binding = "DOWN WHEEL_DOWN",
    select_binding = "RIGHT ENTER",
    append_binding = "Shift+RIGHT Shift+ENTER",
    close_binding = "LEFT ESC",
    remove_binding = "DEL"
}

local script_name = mp.get_script_name()

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options, "booky")

local assdraw = require "mp.assdraw"

local osd = mp.create_osd_overlay("ass-events")
osd.z = 2000
local osd_update = nil
local width, height = 0, 0
local margin_top, margin_bottom = 0, 0
local font_size = mp.get_property_number("osd-font-size") or 55

local fakeio = {data = "", cursor = 0, offset = 0, file = nil}
function fakeio:setvbuf(mode) end
function fakeio:flush()
    self.cursor = self.offset + #self.data
end
function fakeio:read(format)
    local out = ""
    if self.cursor < self.offset then
        self.file:seek("set", self.cursor)
        out = self.file:read(format)
        format = format - #out
        self.cursor = self.cursor + #out
    end
    if format > 0 then
        out = out .. self.data:sub(self.cursor - self.offset, self.cursor - self.offset + format)
        self.cursor = self.cursor + format
    end
    return out
end
function fakeio:seek(whence, offset)
    local base = 0
    offset = offset or 0
    if whence == "end" then
        base = self.offset + #self.data
    end
    self.cursor = base + offset
    return self.cursor
end
function fakeio:write(...)
    local args = {...}
    for i, v in ipairs(args) do
        self.data = self.data .. v
    end
end

local bookmarks, bookmarks_path

if options.bookmarks_path ~= "" then
    bookmarks_path = mp.command_native({"expand-path", options.bookmarks_path})
    bookmarks = io.open(bookmarks_path, "a+b")
end
if bookmarks == nil then
    if bookmarks_path then
        mp.msg.warn("cannot write to bookmarks file " .. options.bookmarks_path .. ", new entries will not be saved to disk")
        bookmarks = io.open(bookmarks_path, "rb")
        if bookmarks then
            fakeio.offset = bookmarks:seek("end")
            fakeio.file = bookmarks
        end
    end
    bookmarks = fakeio
end
if bookmarks then
    bookmarks:setvbuf("full")
end

local event_loop_exhausted = false
local uosc_available = false
local dyn_menu = nil
local menu_shown = false
local last_state = nil
local menu_data = nil
local palette = false
local search_words = nil
local search_query = nil
local new_loadfile = nil
local normalize_path = nil

local data_protocols = {
    edl = true,
    data = true,
    null = true,
    memory = true,
    hex = true,
    fd = true,
    fdclose = true,
    mf = true
}

local stacked_protocols = {
    ffmpeg = true,
    lavf = true,
    appending = true,
    file = true,
    archive = true,
    slice = true
}

local device_protocols = {
    bd = true,
    br = true,
    bluray = true,
    cdda = true,
    dvb = true,
    dvd = true,
    dvdnav = true
}

function utf8_char_bytes(str, i)
    local char_byte = str:byte(i)
    local max_bytes = #str - i + 1
    if char_byte < 0xC0 then
        return math.min(max_bytes, 1)
    elseif char_byte < 0xE0 then
        return math.min(max_bytes, 2)
    elseif char_byte < 0xF0 then
        return math.min(max_bytes, 3)
    elseif char_byte < 0xF8 then
        return math.min(max_bytes, 4)
    else
        return math.min(max_bytes, 1)
    end
end

function utf8_iter(str)
    local byte_start = 1
    return function()
        local start = byte_start
        if #str < start then return nil end
        local byte_count = utf8_char_bytes(str, start)
        byte_start = start + byte_count
        return start, str:sub(start, byte_start - 1)
    end
end

function utf8_table(str)
    local t = {}
    local width = 0
    for _, char in utf8_iter(str) do
        width = width + (#char > 2 and 2 or 1)
        table.insert(t, char)
    end
    return t, width
end

function utf8_subwidth(t, start_index, end_index)
    local index = 1
    local substr = ""
    for _, char in ipairs(t) do
        if start_index <= index and index <= end_index then
            local width = #char > 2 and 2 or 1
            index = index + width
            substr = substr .. char
        end
    end
    return substr, index
end

function utf8_subwidth_back(t, num_chars)
    local index = 0
    local substr = ""
    for i = #t, 1, -1 do
        if num_chars > index then
            local width = #t[i] > 2 and 2 or 1
            index = index + width
            substr = t[i] .. substr
        end
    end
    return substr
end

function utf8_to_unicode(str, i)
    local byte_count = utf8_char_bytes(str, i)
    local char_byte = str:byte(i)
    local unicode = char_byte
    if byte_count ~= 1 then
        local shift = 2 ^ (8 - byte_count)
        char_byte = char_byte - math.floor(0xFF / shift) * shift
        unicode = char_byte * (2 ^ 6) ^ (byte_count - 1)
    end
    for j = 2, byte_count do
        char_byte = str:byte(i + j - 1) - 0x80
        unicode = unicode + char_byte * (2 ^ 6) ^ (byte_count - j)
    end
    return math.floor(unicode + 0.5)
end

function ass_clean(str)
    str = str:gsub("\\", "\\\239\187\191")
    str = str:gsub("{", "\\{")
    str = str:gsub("}", "\\}")
    return str
end

-- Extended from https://stackoverflow.com/a/73283799 with zero-width handling from uosc
function unaccent(str)
    local unimask = "[%z\1-\127\194-\244][\128-\191]*"

    -- "Basic Latin".."Latin-1 Supplement".."Latin Extended-A".."Latin Extended-B"
    local charmap =
    "AÀÁÂÃÄÅĀĂĄǍǞǠǺȀȂȦȺAEÆǢǼ"..
    "BßƁƂƄɃ"..
    "CÇĆĈĊČƆƇȻ"..
    "DÐĎĐƉƊDZƻǄǱDzǅǲ"..
    "EÈÉÊËĒĔĖĘĚƎƏƐȄȆȨɆ"..
    "FƑ"..
    "GĜĞĠĢƓǤǦǴ"..
    "HĤĦȞHuǶ"..
    "IÌÍÎÏĨĪĬĮİƖƗǏȈȊIJĲ"..
    "JĴɈ"..
    "KĶƘǨ"..
    "LĹĻĽĿŁȽLJǇLjǈ"..
    "NÑŃŅŇŊƝǸȠNJǊNjǋ"..
    "OÒÓÔÕÖØŌŎŐƟƠǑǪǬǾȌȎȪȬȮȰOEŒOIƢOUȢ"..
    "PÞƤǷ"..
    "QɊ"..
    "RŔŖŘȐȒɌ"..
    "SŚŜŞŠƧƩƪƼȘ"..
    "TŢŤŦƬƮȚȾ"..
    "UÙÚÛÜŨŪŬŮŰŲƯƱƲȔȖɄǓǕǗǙǛ"..
    "VɅ"..
    "WŴƜ"..
    "YÝŶŸƳȜȲɎ"..
    "ZŹŻŽƵƷƸǮȤ"..
    "aàáâãäåāăąǎǟǡǻȁȃȧaeæǣǽ"..
    "bƀƃƅ"..
    "cçćĉċčƈȼ"..
    "dðƌƋƍȡďđdbȸdzǆǳ"..
    "eèéêëēĕėęěǝȅȇȩɇ"..
    "fƒ"..
    "gĝğġģƔǥǧǵ"..
    "hĥħȟhvƕ"..
    "iìíîïĩīĭįıǐȉȋijĳ"..
    "jĵǰȷɉ"..
    "kķĸƙǩ"..
    "lĺļľŀłƚƛȴljǉ"..
    "nñńņňŉŋƞǹȵnjǌ"..
    "oòóôõöøōŏőơǒǫǭǿȍȏȫȭȯȱoeœoiƣouȣ"..
    "pþƥƿ"..
    "qɋqpȹ"..
    "rŕŗřƦȑȓɍ"..
    "sśŝşšſƨƽșȿ"..
    "tţťŧƫƭțȶtsƾ"..
    "uùúûüũūŭůűųưǔǖǘǚǜȕȗ"..
    "wŵ"..
    "yýÿŷƴȝȳɏ"..
    "zźżžƶƹƺǯȥɀ"

    local zero_width_blocks = {
        {0x0000,  0x001F}, -- C0
        {0x007F,  0x009F}, -- Delete + C1
        {0x034F,  0x034F}, -- combining grapheme joiner
        {0x061C,  0x061C}, -- Arabic Letter Strong
        {0x200B,  0x200F}, -- {zero-width space, zero-width non-joiner, zero-width joiner, left-to-right mark, right-to-left mark}
        {0x2028,  0x202E}, -- {line separator, paragraph separator, Left-to-Right Embedding, Right-to-Left Embedding, Pop Directional Format, Left-to-Right Override, Right-to-Left Override}
        {0x2060,  0x2060}, -- word joiner
        {0x2066,  0x2069}, -- {Left-to-Right Isolate, Right-to-Left Isolate, First Strong Isolate, Pop Directional Isolate}
        {0xFEFF,  0xFEFF}, -- zero-width non-breaking space
        -- Some other characters can also be combined https://en.wikipedia.org/wiki/Combining_character
        {0x0300,  0x036F}, -- Combining Diacritical Marks    0 BMP  Inherited
        {0x1AB0,  0x1AFF}, -- Combining Diacritical Marks Extended   0 BMP  Inherited
        {0x1DC0,  0x1DFF}, -- Combining Diacritical Marks Supplement     0 BMP  Inherited
        {0x20D0,  0x20FF}, -- Combining Diacritical Marks for Symbols    0 BMP  Inherited
        {0xFE20,  0xFE2F}, -- Combining Half Marks   0 BMP  Cyrillic (2 characters), Inherited (14 characters)
        -- Egyptian Hieroglyph Format Controls and Shorthand format Controls
        {0x13430, 0x1345F}, -- Egyptian Hieroglyph Format Controls   1 SMP  Egyptian Hieroglyphs
        {0x1BCA0, 0x1BCAF}, -- Shorthand Format Controls     1 SMP  Common
        -- not sure how to deal with those https://en.wikipedia.org/wiki/Spacing_Modifier_Letters
        {0x02B0,  0x02FF}, -- Spacing Modifier Letters   0 BMP  Bopomofo (2 characters), Latin (14 characters), Common (64 characters)
    }

    return str:gsub(unimask, function(unichar)
        local unicode = utf8_to_unicode(unichar, 1)
        for _, block in ipairs(zero_width_blocks) do
            if unicode >= block[1] and unicode <= block[2] then
                return ""
            end
        end

        return unichar:match("%a") or charmap:match("(%a+)[^%a]-"..(unichar:gsub("[%(%)%.%%%+%-%*%?%[%^%$]", "%%%1")))
    end)
end

function shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function has_protocol(path)
    return path:find("^%a[%w.+-]-://") or path:find("^%a[%w.+-]-:%?")
end

function normalize(path)
    if normalize_path ~= nil then
        if normalize_path then
            -- don't normalize magnet-style paths
            local protocol_start, protocol_end, protocol = path:find("^(%a[%w.+-]-):%?")
            if not protocol_end then
                path = mp.command_native({"normalize-path", path})
            end
        else
            -- TODO: implement the basics of path normalization ourselves for mpv 0.38.0 and under
            local directory = mp.get_property("working-directory", "")
            if not has_protocol(path) then
                path = mp.utils.join_path(directory, path)
            end
        end
        return path
    end

    normalize_path = false

    local commands = mp.get_property_native("command-list", {})
    for _, command in ipairs(commands) do
        if command.name == "loadfile" then
            for _, arg in ipairs(command.args) do
                if arg.name == "index" then
                    new_loadfile = true
                    break
                end
            end
        end
        if command.name == "normalize-path" then
            normalize_path = true
            break
        end
    end
    return normalize(path)
end

function loadfile_compat(path)
    if new_loadfile ~= nil then
        if new_loadfile then
            return {"-1", path}
        end
        return {path}
    end

    new_loadfile = false

    local commands = mp.get_property_native("command-list", {})
    for _, command in ipairs(commands) do
        if command.name == "loadfile" then
            for _, arg in ipairs(command.args) do
                if arg.name == "index" then
                    new_loadfile = true
                    return {"-1", path}
                end
            end
            return {path}
        end
    end
    return {path}
end

function menu_json(menu_items, page)
    local title = "Bookmarks (booky)"
    if options.pagination or page ~= 1 then
        title = title .. " - Page " .. page
    end

    local menu = {
        type = "booky-bookmarks",
        title = title,
        items = menu_items,
        on_close = {"script-message-to", script_name, "booky-clear"}
    }

    return menu
end

function uosc_update()
    local json = mp.utils.format_json(menu_data) or "{}"
	local cmd = menu_shown and "update-menu" or "open-menu"
    mp.commandv("script-message-to", "uosc", cmd, json)
end

function update_dimensions()
    width, height = mp.get_osd_size()
    osd.res_x = width
    osd.res_y = height
    draw_menu()
end

if mp.utils.shared_script_property_set then
    function update_margins()
        local shared_props = mp.get_property_native("shared-script-properties")
        local val = shared_props["osc-margins"]
        if val then
            -- formatted as "%f,%f,%f,%f" with left, right, top, bottom, each
            -- value being the border size as ratio of the window size (0.0-1.0)
            local vals = {}
            for v in string.gmatch(val, "[^,]+") do
                vals[#vals + 1] = tonumber(v)
            end
            margin_top = vals[3] -- top
            margin_bottom = vals[4] -- bottom
        else
            margin_top = 0
            margin_bottom = 0
        end
        draw_menu()
    end
else
    function update_margins()
        local val = mp.get_property_native("user-data/osc/margins")
        if val then
            margin_top = val.t
            margin_bottom = val.b
        else
            margin_top = 0
            margin_bottom = 0
        end
        draw_menu()
    end
end

function bind_keys(keys, name, func, opts)
    if not keys then
        mp.add_forced_key_binding(keys, name, func, opts)
        return
    end
    local i = 1
    for key in keys:gmatch("[^%s]+") do
        local prefix = i == 1 and "" or i
        mp.add_forced_key_binding(key, name .. prefix, func, opts)
        i = i + 1
    end
end

function unbind_keys(keys, name)
    if not keys then
        mp.remove_key_binding(name)
        return
    end
    local i = 1
    for key in keys:gmatch("[^%s]+") do
        local prefix = i == 1 and "" or i
        mp.remove_key_binding(name .. prefix)
        i = i + 1
    end
end

function open_menu()
    menu_shown = true

    update_dimensions()
    mp.observe_property("osd-dimensions", "native", update_dimensions)
    mp.observe_property("video-out-params", "native", update_dimensions)
    local margin_prop = mp.utils.shared_script_property_set and "shared-script-properties" or "user-data/osc/margins"
    mp.observe_property(margin_prop, "native", update_margins)

    local function select_item(append)
        local item = menu_data.items[last_state.selected_index]
        if not item then return end
        if not item.keep_open then
            close_menu()
        end
        if append and item.value[1] == "loadfile" then
            -- bail if file is already in playlist
            local playlist = mp.get_property_native("playlist", {})
            for i = 1, #playlist do
                local playlist_file = playlist[i].filename
                local display_path, save_path, effective_path, effective_protocol, is_remote, file_options = path_info(playlist_file)
                if not is_remote then
                    playlist_file = normalize(save_path)
                end
                if item.value[2] == playlist_file then
                    return
                end
            end
            item.value[3] = "append-play"
        end
        mp.commandv(unpack(item.value))
    end

    bind_keys(options.up_binding, "move_up", function()
        last_state.selected_index = math.max(last_state.selected_index - 1, 1)
        draw_menu()
    end, { repeatable = true })
    bind_keys(options.down_binding, "move_down", function()
        last_state.selected_index = math.min(last_state.selected_index + 1, #menu_data.items)
        draw_menu()
    end, { repeatable = true })
    bind_keys(options.select_binding, "select", select_item)
    bind_keys(options.append_binding, "append", function()
        select_item(true)
    end)
    bind_keys(options.close_binding, "close", close_menu)
    bind_keys(options.remove_binding, "remove", function()
        if last_state and last_state.selected_index and menu_data and menu_data.items then
            local selected_item = menu_data.items[last_state.selected_index]
            if selected_item and selected_item.bookmark_path then
                booky_remove(selected_item.bookmark_path)
            end
        end
    end)
    osd.hidden = false
    draw_menu()
end

function draw_menu()
    if not menu_data then return end
    if not menu_shown then
        open_menu()
    end

    local num_options = #menu_data.items > 0 and #menu_data.items + 1 or 1
    last_state.selected_index = math.min(last_state.selected_index, #menu_data.items)

    local function get_scrolled_lines()
        local output_height = height - margin_top * height - margin_bottom * height - 0.2 * font_size + 0.5
        local screen_lines = math.max(math.floor(output_height / font_size), 1)
        local max_scroll = math.max(num_options - screen_lines, 0)
        return math.min(math.max(last_state.selected_index - math.ceil(screen_lines / 2), 0), max_scroll) - 1
    end

    local ass = assdraw.ass_new()
    local curtain_opacity = 0.7

    local alpha = 255 - math.ceil(255 * curtain_opacity)
    ass.text = string.format("{\\pos(0,0)\\rDefault\\an7\\1c&H000000&\\alpha&H%X&}", alpha)
    ass:draw_start()
    ass:rect_cw(0, 0, width, height)
    ass:draw_stop()
    ass:new_event()

    ass:append("{\\rDefault\\pos("..(0.3 * font_size).."," .. (margin_top * height + 0.1 * font_size) .. ")\\an7\\fs" .. font_size .. "\\bord2\\q2\\b1}" .. ass_clean(menu_data.title) .. "{\\b0}")
    ass:new_event()

    local scrolled_lines = get_scrolled_lines() - 1
    local pos_y = margin_top * height - scrolled_lines * font_size + 0.2 * font_size + 0.5
    local clip_top = math.floor(margin_top * height + font_size + 0.2 * font_size + 0.5)
    local clip_bottom = math.floor((1 - margin_bottom) * height + 0.5)
    local clipping_coordinates = "0," .. clip_top .. "," .. width .. "," .. clip_bottom

    if #menu_data.items > 0 then
        local menu_index = 0
        for i = 1, #menu_data.items do
            local item = menu_data.items[i]
            if item.title then
                local icon
                local separator = last_state.selected_index == i and "{\\alpha&HFF&}●{\\alpha&H00&}  - " or "{\\alpha&HFF&}●{\\alpha&H00&} - "
                if item.icon == "spinner" then
                    separator = "⟳ "
                elseif item.icon == "navigate_next" then
                    icon = last_state.selected_index == i and "▶" or "▷"
                elseif item.icon == "navigate_before" then
                    icon = last_state.selected_index == i and "◀" or "◁"
                else
                    icon = last_state.selected_index == i and "●" or "○"
                end
                ass:new_event()
                ass:pos(0.3 * font_size, pos_y + menu_index * font_size)
                ass:append("{\\rDefault\\fnmonospace\\an1\\fs" .. font_size .. "\\bord2\\q2\\clip(" .. clipping_coordinates .. ")}"..separator.."{\\rDefault\\an7\\fs" .. font_size .. "\\bord2\\q2}" .. ass_clean(item.title))
                if icon then
                    ass:new_event()
                    ass:pos(0.6 * font_size, pos_y + menu_index * font_size)
                    ass:append("{\\rDefault\\fnmonospace\\an2\\fs" .. font_size .. "\\bord2\\q2\\clip(" .. clipping_coordinates .. ")}" .. icon)
                end
                menu_index = menu_index + 1
            end
        end
    else
        ass:pos(0.3 * font_size, pos_y)
        ass:append("{\\rDefault\\an1\\fs" .. font_size .. "\\bord2\\q2\\clip(" .. clipping_coordinates .. ")}")
        ass:append("No entries")
    end

    osd_update = nil
    osd.data = ass.text
    osd:update()
end

function get_full_path()
    local path = mp.get_property("path")
    if path == nil or path == "-" or path == "/dev/stdin" then return end

    local display_path, save_path, effective_path, effective_protocol, is_remote, file_options = path_info(path)

    if not is_remote then
        path = normalize(save_path)
    end

    return path, display_path, save_path, effective_path, effective_protocol, is_remote, file_options
end

function path_info(full_path)
    local function resolve(effective_path, save_path, display_path, last_protocol, is_remote)
        local protocol_start, protocol_end, protocol = display_path:find("^(%a[%w.+-]-)://")

        if protocol == "ytdl" then
            -- for direct video access ytdl://videoID and ytsearch:
            is_remote = true
        elseif protocol and not stacked_protocols[protocol] then
            local input_path, file_options
            if device_protocols[protocol] then
                input_path, file_options = display_path:match("(.-) %-%-opt=(.+)")
                effective_path = file_options and file_options:match(".+=(.*)")
                if protocol == "dvb" then
                    is_remote = true
                    if not effective_path then
                        effective_path = display_path
                        input_path = display_path:sub(protocol_end + 1)
                    end
                end
                display_path = input_path or display_path
            else
                is_remote = true
                display_path = display_path:sub(protocol_end + 1)
            end
            return display_path, save_path, effective_path, protocol, is_remote, file_options
        end

        if not protocol_end then
            if last_protocol == "ytdl" then
                display_path = "ytdl://" .. display_path
            end
            return display_path, save_path, effective_path, last_protocol, is_remote, nil
        end

        display_path = display_path:sub(protocol_end + 1)

        if protocol == "archive" then
            local main_path, archive_path, filename = display_path:gsub("%%7C", "|"):match("(.-)(|.-[\\/])(.+)")
            if not main_path then
                local main_path = display_path:match("(.-)|")
                effective_path = normalize(main_path or display_path)
                _, save_path, effective_path, protocol, is_remote, file_options = resolve(effective_path, save_path, display_path, protocol, is_remote)
                effective_path = normalize(effective_path)
                save_path = "archive://" .. (save_path or effective_path)
                if main_path then
                    save_path = save_path .. display_path:match("|(.-)")
                end
            else
                display_path, save_path, _, protocol, is_remote, file_options = resolve(main_path, save_path, main_path, protocol, is_remote)
                effective_path = normalize(display_path)
                save_path = save_path or effective_path
                save_path = "archive://" .. save_path .. (save_path:find("archive://") and archive_path:gsub("|", "%%7C") or archive_path) .. filename
                _, main_path = mp.utils.split_path(main_path)
                _, filename = mp.utils.split_path(filename)
                display_path = main_path .. ": " .. filename
            end
        elseif protocol == "slice" then
            if effective_path then
                effective_path = effective_path:match(".-@(.*)") or effective_path
            end
            display_path = display_path:match(".-@(.*)") or display_path
        end

        return resolve(effective_path, save_path, display_path, protocol, is_remote)
    end

    -- don't resolve magnet-style paths
    local protocol_start, protocol_end, protocol = full_path:find("^(%a[%w.+-]-):%?")
    if protocol_end then
        return full_path, full_path, protocol, true, nil
    end

    local display_path, save_path, effective_path, effective_protocol, is_remote, file_options = resolve(nil, nil, full_path, nil, false)
    effective_path = effective_path or display_path
    save_path = save_path or effective_path
    if is_remote and not file_options then
        display_path = display_path:gsub("%%(%x%x)", function(hex)
            return string.char(tonumber(hex, 16))
        end)
    end

    return display_path, save_path, effective_path, effective_protocol, is_remote, file_options
end

function add_bookmark(display)
    local full_path, display_path, save_path, effective_path, effective_protocol, is_remote, file_options = get_full_path()
    if full_path == nil then
        mp.msg.debug("cannot get full path to file")
        if display then
            mp.osd_message("[booky] cannot get full path to file")
        end
        return
    end

    if data_protocols[effective_protocol] then
        mp.msg.debug("not bookmarking file with " .. effective_protocol .. " protocol")
        if display then
            mp.osd_message("[booky] not bookmarking file with " .. effective_protocol .. " protocol")
        end
        return
    end

    -- Check if bookmark already exists
    if is_bookmarked(full_path) then
        if display then
            mp.osd_message("[booky] file already bookmarked")
        end
        return
    end

    if effective_protocol == "bd" or effective_protocol == "br" or effective_protocol == "bluray" then
        full_path = full_path .. " --opt=bluray-device=" .. mp.get_property("bluray-device", "")
    elseif effective_protocol == "cdda" then
        full_path = full_path .. " --opt=cdrom-device=" .. mp.get_property("cdrom-device", "")
    elseif effective_protocol == "dvb" then
        local dvb_program = mp.get_property("dvbin-prog", "")
        if dvb_program ~= "" then
            full_path = full_path .. " --opt=dvbin-prog=" .. dvb_program
        end
    elseif effective_protocol == "dvd" or effective_protocol == "dvdnav" then
        full_path = full_path .. " --opt=dvd-angle=" .. mp.get_property("dvd-angle", "1") .. ",dvd-device=" .. mp.get_property("dvd-device", "")
    end

    mp.msg.debug("bookmarking file " .. full_path)
    if display then
        mp.osd_message("[booky] bookmarked " .. (display_path or full_path))
    end

    local playlist_pos = mp.get_property_number("playlist-pos") or -1
    local title = playlist_pos > -1 and mp.get_property("playlist/"..playlist_pos.."/title") or ""
    local title_length = #title
    local timestamp = os.time()

    -- format: <timestamp>,<title length>,<title>,<path>,<entry length>
    local entry = timestamp .. "," .. (title_length > 0 and title_length or "") .. "," .. title .. "," .. full_path
    local entry_length = #entry

    bookmarks:seek("end")
    bookmarks:write(entry .. "," .. entry_length, "\n")
    bookmarks:flush()

    if dyn_menu then
        dyn_menu_update()
    end
end

function is_bookmarked(target_path)
    if not bookmarks then return false end
    
    bookmarks:seek("set", 0)
    local line
    while true do
        line = bookmarks:read("*l")
        if not line then break end
        
        local entry_length = line:match(",(%d+)$")
        if entry_length then
            entry_length = tonumber(entry_length)
            local entry = line:sub(1, entry_length)
            local parts = {}
            local start = 1
            local comma_count = 0
            
            for i = 1, #entry do
                if entry:sub(i, i) == "," then
                    comma_count = comma_count + 1
                    if comma_count == 3 then
                        local path = entry:sub(i + 1)
                        if path == target_path then
                            return true
                        end
                        break
                    end
                end
            end
        end
    end
    return false
end

function remove_bookmark(target_path)
    if not bookmarks then return false end
    
    local lines = {}
    bookmarks:seek("set", 0)
    local line
    local found = false
    
    while true do
        line = bookmarks:read("*l")
        if not line then break end
        
        local entry_length = line:match(",(%d+)$")
        if entry_length then
            entry_length = tonumber(entry_length)
            local entry = line:sub(1, entry_length)
            local parts = {}
            local start = 1
            local comma_count = 0
            local should_keep = true
            
            for i = 1, #entry do
                if entry:sub(i, i) == "," then
                    comma_count = comma_count + 1
                    if comma_count == 3 then
                        local path = entry:sub(i + 1)
                        if path == target_path then
                            should_keep = false
                            found = true
                        end
                        break
                    end
                end
            end
            
            if should_keep then
                table.insert(lines, line)
            end
        end
    end
    
    if found then
        -- Rewrite the file
        bookmarks:close()
        bookmarks = io.open(bookmarks_path, "w+b")
        if bookmarks then
            for _, line in ipairs(lines) do
                bookmarks:write(line .. "\n")
            end
            bookmarks:flush()
            bookmarks:setvbuf("full")
        end
        
        if dyn_menu then
            dyn_menu_update()
        end
    end
    
    return found
end

function show_bookmarks()
    mp.msg.info("show_bookmarks called")
    if event_loop_exhausted then 
        mp.msg.info("event_loop_exhausted, returning")
        return 
    end
    event_loop_exhausted = true

    local should_close = menu_shown
    if should_close then
        mp.msg.info("menu already shown, closing")
        booky_close()
        event_loop_exhausted = false
        return
    end

    mp.msg.info("creating menu items")
    local menu_items = {}
    
    -- Add "Add bookmark" option at the top
    menu_items[1] = {
        title = "📌 Bookmark current video",
        hint = "Add current video to bookmarks", 
        value = {"script-message", "booky-add"},
        keep_open = true
    }
    
    if not bookmarks then
        mp.msg.info("no bookmarks file")
        menu_items[2] = {
            title = "No bookmarks file",
            hint = "Add your first bookmark with 'b'",
            keep_open = true
        }
    else
        mp.msg.info("reading bookmarks from file")
        bookmarks:seek("set", 0)
        local line
        local index = 2
        
        -- Read all bookmarks and add them to menu
        while true do
            line = bookmarks:read("*l")
            if not line then break end
            
            local entry_length = line:match(",(%d+)$")
            if entry_length then
                entry_length = tonumber(entry_length)
                local entry = line:sub(1, entry_length)
                
                -- Parse entry: timestamp,title_length,title,path
                local timestamp_str, title_length_str, remaining = entry:match("([^,]*),(%d*),(.*)")
                if timestamp_str and remaining then
                    local title_length = tonumber(title_length_str) or 0
                    local title = ""
                    local path = remaining
                    
                    if title_length > 0 then
                        title = remaining:sub(1, title_length)
                        path = remaining:sub(title_length + 2) -- +2 for the comma
                    else
                        -- No title, the remaining part is just the path
                        path = remaining
                    end
                    
                    local display_title = title
                    if display_title == "" then
                        -- Extract filename from path
                        display_title = path:match("([^/\\]+)$") or path
                    end
                    
                    if options.use_titles and options.truncate_titles > 0 and #display_title > options.truncate_titles then
                        display_title = display_title:sub(1, options.truncate_titles) .. "..."
                    end
                    
                    local timestamp = tonumber(timestamp_str)
                    local hint = timestamp and os.date(options.timestamp_format, timestamp) or timestamp_str
                    
                    if options.hide_deleted then
                        local file_exists = mp.utils.file_info(path)
                        if not file_exists then
                            hint = hint .. " (missing)"
                        end
                    end
                    
                    menu_items[index] = {
                        title = display_title,
                        hint = hint,
                        value = {"loadfile", path, "replace"}
                    }
                    index = index + 1
                    mp.msg.info("added bookmark: " .. display_title)
                end
            end
        end
        
        if index == 2 then
            mp.msg.info("no bookmarks found")
            menu_items[2] = {
                title = "No bookmarks yet",
                hint = "Add your first bookmark with 'b'",
                keep_open = true
            }
        end
    end

    mp.msg.info("creating menu data with " .. #menu_items .. " items")
    menu_data = menu_json(menu_items, 1)
    -- menu_shown = true

    mp.msg.info("uosc_available: " .. tostring(uosc_available))
    if uosc_available then
        mp.msg.info("calling uosc_update")
		menu_shown = false
        uosc_update()
		menu_shown = true
    else
		open_menu()
    end
    
    event_loop_exhausted = false
    mp.msg.info("show_bookmarks completed")
end

function idle()
    event_loop_exhausted = false
    if osd_update then
        osd_update = nil
        osd:update()
    end
end

mp.register_script_message("uosc-version", function(version)
    mp.msg.info("uosc version detected: " .. version)
    local function semver_comp(v1, v2)
        local v1_iterator = v1:gmatch("%d+")
        local v2_iterator = v2:gmatch("%d+")
        for v2_num_str in v2_iterator do
            local v1_num_str = v1_iterator()
            if not v1_num_str then return true end
            local v1_num = tonumber(v1_num_str)
            local v2_num = tonumber(v2_num_str)
            if v1_num < v2_num then return true end
            if v1_num > v2_num then return false end
        end
        return false
    end

    local min_version = "5.0.0"
    uosc_available = not semver_comp(version, min_version)
    mp.msg.info("uosc_available set to: " .. tostring(uosc_available))
end)

mp.register_script_message("menu-ready", function(client_name)
    dyn_menu = client_name
    dyn_menu_update()
end)

function booky_close()
    menu_shown = false
    palette = false
    if uosc_available then
        mp.commandv("script-message-to", "uosc", "close-menu", "booky-bookmarks")
    else
        close_menu()
    end
end

function booky_clear()
    search_words = nil
    search_query = nil
    menu_shown = false
    palette = false
end

function booky_remove_selected()
    -- This would need integration with uosc to get the selected item
    -- For now, we'll provide a simple message
    mp.osd_message("[booky] Use script-message booky-remove <path> to remove specific bookmarks")
end

function booky_add()
    add_bookmark(true)
    if menu_shown then
        show_bookmarks()
    end
end

function booky_remove(path)
    if remove_bookmark(path) then
        mp.osd_message("[booky] bookmark removed")
        if menu_shown then
            show_bookmarks()
        end
    else
        mp.osd_message("[booky] bookmark not found")
    end
end

-- update menu in mpv-menu-plugin
function dyn_menu_update()
    event_loop_exhausted = false
    
    local menu = {
        type = "submenu",
        submenu = {
            {title = "📌 Bookmark current video", cmd = "script-binding booky-add"},
            {type = "separator"}
        }
    }

    if bookmarks then
        bookmarks:seek("set", 0)
        local line
        local bookmarks_list = {}
        
        while true do
            line = bookmarks:read("*l")
            if not line then break end
            
            local entry_length = line:match(",(%d+)$")
            if entry_length then
                entry_length = tonumber(entry_length)
                local entry = line:sub(1, entry_length)
                
                local timestamp_str, title_length_str, remaining = entry:match("([^,]*),(%d*),(.*)")
                if timestamp_str and remaining then
                    local title_length = tonumber(title_length_str) or 0
                    local title = ""
                    local path = remaining
                    
                    if title_length > 0 then
                        title = remaining:sub(1, title_length)
                        path = remaining:sub(title_length + 2)
                    else
                        -- No title, the remaining part is just the path
                        path = remaining
                    end
                    
                    local display_title = title
                    if display_title == "" then
                        display_title = path:match("([^/\\]+)$") or path
                    end
                    
                    table.insert(bookmarks_list, {
                        title = display_title,
                        path = path
                    })
                end
            end
        end
        
        if #bookmarks_list > 0 then
            for _, bookmark in ipairs(bookmarks_list) do
                local cmd = string.format("loadfile \"%s\" replace", bookmark.path:gsub("\\", "\\\\"):gsub("\"", "\\\""))
                menu.submenu[#menu.submenu + 1] = {
                    title = bookmark.title,
                    cmd = cmd
                }
            end
        else
            menu.submenu[#menu.submenu + 1] = {
                title = "No bookmarks yet",
                state = {"disabled"}
            }
        end
    end

    mp.commandv("script-message-to", dyn_menu, "update", "booky", mp.utils.format_json(menu))
end

function booky_clear_all()
    if bookmarks_path then
        local f = io.open(bookmarks_path, "w")
        if f then
            f:close()
            mp.osd_message("[booky] All bookmarks cleared")
            if menu_shown then
                show_bookmarks()
            end
        else
            mp.osd_message("[booky] Failed to clear bookmarks")
        end
    else
        mp.osd_message("[booky] No bookmarks file configured")
    end
end

mp.register_script_message("booky-clear", booky_clear)
mp.register_script_message("booky-add", booky_add)
mp.register_script_message("booky-remove", function(path)
    booky_remove(path)
end)
mp.register_script_message("booky-clear-all", booky_clear_all)

mp.add_key_binding("", "booky-add", booky_add)
mp.add_key_binding("", "booky-bookmarks", function()
    if event_loop_exhausted then return end
    show_bookmarks()
end)
mp.add_key_binding("ctrl+shift+b", "booky-clear-all", booky_clear_all)

mp.register_idle(idle)