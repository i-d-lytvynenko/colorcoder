local M = {}

local function first_to_upper(str)
    return (str:gsub("^%l", string.upper))
end

local function clear_highlights(filetype)
    local opts = M.filetypes[filetype]
    if type(opts.groups) ~= "table" then
        return
    end
    for group, _ in ipairs(opts.groups) do
        local group_name = filetype .. first_to_upper(group)
        vim.cmd(string.format("syntax clear %s", group_name))
        vim.cmd(string.format("highlight %s NONE", group_name))
        vim.cmd(string.format("highlight default link %s NONE", group_name))
    end
end

local function apply_highlights(filetype)
    local opts = M.filetypes[filetype]
    for group, group_opts in pairs(opts.groups) do
        local group_name = filetype .. first_to_upper(group)

        local matches = group_opts.matches
        local regions = group_opts.regions
        local links = group_opts.links
        local styles = group_opts.styles

        if not (matches or regions) then
            error("No matching rules were provided", 2)
        end

        if not (links or styles) then
            -- If no links or styles provided, attempt to link new group with the group of same name
            if vim.fn.hlexists(group) == 1 then
                links = group
            elseif vim.fn.hlexists(first_to_upper(group)) == 1 then
                links = first_to_upper(group)
            else
                error("No styles were provided", 2)
            end
        end

        if regions then
            for _, region in ipairs(regions) do
                if not (region.from and region.to) then
                    error("Incorrect region provided: " .. vim.inspect(region), 2)
                end
            end
        end

        -- Clear previous file syntax
        if vim.fn.hlexists(group_name) == 1 then
            vim.cmd(string.format("syntax clear %s", group_name))
            vim.cmd(string.format("highlight %s NONE", group_name))
            vim.cmd(string.format("highlight default link %s NONE", group_name))
        end

        -- Add regex capturing rules
        if type(matches) == "table" then
            for _, regex in ipairs(matches) do
                vim.cmd(string.format("syntax match %s /%s/", group_name, regex))
            end
        elseif matches then
            vim.cmd(string.format("syntax match %s /%s/", group_name, matches))
        end

        -- Add regions capturing rules
        if type(regions) == "table" then
            for _, region_params in ipairs(regions) do
                local syntax_cmd = string.format("syntax region %s ", group_name)
                local keys_translator = {
                    from = "start",
                    to = "end",
                    skip = "skip",
                }
                for config_key, vim_keyword in pairs(keys_translator) do
                    if type(region_params[config_key]) == "table" then
                        for _, region_regex in ipairs(region_params[config_key]) do
                            syntax_cmd = string.format("%s%s=/%s/ ", syntax_cmd, vim_keyword, region_regex)
                        end
                    elseif region_params[config_key] then
                        syntax_cmd = string.format("%s%s=/%s/ ", syntax_cmd, vim_keyword, region_params[config_key])
                    end
                end
                vim.cmd(syntax_cmd)
            end
        end

        -- Link group default styles to predefined groups
        if type(links) == "table" then
            for _, predefined_group in ipairs(links) do
                vim.cmd(string.format("highlight link %s %s", group_name, predefined_group))
            end
        elseif links then
            vim.cmd(string.format("highlight link %s %s", group_name, links))
        end

        -- Apply additional provided styles
        if styles then
            local highlight_cmd = string.format("silent highlight %s ", group_name)
            for key, value in pairs(styles) do
                highlight_cmd = string.format("%s%s=%s ", highlight_cmd, key, value)
            end
            vim.cmd(highlight_cmd)
        end
    end

    -- Add remaps for the current buffer
    local remaps = opts.remaps
    if type(remaps) == "table" then
        for remap_i, remap in ipairs(remaps) do
            local modes = remap[1]
            local lhs = remap[2]
            local rhs = remap[3]
            if type(rhs) == "function" then
                rhs = string.format(
                    "<cmd>lua require('colorcoder').filetypes['%s'].remaps[%s][3]()<CR>",
                    filetype, remap_i
                )
            end
            local remap_opts = remap[4] or {}
            if type(modes) == "table" then
                for _, mode in ipairs(modes) do
                    vim.api.nvim_buf_set_keymap(0, mode, lhs, rhs, remap_opts)
                end
            else
                vim.api.nvim_buf_set_keymap(0, modes, lhs, rhs, remap_opts)
            end
        end
    end
end

local function setup(opts)
    if type(M.filetypes) == "table" then
        for filetype, _ in pairs(M.filetypes) do
            clear_highlights(filetype)
        end
    end
    M.filetypes = opts.filetypes
    for filetype, _ in pairs(M.filetypes) do
        vim.cmd(string.format(
            "autocmd BufEnter *.%s lua require('colorcoder').apply_highlights('%s')",
            filetype, filetype
        ))
    end
end

M.clear_highlights = clear_highlights
M.apply_highlights = apply_highlights
M.setup = setup

return M
