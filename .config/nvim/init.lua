-- Minimal Neovim configuration.
--
-- Mirrors the important defaults from ~/.vimrc (leader ",", ";" -> ":",
-- 2-space indent, persistent undo, cursor restore) and adds the pieces vim
-- can't do: native LSP, treesitter, git plumbing. No plugin manager and no
-- distro — Neovim 0.12's built-in `vim.pack` clones six plugins on first
-- launch and that's the whole dependency tree.
--
-- Tuned for git and for agents editing files underneath the editor:
-- swapfiles off (agents write files directly, no swap conflicts), persistent
-- undo, autoread/checktime, format-on-save off by default (agents format;
-- use ,f when you want it by hand).

-- Leader first, so plugin default mappings (if any) pick it up.
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Faster startup: byte-compile/reload lua modules from the cache.
vim.loader.enable()

-------------------------------------------------------------------------------
-- Options (mirroring .vimrc where it matters)
-------------------------------------------------------------------------------
local opt = vim.opt

opt.number = true
opt.termguicolors = true
opt.mouse = "a"

-- Searching
opt.hlsearch = true
opt.showmatch = true
opt.ignorecase = true
opt.smartcase = true

-- Indentation: 2 spaces everywhere, 4 for the languages that want it
opt.expandtab = true
opt.shiftwidth = 2
opt.softtabstop = 2
opt.smartindent = true
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "java", "c", "cpp" },
  callback = function(args)
    vim.bo[args.buf].shiftwidth = 4
    vim.bo[args.buf].softtabstop = 4
  end,
})
-- gofmt wants tabs
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gosum" },
  callback = function(args)
    vim.bo[args.buf].expandtab = false
    vim.bo[args.buf].shiftwidth = 8
    vim.bo[args.buf].tabstop = 8
  end,
})

-- Splits
opt.splitbelow = true
opt.splitright = true
opt.diffopt:append("vertical,algorithm:histogram,linematch:60")
for _, key in ipairs({ "h", "j", "k", "l" }) do
  vim.keymap.set("n", "<C-" .. key .. ">", "<C-w><C-" .. key .. ">")
end

-- Persistent undo, no swapfiles: agents and `git checkout` rewrite files on
-- disk all the time; a swapfile turns every concurrent write into a prompt.
opt.undofile = true
opt.swapfile = false
opt.history = 10000
opt.autoread = true
opt.autowrite = true
opt.updatetime = 250
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  callback = function()
    vim.cmd("checktime")
  end,
})

-- System clipboard. With no clipboard tool installed Neovim falls back to
-- OSC52, which works through Ghostty/tmux/SSH passthrough.
opt.clipboard = "unnamedplus"

-- ; = : (vimrc muscle memory); ,<space> clears search highlights
vim.keymap.set("n", ";", ":")
vim.keymap.set("n", "<leader><space>", ":nohlsearch<CR>")

-- ]q / [q walk the quickfix list (LSP references, :Git, greps)
vim.keymap.set("n", "]q", ":cnext<CR>")
vim.keymap.set("n", "[q", ":cprev<CR>")

-- Cursor restore
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) and args.filetype ~= "gitcommit" then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-------------------------------------------------------------------------------
-- Plugins (vim.pack — built into Neovim 0.12+, nothing to install)
-------------------------------------------------------------------------------
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/stevearc/conform.nvim" },
})

-- Update with :PackUpdate (vim.pack). Kept manual so agents/CI never hit the
-- network on launch after the initial clone.

-------------------------------------------------------------------------------
-- Treesitter: highlight + indent for the languages actually used here
-- (Ruby/Rails, Python, Go, JS/TS, Rust, Elixir) plus git/editing basics.
-- Parsers compile once on first launch; missing toolchain just skips quietly.
-------------------------------------------------------------------------------
local parsers = {
  "bash", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
  "json", "yaml", "toml", "diff", "gitcommit", "gitignore",
  "ruby", "heex", "html", "python", "go", "gomod",
  "javascript", "typescript", "tsx", "rust", "elixir",
}
pcall(function()
  require("nvim-treesitter").install(parsers)
end)
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    -- Start treesitter highlighting only where a parser is available.
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-------------------------------------------------------------------------------
-- Diagnostics: visible but quiet — no noise while an agent streams edits.
-------------------------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = { current_line = true },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist)

-------------------------------------------------------------------------------
-- LSP: enable a server only when its binary is on PATH — no Mason, machines
-- install what they need (gopls, ruby-lsp, pyright, typescript-language-server,
-- lua-language-server, bash-language-server, elixir-ls, rust-analyzer) and the
-- config picks them up. Completion is Neovim's built-in auto-trigger.
-------------------------------------------------------------------------------
local servers = {
  gopls = "gopls",
  rust_analyzer = "rust-analyzer",
  ruby_lsp = "ruby-lsp",
  pyright = "pyright-langserver",
  ts_ls = "typescript-language-server",
  lua_ls = "lua-language-server",
  bashls = "bash-language-server",
  elixirls = "elixir-ls",
}

vim.lsp.config("lua_ls", {
  settings = { Lua = { diagnostics = { globals = { "vim" } } } },
})

for server, binary in pairs(servers) do
  if vim.fn.executable(binary) == 1 then
    vim.lsp.enable(server)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end
    if client:supports_method("textDocument/completion", args.buf) then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "go to definition")
    map("gD", vim.lsp.buf.declaration, "go to declaration")
    map("grr", vim.lsp.buf.references, "references")
    map("grn", vim.lsp.buf.rename, "rename")
    map("gra", vim.lsp.buf.code_action, "code action")
    map("K", vim.lsp.buf.hover, "hover")
  end,
})

-------------------------------------------------------------------------------
-- Git
-------------------------------------------------------------------------------
require("gitsigns").setup({
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end
    map("n", "]h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gs.nav_hunk("next")
      end
    end, "next hunk")
    map("n", "[h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gs.nav_hunk("prev")
      end
    end, "previous hunk")
    map("n", "<leader>hs", gs.stage_hunk, "stage hunk")
    map("n", "<leader>hr", gs.reset_hunk, "reset hunk")
    map("n", "<leader>hp", gs.preview_hunk, "preview hunk")
    map("n", "<leader>hb", function()
      gs.blame_line({ full = true })
    end, "blame line")
    map("n", "<leader>tb", gs.toggle_current_line_blame, "toggle line blame")
    map("n", "<leader>hd", gs.diffthis, "diff this")
  end,
})

-- ,gs = :Git status (fugitive), ,gd = vertical diff of the file, plus the
-- full :Git porcelain when needed.
vim.keymap.set("n", "<leader>gs", ":Git<CR>")
vim.keymap.set("n", "<leader>gd", ":Gvdiffsplit<CR>")

-------------------------------------------------------------------------------
-- fzf-lua (fzf is already a system dependency): files, grep, buffers, git
-------------------------------------------------------------------------------
local fzf = require("fzf-lua")
fzf.setup({})
local fzf_map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end
fzf_map("<leader>ff", fzf.files, "find files")
fzf_map("<leader>fg", fzf.live_grep, "live grep")
fzf_map("<leader>fb", fzf.buffers, "buffers")
fzf_map("<leader>fh", fzf.helptags, "help tags")
fzf_map("<leader>gf", fzf.git_files, "git files")
fzf_map("<leader>gt", fzf.git_status, "git status")
fzf_map("<leader>gc", fzf.git_commits, "git commits")
fzf_map("<leader>gb", fzf.git_bcommits, "buffer commits")

-------------------------------------------------------------------------------
-- Formatting: conform, by hand (,f) — format-on-save stays off so agents'
-- file writes never get reformatted underneath them.
-------------------------------------------------------------------------------
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "black" },
    go = { "gofmt", "goimports" },
    rust = { "rustfmt" },
    ruby = { "rubocop" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    yaml = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    sh = { "shfmt" },
  },
})
vim.keymap.set({ "n", "v" }, "<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "format buffer/selection" })

-------------------------------------------------------------------------------
-- Terminal: <C-/> toggles a bottom split; <Esc> leaves terminal mode.
-------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.signcolumn = "no"
  end,
})
local term_buf = nil
local function toggle_term()
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    local win = vim.fn.bufwinid(term_buf)
    if win ~= -1 then
      vim.api.nvim_win_hide(win)
      return
    end
    vim.cmd("botright 15split")
    vim.api.nvim_win_set_buf(0, term_buf)
  else
    vim.cmd("botright 15split")
    term_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, term_buf)
    vim.cmd("terminal")
  end
  vim.cmd("startinsert")
end
vim.keymap.set({ "n", "t" }, "<C-/>", toggle_term, { desc = "toggle terminal" })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
