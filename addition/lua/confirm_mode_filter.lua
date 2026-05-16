-- confirm_mode_filter.lua
-- ⏎ 模式下，在候选列表首位插入原始输入，便于指示当前模式

local M = {}

function M.func(input, env)
    local context = env.engine.context
    local is_enter_confirm = context:get_option("confirm_mode")

    -- ␣ 模式：不干预，直接透传
    if not is_enter_confirm then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    -- ⏎ 模式：首位插入原始输入候选
    local raw_input = context.input
    if raw_input and raw_input ~= "" then
        -- 插入原始输入作为第一个候选词
        local raw_cand = Candidate("raw_input", 0, #raw_input, raw_input, "")
        yield(raw_cand)
    end

    -- 产出原始候选列表
    for cand in input:iter() do
        yield(cand)
    end
end

return M
