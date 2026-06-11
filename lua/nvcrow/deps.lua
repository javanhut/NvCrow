-- System dependency handling, cross-platform (macOS + Linux).
--
-- Strategy: binaries with prebuilt releases (tree-sitter CLI) are
-- downloaded straight into NvCrow's own bin dir — no package manager,
-- no sudo, works the same everywhere. Toolchain pieces that can't be
-- portably downloaded (compiler, make, ripgrep) get a one-keypress
-- install through whichever package manager the system has.

local M = {}

local bin_dir = vim.fn.stdpath("data") .. "/nvcrow/bin"

-- Make NvCrow-managed binaries visible to this session and to child
-- processes (mason builds, parser compiles).
function M.setup_path()
  if not (vim.env.PATH or ""):find(bin_dir, 1, true) then
    vim.env.PATH = bin_dir .. ":" .. (vim.env.PATH or "")
  end
end

local function platform()
  local uname = vim.uv.os_uname()
  local sys = uname.sysname:lower()
  local os_name = (sys:find("darwin") and "macos") or (sys:find("linux") and "linux") or nil
  local m = uname.machine
  local arch = ((m == "arm64" or m == "aarch64") and "arm64")
    or (m == "x86_64" and "x64")
    or nil
  return os_name, arch
end

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, { title = "NvCrow" })
  end)
end

local function fetch(url, dest, cb)
  vim.fn.mkdir(vim.fs.dirname(dest), "p")
  local cmd
  if vim.fn.executable("curl") == 1 then
    cmd = { "curl", "-fsSL", "-o", dest, url }
  elseif vim.fn.executable("wget") == 1 then
    cmd = { "wget", "-qO", dest, url }
  else
    return cb(false, "neither curl nor wget is available")
  end
  vim.system(cmd, {}, function(out)
    cb(out.code == 0, out.stderr)
  end)
end

-- Ensure the tree-sitter CLI is available, auto-downloading a prebuilt
-- release binary if needed. Calls on_ready() once it's usable.
function M.ensure_tree_sitter(on_ready)
  M.setup_path()
  if vim.fn.executable("tree-sitter") == 1 then
    on_ready()
    return
  end

  local os_name, arch = platform()
  if not os_name or not arch then
    notify("Can't auto-download the tree-sitter CLI on this platform — please install it manually.", vim.log.levels.WARN)
    return
  end

  local url = ("https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-%s-%s.gz")
    :format(os_name, arch)
  local gz = bin_dir .. "/tree-sitter.gz"

  notify("Downloading tree-sitter CLI (compiles syntax parsers)…")
  fetch(url, gz, function(ok, err)
    if not ok then
      notify("tree-sitter CLI download failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end
    vim.system(
      { "sh", "-c", ("gunzip -f %q && chmod +x %q"):format(gz, bin_dir .. "/tree-sitter") },
      {},
      function(out)
        vim.schedule(function()
          if out.code == 0 and vim.fn.executable("tree-sitter") == 1 then
            notify("tree-sitter CLI installed.")
            on_ready()
          else
            notify("tree-sitter CLI unpack failed: " .. (out.stderr or ""), vim.log.levels.ERROR)
          end
        end)
      end
    )
  end)
end

-- Package managers we know how to drive, in detection order.
local managers = {
  { bin = "apt-get", install = "apt-get install -y", update = "apt-get update && ",
    map = { rg = "ripgrep", cc = "build-essential", make = "build-essential" } },
  { bin = "dnf", install = "dnf install -y", map = { rg = "ripgrep", cc = "gcc" } },
  { bin = "pacman", install = "pacman -S --needed --noconfirm",
    map = { rg = "ripgrep", cc = "base-devel", make = "base-devel" } },
  { bin = "zypper", install = "zypper install -y", map = { rg = "ripgrep", cc = "gcc" } },
  { bin = "apk", install = "apk add", map = { rg = "ripgrep", cc = "build-base", make = "build-base" } },
}

local function missing_tools()
  local missing = {}
  local function need(tool, alternates)
    for _, bin in ipairs(alternates or { tool }) do
      if vim.fn.executable(bin) == 1 then return end
    end
    table.insert(missing, tool)
  end
  need("git")
  need("curl", { "curl", "wget" })
  need("unzip")
  need("rg")
  need("make")
  need("cc", { "cc", "gcc", "clang" })
  return missing
end

-- Build the exact install command for this system, or nil.
local function install_command(missing)
  local os_name = platform()
  local sudo = ""
  local uid = vim.uv.getuid and vim.uv.getuid() or 1
  if uid ~= 0 and vim.fn.executable("sudo") == 1 then
    sudo = "sudo "
  end

  if os_name == "macos" then
    local parts = {}
    local needs_clt = vim.tbl_contains(missing, "cc") or vim.tbl_contains(missing, "make")
    if needs_clt then
      table.insert(parts, "xcode-select --install")
    end
    local pkgs = {}
    for _, t in ipairs(missing) do
      if t ~= "cc" and t ~= "make" then
        table.insert(pkgs, t == "rg" and "ripgrep" or t)
      end
    end
    if #pkgs > 0 then
      if vim.fn.executable("brew") == 1 then
        table.insert(parts, "brew install " .. table.concat(pkgs, " "))
      else
        return nil
      end
    end
    return #parts > 0 and table.concat(parts, " ; ") or nil
  end

  for _, pm in ipairs(managers) do
    if vim.fn.executable(pm.bin) == 1 then
      local pkgs, seen = {}, {}
      for _, t in ipairs(missing) do
        local pkg = (pm.map or {})[t] or t
        if not seen[pkg] then
          seen[pkg] = true
          table.insert(pkgs, pkg)
        end
      end
      local update = pm.update and (sudo .. pm.update) or ""
      return update .. sudo .. pm.install .. " " .. table.concat(pkgs, " ")
    end
  end
  return nil
end

-- Check for missing system tools and offer to install them in a
-- terminal split (so sudo prompts work). Declining is remembered
-- until the set of missing tools changes.
function M.check_system()
  local missing = missing_tools()
  if #missing == 0 then return end

  local summary = "NvCrow needs these system tools: " .. table.concat(missing, ", ")
  local cmd = install_command(missing)
  if not cmd then
    notify(summary .. "\nInstall them with your system's package manager.", vim.log.levels.WARN)
    return
  end

  local state_file = vim.fn.stdpath("state") .. "/nvcrow_deps_declined"
  local sig = table.concat(missing, ",")
  local f = io.open(state_file, "r")
  if f then
    local declined = f:read("*a")
    f:close()
    if declined == sig then
      notify(summary .. "\nFix with: " .. cmd, vim.log.levels.WARN)
      return
    end
  end

  if vim.fn.confirm(summary .. "\n\nRun this now?\n  " .. cmd, "&Yes\n&No", 1) == 1 then
    vim.cmd("botright 12new")
    vim.fn.jobstart(cmd, { term = true })
    vim.cmd("startinsert")
  else
    local w = io.open(state_file, "w")
    if w then
      w:write(sig)
      w:close()
    end
    notify("Okay — I won't ask again unless something changes. Fix later with:\n  " .. cmd)
  end
end

return M
