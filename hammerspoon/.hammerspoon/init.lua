-- ==============================================================================
-- Hammerspoon Configuration (macOS Keyboard Shortcuts)
-- ==============================================================================
-- 配合 macOS 系统修饰键重映射：
-- 请在「系统设置 -> 键盘 -> 键盘快捷键 -> 修饰键」中，将 Caps Lock 键改为 Option ⌥
-- ==============================================================================

-- 方案 A：Vim 风格的 HJKL 方向键映射 (推荐，与你的 Vim/Tmux 配置一致)
-- Option (Caps Lock) + H -> 左
-- Option (Caps Lock) + J -> 下
-- Option (Caps Lock) + K -> 上
-- Option (Caps Lock) + L -> 右
local keys = {
    h = "left",
    j = "down",
    k = "up",
    l = "right"
}

-- 方案 B：如果你更喜欢 HIJK 方向键映射，请取消注释下方代码并注释掉上方 keys 定义
-- local keys = {
--     h = "left",
--     i = "up",
--     j = "down",
--     k = "right"
-- }

-- 绑定按键映射到方向键
for key, direction in pairs(keys) do
    hs.hotkey.bind({"option"}, key, 
        function() hs.eventtap.keyStroke({}, direction, 0) end, -- 单次点击
        nil, 
        function() hs.eventtap.keyStroke({}, direction, 0) end  -- 按住不放持续移动
    )
end

-- ==============================================================================
-- 配置自动重载 (当修改 init.lua 时，Hammerspoon 会自动重载生效)
-- ==============================================================================
function reloadConfig(files)
    local configFileSeen = false
    for _,file in ipairs(files) do
        if file:sub(-4) == ".lua" then
            configFileSeen = true
        end
    end
    if configFileSeen then
        hs.reload()
    end
end
local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Hammerspoon Config Loaded")
