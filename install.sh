#!/usr/bin/env bash
# NvCrow installer for macOS and Linux.
#
# Installs missing system tools through your package manager
# (brew / apt / dnf / pacman / zypper / apk), ensures Neovim 0.11+
# (downloading an official build on Linux if needed), then links this
# repo as your Neovim config. Existing configs are backed up first.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
OS="$(uname -s)"
ARCH="$(uname -m)"

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

missing() { ! command -v "$1" >/dev/null 2>&1; }

# ---------- system tools ----------
TOOLS=()
missing git && TOOLS+=(git)
missing curl && missing wget && TOOLS+=(curl)
missing unzip && TOOLS+=(unzip)
missing rg && TOOLS+=(rg)
missing make && TOOLS+=(make)
if missing cc && missing gcc && missing clang; then TOOLS+=(cc); fi

if [ "${#TOOLS[@]}" -gt 0 ]; then
  echo "Missing system tools: ${TOOLS[*]} — installing..."

  if [ "$OS" = "Darwin" ]; then
    for t in "${TOOLS[@]}"; do
      case "$t" in
        cc | make)
          echo "Installing Xcode command line tools (a dialog may appear)..."
          xcode-select --install 2>/dev/null || true
          ;;
      esac
    done
    BREW_PKGS=()
    for t in "${TOOLS[@]}"; do
      case "$t" in
        rg) BREW_PKGS+=(ripgrep) ;;
        git | curl | unzip) BREW_PKGS+=("$t") ;;
      esac
    done
    if [ "${#BREW_PKGS[@]}" -gt 0 ]; then
      if command -v brew >/dev/null 2>&1; then
        brew install "${BREW_PKGS[@]}"
      else
        echo "warning: Homebrew not found — install manually: ${BREW_PKGS[*]}" >&2
      fi
    fi

  elif command -v apt-get >/dev/null 2>&1; then
    PKGS=()
    for t in "${TOOLS[@]}"; do
      case "$t" in
        rg) PKGS+=(ripgrep) ;;
        cc | make) PKGS+=(build-essential) ;;
        *) PKGS+=("$t") ;;
      esac
    done
    $SUDO apt-get update
    $SUDO apt-get install -y "${PKGS[@]}"

  elif command -v dnf >/dev/null 2>&1; then
    PKGS=()
    for t in "${TOOLS[@]}"; do
      case "$t" in
        rg) PKGS+=(ripgrep) ;;
        cc) PKGS+=(gcc) ;;
        *) PKGS+=("$t") ;;
      esac
    done
    $SUDO dnf install -y "${PKGS[@]}"

  elif command -v pacman >/dev/null 2>&1; then
    PKGS=()
    for t in "${TOOLS[@]}"; do
      case "$t" in
        rg) PKGS+=(ripgrep) ;;
        cc | make) PKGS+=(base-devel) ;;
        *) PKGS+=("$t") ;;
      esac
    done
    $SUDO pacman -S --needed --noconfirm "${PKGS[@]}"

  elif command -v zypper >/dev/null 2>&1; then
    PKGS=()
    for t in "${TOOLS[@]}"; do
      case "$t" in
        rg) PKGS+=(ripgrep) ;;
        cc) PKGS+=(gcc) ;;
        *) PKGS+=("$t") ;;
      esac
    done
    $SUDO zypper install -y "${PKGS[@]}"

  elif command -v apk >/dev/null 2>&1; then
    PKGS=()
    for t in "${TOOLS[@]}"; do
      case "$t" in
        rg) PKGS+=(ripgrep) ;;
        cc | make) PKGS+=(build-base) ;;
        *) PKGS+=("$t") ;;
      esac
    done
    $SUDO apk add "${PKGS[@]}"

  else
    echo "warning: no supported package manager found." >&2
    echo "         Install these yourself: ${TOOLS[*]}" >&2
  fi
fi

# ---------- neovim 0.11+ ----------
nvim_ok() {
  command -v nvim >/dev/null 2>&1 || return 1
  nvim --version | head -1 | awk '{
    split(substr($2, 2), v, ".")
    exit !(v[1] > 0 || v[2] >= 11)
  }'
}

if ! nvim_ok; then
  echo "Neovim 0.11+ not found — installing..."
  if [ "$OS" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
      brew install neovim
    else
      echo "error: install Homebrew (https://brew.sh) or Neovim 0.11+ manually." >&2
      exit 1
    fi
  else
    # Distro repos often lag; use the official release build.
    case "$ARCH" in
      x86_64) NV_ARCH="x86_64" ;;
      aarch64 | arm64) NV_ARCH="arm64" ;;
      *)
        echo "error: unsupported architecture $ARCH — install Neovim 0.11+ manually." >&2
        exit 1
        ;;
    esac
    DEST="$HOME/.local/share/nvcrow/nvim-runtime"
    mkdir -p "$DEST" "$HOME/.local/bin"
    URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NV_ARCH}.tar.gz"
    echo "Downloading $URL"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$URL" | tar -xz -C "$DEST" --strip-components=1
    else
      wget -qO- "$URL" | tar -xz -C "$DEST" --strip-components=1
    fi
    ln -sf "$DEST/bin/nvim" "$HOME/.local/bin/nvim"
    export PATH="$HOME/.local/bin:$PATH"
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) echo "note: add ~/.local/bin to your PATH to use nvim everywhere." ;;
    esac
  fi
fi

nvim_ok || {
  echo "error: still can't find Neovim 0.11+." >&2
  exit 1
}

# ---------- link config ----------
if [ -e "$NVIM_CONFIG" ] && [ ! -L "$NVIM_CONFIG" ]; then
  BACKUP="$NVIM_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing config to $BACKUP"
  mv "$NVIM_CONFIG" "$BACKUP"
elif [ -L "$NVIM_CONFIG" ]; then
  echo "Removing existing symlink $NVIM_CONFIG"
  rm "$NVIM_CONFIG"
fi

mkdir -p "$(dirname "$NVIM_CONFIG")"
echo "Linking $SRC_DIR -> $NVIM_CONFIG"
ln -s "$SRC_DIR" "$NVIM_CONFIG"

echo
echo "Done. Start nvim — plugins, LSP servers, formatters, and the"
echo "tree-sitter CLI all install themselves automatically."
echo "Then try:  :Crow add rust    :Crow list"
