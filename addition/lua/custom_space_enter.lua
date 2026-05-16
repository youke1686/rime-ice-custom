-- custom_space_enter.lua
-- 自定义空格与回车的行为切换
-- ␣ 模式：空格上屏候选词，回车原始输入
-- ⏎ 模式：回车键上屏候选词，空格原始输入+空格

-- 按键键码常量
local KEY_SPACE = 32
local KEY_RETURN = 65293

-- ⏎ 模式下需拦截的非字母字符：可打印 ASCII（排除字母和反引号）+ 小键盘按键
local function is_interrupt_key(keycode)
    -- 可打印 ASCII (32-126)，排除字母 A-Z/a-z 和反引号 `
    local is_ascii_non_letter = keycode >= 32 and keycode <= 126
        and not (keycode >= 65 and keycode <= 90)
        and not (keycode >= 97 and keycode <= 122)
        and keycode ~= 96
    -- 小键盘键 (KP_0~9, KP_Add, KP_Subtract, KP_Multiply, KP_Divide, KP_Decimal)
    local is_keypad = keycode >= 65450 and keycode <= 65465
    return is_ascii_non_letter or is_keypad
end

local function processor(key, env)
    local context = env.engine.context
    local is_enter_confirm = context:get_option("confirm_mode")

    -- 切换模式时联动切换标点符号模式（同时重新设置 confirm_mode 用于触发状态栏通知）
    if is_enter_confirm then
        if not context:get_option("ascii_punct") then
            context:set_option("ascii_punct", true)
            context:set_option("confirm_mode", true)
        end
    else
        if context:get_option("ascii_punct") then
            context:set_option("ascii_punct", false)
            context:set_option("confirm_mode", false)
        end
    end

    -- 未输入或按键释放时交给默认处理
    if not context:is_composing() or key:release() then
        return 2 -- kNoop
    end

    -- ⏎ 模式：非字母字符打断输入，先上屏原始输入
    if is_enter_confirm and is_interrupt_key(key.keycode) then
        local input = context.input
        if input and input ~= "" then
            env.engine:commit_text(input)
            context:clear()
        end
        return 2 -- kNoop，交由后续处理器处理该字符
    end

    -- 空格键处理
    if key.keycode == KEY_SPACE and key.modifier == 0 then
        if is_enter_confirm then
            -- ⏎ 模式：上屏原始输入 + 空格
            env.engine:commit_text(context.input .. " ")
        else
            -- ␣ 模式：上屏首选候选词
            local commit_text = context:get_commit_text()
            if commit_text and commit_text ~= "" then
                env.engine:commit_text(commit_text)
            end
        end
        context:clear()
        return 1 -- kAccepted
    end

    -- 回车键处理
    if key.keycode == KEY_RETURN and key.modifier == 0 then
        if is_enter_confirm then
            -- ⏎ 模式：只有当前选中的是原始输入时，才跳转到第二个候选词
            local selected = context:get_selected_candidate()
            if selected and selected.text == context.input then
                context:select(1)
            end
            local commit_text = context:get_commit_text()
            if commit_text and commit_text ~= "" then
                env.engine:commit_text(commit_text)
            end
        else
            -- ␣ 模式：上屏原始输入
            env.engine:commit_text(context.input)
        end
        context:clear()
        return 1 -- kAccepted
    end

    return 2 -- kNoop
end

return processor
