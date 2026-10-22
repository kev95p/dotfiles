#!/usr/bin/env bash
# Instala oh-my-zsh, powerlevel10k y los plugins en los commits de omz/plugins.lock,
# la fuente MesloLGS NF y kitty, y enlaza las configuraciones en $HOME.
# Requiere zsh, git, curl y, en Linux, xz (para descomprimir kitty).
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
ZSH="$HOME/.oh-my-zsh"

# --- oh-my-zsh y plugins ---
while read -r rel url sha; do
  [[ -z "$rel" || "$rel" == \#* ]] && continue
  if [[ "$rel" == "." ]]; then dest="$ZSH"; else dest="$ZSH/$rel"; fi

  if [[ "$(git -C "$dest" rev-parse HEAD 2>/dev/null)" != "$sha" ]]; then
    echo "fetch   $(basename "$dest") @ ${sha:0:7}"
    mkdir -p "$dest"
    [[ -d "$dest/.git" ]] || git -C "$dest" init -q
    git -C "$dest" remote remove origin 2>/dev/null || true
    git -C "$dest" remote add origin "$url"
    git -C "$dest" fetch -q --depth 1 origin "$sha"
    git -C "$dest" checkout -q --force FETCH_HEAD
  fi

  patch="$DOTFILES/omz/patches/$(basename "$rel").patch"
  if [[ -f "$patch" ]] && git -C "$dest" apply --check "$patch" 2>/dev/null; then
    git -C "$dest" apply "$patch" && echo "patch   $(basename "$patch")"
  fi
done < "$DOTFILES/omz/plugins.lock"

# --- fuente MesloLGS NF para powerlevel10k (commit fijo de powerlevel10k-media) ---
FONTS_SHA=145eb9fbc2f42ee408dacd9b22d8e6e0e553f83d
if [[ "$OSTYPE" == darwin* ]]; then
  font_dir="$HOME/Library/Fonts"
else
  font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
fi
mkdir -p "$font_dir"
for style in Regular Bold Italic "Bold Italic"; do
  font="MesloLGS NF $style.ttf"
  [[ -f "$font_dir/$font" ]] && continue
  echo "font    $font"
  curl -fsSL -o "$font_dir/$font" \
    "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/$FONTS_SHA/${font// /%20}"
done
[[ "$OSTYPE" == darwin* ]] || ! command -v fc-cache >/dev/null || fc-cache -f "$font_dir"

# --- enlaces; si ya existe un archivo real se respalda como .bak ---
for name in zshrc zshenv zprofile p10k.zsh; do
  target="$HOME/.$name"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mv "$target" "$target.bak"
    echo "backup  ~/.$name -> ~/.$name.bak"
  fi
  ln -sfn "$DOTFILES/zsh/$name" "$target"
  echo "link    ~/.$name"
done

# --- kitty (instalador oficial, versión fija) ---
KITTY_VERSION=0.47.4
if [[ "$OSTYPE" == darwin* ]]; then
  kitty_app="/Applications/kitty.app"
else
  kitty_app="$HOME/.local/kitty.app"
fi
if [[ ! -d "$kitty_app" ]]; then
  echo "install kitty $KITTY_VERSION"
  curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin \
    installer=version-$KITTY_VERSION launch=n
fi
if [[ "$OSTYPE" != darwin* ]]; then
  # Integración con el escritorio, según https://sw.kovidgoyal.net/kitty/binary/
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config"
  ln -sf "$kitty_app/bin/kitty" "$kitty_app/bin/kitten" "$HOME/.local/bin/"
  cp "$kitty_app/share/applications/kitty.desktop" "$kitty_app/share/applications/kitty-open.desktop" \
    "$HOME/.local/share/applications/"
  sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
    "$HOME"/.local/share/applications/kitty*.desktop
  sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" \
    "$HOME"/.local/share/applications/kitty*.desktop
  echo 'kitty.desktop' > "$HOME/.config/xdg-terminals.list"
fi

mkdir -p "$HOME/.config/kitty"
target="$HOME/.config/kitty/kitty.conf"
if [[ -e "$target" && ! -L "$target" ]]; then
  mv "$target" "$target.bak"
  echo "backup  ~/.config/kitty/kitty.conf -> kitty.conf.bak"
fi
ln -sfn "$DOTFILES/kitty/kitty.conf" "$target"
echo "link    ~/.config/kitty/kitty.conf"

[[ "$SHELL" == *zsh ]] || echo "Cambia tu shell con: chsh -s \"$(command -v zsh)\""
