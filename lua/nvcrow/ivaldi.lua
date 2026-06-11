-- Ivaldi VCS integration (https://github.com/javanhut/Ivaldi).
-- NvCrow-native — no external plugin needed.
-- Activates only when the `ivaldi` binary exists; statusline and
-- repo-aware bits light up inside Ivaldi repositories (.ivaldi dir).

local M = { _timeline = nil }

local function in_repo()
  return vim.fn.finddir(".ivaldi", vim.fn.getcwd() .. ";") ~= ""
end

-- Lualine component: current timeline, e.g. "󰜘 main".
function M.statusline()
  return M._timeline and ("󰜘 " .. M._timeline) or ""
end

function M.refresh()
  if vim.fn.executable("ivaldi") == 0 or not in_repo() then
    M._timeline = nil
    return
  end
  vim.system({ "ivaldi", "whereami" }, { text = true }, function(out)
    M._timeline = out.code == 0 and (out.stdout or ""):match("Timeline:%s*(%S+)") or nil
  end)
end

-- Run an ivaldi command in a bottom terminal split (output stays
-- readable and scrollable; press i to interact, q closes via terminal).
local function term_split(args)
  vim.cmd("botright 15new")
  vim.bo.bufhidden = "wipe"
  vim.fn.jobstart("ivaldi " .. args, { term = true })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, nowait = true })
end

-- Full-screen floating terminal for interactive commands (tui, travel).
local function term_float(args)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2) - 1,
    style = "minimal",
    border = "rounded",
    title = " ivaldi " .. args .. " ",
    title_pos = "center",
  })
  vim.fn.jobstart("ivaldi " .. args, {
    term = true,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        M.refresh()
      end)
    end,
  })
  vim.cmd.startinsert()
end

local function notify_result(out, success_msg)
  vim.schedule(function()
    if out.code == 0 then
      vim.notify(success_msg or vim.trim(out.stdout or ""), vim.log.levels.INFO, { title = "Ivaldi" })
    else
      vim.notify(vim.trim((out.stderr or "") .. (out.stdout or "")), vim.log.levels.ERROR, { title = "Ivaldi" })
    end
    M.refresh()
  end)
end

-- Stage the current file.
function M.gather_current()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then return end
  vim.system({ "ivaldi", "gather", file }, { text = true }, function(out)
    notify_result(out, "Gathered " .. vim.fn.fnamemodify(file, ":."))
  end)
end

-- Prompt for a message, then seal staged files.
function M.seal()
  vim.ui.input({ prompt = "Seal message: " }, function(msg)
    if not msg or msg == "" then return end
    vim.system({ "ivaldi", "seal", msg }, { text = true }, function(out)
      notify_result(out)
    end)
  end)
end

function M.sync()
  vim.notify("Syncing timeline…", vim.log.levels.INFO, { title = "Ivaldi" })
  vim.system({ "ivaldi", "sync" }, { text = true }, function(out)
    notify_result(out)
  end)
end

local subcommands = {
  "forge", "gather", "seal", "reseal", "status", "whereami", "log", "whodidit",
  "diff", "reset", "rewind", "undo", "pluck", "timeline", "fuse", "travel",
  "weld", "config", "exclude", "portal", "auth", "download", "upload",
  "scout", "harvest", "sync", "review", "tui", "serve", "peer",
}

function M.setup()
  if vim.fn.executable("ivaldi") == 0 then return end

  vim.api.nvim_create_user_command("Ivaldi", function(opts)
    local args = table.concat(opts.fargs, " ")
    if args == "" or args == "tui" or args:match("^travel") then
      term_float(args == "" and "tui" or args)
    else
      term_split(args)
    end
  end, {
    nargs = "*",
    complete = function(arglead, cmdline)
      local n = #vim.split(cmdline, "%s+", { trimempty = true })
      if n > 2 or (n == 2 and cmdline:sub(-1) == " ") then return {} end
      return vim.tbl_filter(function(c)
        return vim.startswith(c, arglead)
      end, subcommands)
    end,
    desc = "Ivaldi VCS (no args: TUI dashboard)",
  })

  local map = vim.keymap.set
  map("n", "<leader>vv", "<cmd>Ivaldi tui<cr>", { desc = "Ivaldi dashboard" })
  map("n", "<leader>vs", "<cmd>Ivaldi status<cr>", { desc = "Status" })
  map("n", "<leader>vl", "<cmd>Ivaldi log<cr>", { desc = "Log" })
  map("n", "<leader>vd", "<cmd>Ivaldi diff<cr>", { desc = "Diff" })
  map("n", "<leader>vt", "<cmd>Ivaldi travel<cr>", { desc = "Time travel" })
  map("n", "<leader>vg", M.gather_current, { desc = "Gather current file" })
  map("n", "<leader>vc", M.seal, { desc = "Seal (commit)" })
  map("n", "<leader>vy", M.sync, { desc = "Sync with remote" })

  vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "FocusGained" }, {
    group = vim.api.nvim_create_augroup("nvcrow_ivaldi", { clear = true }),
    callback = M.refresh,
  })
  M.refresh()
end

return M
