# Colorcoder

Colorcoder is a Neovim plugin that allows users to quickly add custom highlights to specific file formats. With colorcoder, users can define custom groups and their corresponding matches and styles for highlighting in their preferred file types.

## Features

- Define custom groups with matches and styles for highlighting
- Remap keys to specific functions within the defined file formats

## Installation

```lua
require("lazy").setup({
    -- ...
    {
        "i-d-lytvynenko/colorcoder",
        opts = {
            -- Paste your config here. Without a config this plugin does nothing.
            -- Providing config here is the same as running
            -- require("colorcoder").setup(<your config table>)

            -- filetypes = {
            --     ...
            -- }
        },
    },
    -- ...
})
```

## Usage

Once installed, you can set up colorcoder in your Neovim configuration file using the ``require("colorcoder").setup({})`` function. Inside the setup function, you can define the filetypes for which you want to define custom highlights. Each filetype can have its own set of groups with regions/matches and links/styles.

Here are examples of how the setup looks like:

### Basic feature overview

```lua
require("colorcoder").setup({
    filetypes = {
        xyz = {
            groups = {
                link = {
                    matches = "\\[\\[\\(.\\{-}\\)\\]\\]",  -- a vim regex which will be used to locate the group
                    links = "Constant",  -- a link to already existing highlighting group
                                         -- (for more group examples run ":highlight" or ":help highlight")
                },
                code = {
                    regions = {  -- basically a multiline match
                        {
                            from = [[```]],
                            to = [[```]],
                            skip = [[\\.]],
                        },
                        {
                            from = [[''']],
                            to = [[''']],
                            skip = [[\\.]],
                        },
                    },
                    links = "Comment",
                },
                todo = {
                    matches = { [[TODO]], [[???]] , [[fix this someday]] },
                    styles = {
                        -- You can provide your own styles if already existing groups aren't good enough.
                        -- Keep in mind that if you provide your own styles,
                        -- Vim will ignore the "links" section of your group
                        guifg = "#f6f6f6",
                        guibg = "#c75ae8",
                        gui = "bold",
                    }
                },
            },
            remaps = {  -- a section for maps, which will only work in this file format
                {
                    "n",
                    "gx",
                    function ()
                        local url = string.match(vim.fn.expand("<cWORD>"), "(https?://[a-zA-Z0-9_/%-%.~@\\+#=?&:]+)")
                        if url then
                            vim.cmd(("silent !start %s"):format(url))
                        else
                            print("No https or http URI found on line")
                        end
                    end,
                    { desc = "Open url in browser" }
                },
                {
                    {"n", "v"},
                    "<A-d>",
                    function ()
                        local filetype = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":e")
                        local filetype_opts = require("colorcoder").filetypes[filetype]
                        -- Notice how you can directly access your config
                        local todo_regex_list = filetype_opts.groups.todo.matches
                        -- Editing it is permissible, unless you want to add a new file format.
                        -- In this case run require("colorcoder").setup(...) with your new config.
                        local mode = vim.fn.mode()
                        local cmd_template
                        if mode == "n" then
                            cmd_template = ":silent! .s/%s//g\n"
                        else
                            vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n")
                            cmd_template = ":silent! '<,'>s/%s//g\n"
                        end
                        local result_regex = ""
                        for i, todo_regex in ipairs(todo_regex_list) do
                            result_regex = result_regex .. todo_regex
                            if i < #todo_regex_list then
                                result_regex = result_regex .. "\\|"
                            end
                        end
                        vim.fn.feedkeys(string.format(cmd_template, result_regex), "n")
                    end,
                    { noremap = true, silent = true, desc = "Remove TODO" }
                },
            },
        },
    },
})
```

Preview:

![preview1.gif](https://raw.githubusercontent.com/i-d-lytvynenko/colorcoder/master/examples/preview1.gif)

### Orgmode-ish file format
```lua
require("colorcoder").setup({
    filetypes = {
        org = {
            groups = {
                page = {
                    matches = [[^\_s*---\s.*]],
                    links = "Type",
                },
                headline = {
                    matches = [[^\_s*\*\+\s.*]],
                    styles = {
                        guifg = "#c75ae8",
                        gui = "bold",
                    }
                },
                tack = {
                    matches = [[^\_s*\zs-\ze ]],
                    links = "Type",
                },
                checkbox = {
                    matches = [[^\_s*\zs\[[X -]\]\ze ]],
                    links = "Type",
                },
                checkboxSummary = {
                    matches = {
                        [[^\_s*\zs\[\d*[/]\d*\]\ze ]],
                        [[\zs\[\d*[/]\d*\]\ze\s*$]],
                    },
                    links = "Type",
                },
                link = {
                    matches = "\\[\\[\\(.\\{-}\\)\\]\\]",
                    links = "Constant",
                },
                linkHeadline = {
                    matches = "{{\\(.\\{-}\\)}}",
                    links = "Statement",
                },
                bold = {
                    matches = [[\(^\|\_s\|(\|\[\|{\|"\|'\)\zs\*.\(.\{-}\)\*\ze\([.,!?'":;}\])]\|\_s\|$\)]],
                    styles = {
                        guifg = "#f6f6f6",
                        gui = "bold",
                    },
                },
                underline = {
                    matches = [[\(^\|\_s\|(\|\[\|{\|"\|'\)\zs_\(.\{-}\)_\ze\([.,!?'":;}\])]\|\_s\|$\)]],
                    styles = {
                        guisp = "#f6f6f6",
                        guifg = "#f6f6f6",
                        gui = "underline",
                    },
                },
                italic = {
                    matches = [[\(^\|\_s\|(\|\[\|{\|"\|'\)\zs\/\(.\{-}\)\/\ze\([.,!?'":;}\])]\|\_s\|$\)]],
                    styles = {
                        guifg = "#e2e2e2",
                        gui = "italic",
                    },
                },
                green = {
                    matches = {
                        [[^\_s*\zs\: \(.*\)\ze$]],
                        [[\(^\|\_s\|(\|\[\|{\|"\|'\)\zs\:\(.\{-}\)\:\ze\([.,!?'":;}\])]\|\_s\|$\)]],
                    },
                    styles = {
                        guifg = "#77ff9b",
                        gui = "bold",
                    },
                },
                yellow = {
                    matches = {
                        [[\(^\|\_s\|(\|\[\|{\|"\|'\)\zs\;\(.\{-}\)\;\ze\([.,!?'":;}\])]\|\_s\|$\)]],
                        [[^\_s*\zs\; \(.*\)\ze$]],
                    },
                    links = "WarningMsg",
                },
                red = {
                    matches = {
                        [[\(^\|\_s\|(\|\[\|{\|"\|'\)\zs\!\(.\{-}\)\!\ze\([.,!?'":;}\])]\|\_s\|$\)]],
                        [[^\_s*\zs\! \(.*\)\ze$]],
                    },
                    links = "ErrorMsg",
                },
                blue = {
                    matches = {
                        [[\(^\|\_s\|(\|\[\|{\|"\|'\)\zs\^\(.\{-}\)\^\ze\([.,!?'":;}\])]\|\_s\|$\)]],
                        [[^\_s*\zs\^ \(.*\)\ze$]],
                    },
                    links = "MoreMsg",
                },
            },
            remaps = {
                {
                    {"n", "v"},
                    "<A-b>",
                    function ()
                        local filetype = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":e")
                        local filetype_opts = require("colorcoder").filetypes[filetype]
                        local checkbox_regex = filetype_opts.groups.checkbox.matches
                        local checkbox_states = {
                            ["[-]"] = "[X]",
                            ["[ ]"] = "[X]",
                            ["[X]"] = "[ ]",
                        }

                        local mode = vim.fn.mode()
                        local line_start, line_end
                        if mode ~= "n" then
                            line_start = vim.fn.line("v")
                            line_end = vim.fn.line(".")
                            if line_start > line_end then
                                line_end, line_start = line_start, line_end
                            end
                        else
                            line_start = vim.fn.line(".")
                            line_end = line_start
                        end

                        local lines = vim.fn.getline(line_start, line_end)
                        for i, line_content in ipairs(lines) do
                            local line_number = i + line_start - 1
                            local match, start_index, end_index = unpack(vim.fn.matchstrpos(line_content, checkbox_regex))
                            local new_state = checkbox_states[match]
                            if new_state then
                                local edited_line = line_content:sub(1, start_index) .. new_state .. line_content:sub(end_index + 1)
                                vim.api.nvim_buf_set_lines(0, line_number - 1, line_number, false, {edited_line})
                            end
                        end
                        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n")
                    end,
                    { noremap = true, silent = true, desc = "Toggle checkboxes" }
                },
                {
                    "n",
                    "gf",
                    function ()
                        local filename = vim.fn.expand("<cWORD>")
                        local start_index, end_index = string.find(filename, "%[%[(.-)%]%]")
                        if start_index and end_index then
                            filename = filename:sub(start_index + 2, end_index - 2)
                        end
                        if filename == "" then
                            print("File not found.")
                            return
                        end
                        local current_file_path = vim.fn.expand("%:p")
                        local dirname = vim.fn.fnamemodify(current_file_path, ":h")
                        local is_abs = filename:sub(1, 1) ~= "/"
                        is_abs = is_abs or filename:sub(1, 2) ~= "./"
                        is_abs = is_abs or filename:sub(1, 3) ~= "../"
                        is_abs = is_abs or (vim.fn.has("win32") == 1 and filename:match("^%a:"))
                        if not is_abs then
                            filename = dirname .. "/" ..filename
                        end
                        vim.cmd(("edit %s"):format(filename))
                    end,
                    { noremap = true, silent = true, desc = "Open file link" }
                },
                {
                    "n",
                    "gx",
                    function ()
                        local url = string.match(vim.fn.expand("<cWORD>"), "(https?://[a-zA-Z0-9_/%-%.~@\\+#=?&:]+)")
                        if url then
                            vim.cmd(("silent !start %s"):format(url))
                        else
                            print("No https or http URI found on line")
                        end
                    end,
                    { desc = "Open url in browser" }
                },
                {
                    "n",
                    "gl",
                    function ()
                        local filetype = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":e")
                        local filetype_opts = require("colorcoder").filetypes[filetype]
                        local headline_regex = filetype_opts.groups.headline.matches
                        local headline_link_regex = filetype_opts.groups.linkHeadline.matches

                        local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
                        local current_line = vim.fn.getline(".")
                        local start_i = 0
                        local headline_name
                        while true do
                            local match, link_start, link_end = unpack(vim.fn.matchstrpos(current_line, headline_link_regex, start_i))
                            if not link_start or match == "" then
                                print("No headline link found")
                                return
                            end
                            if type(link_start) == "string" then
                                link_start = -1
                            end
                            if type(link_end) == "string" then
                                link_end = -1
                            end
                            if cursor_col >= link_start and cursor_col <= link_end then
                                headline_name = match:sub(3, -3)
                                break
                            end
                            if link_end ~= -1 then
                                start_i = link_end
                            else
                                start_i = start_i + 1
                            end
                            if start_i > cursor_col then
                                print("No headline link found")
                                return
                            end
                        end

                        for line_i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
                            local match = vim.fn.matchstrpos(line, headline_regex)[1]
                            if match ~= "" then
                                local headline = vim.fn.matchstrpos(match, ([[^\_s*\*\+\s\(%s\)]]):format(headline_name))[1]
                                if headline ~= "" then
                                    vim.api.nvim_command("normal! m'")
                                    vim.api.nvim_win_set_cursor(0, {line_i, 0})
                                    return
                                end
                            end
                        end
                        print("No headline found")
                    end,
                    { desc = "Go to headline" }
                },
            },
        },
    }
})
```

(Yes, this config is larger then the plugin itself).

Preview:

![preview2.gif](https://raw.githubusercontent.com/i-d-lytvynenko/colorcoder/master/examples/preview2.gif)

## License

This plugin is licensed under the MIT License. See the LICENSE file for more details.
