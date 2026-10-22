# dotfiles

Configuración de zsh (oh-my-zsh + powerlevel10k) y kitty para macOS y Linux.

## Instalación

Requisitos: `zsh`, `git`, `curl` y, en Linux, `xz`.

```sh
git clone https://github.com/kev95p/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Si tu shell no es zsh, el script te dirá cómo cambiarla (`chsh -s "$(command -v zsh)"`).
Abre una terminal nueva para ver los cambios.

## Qué hace `install.sh`

1. Instala oh-my-zsh, powerlevel10k y los plugins en los commits fijados en
   `omz/plugins.lock`, y aplica los parches de `omz/patches/`.
2. Descarga la fuente MesloLGS NF (la que necesita powerlevel10k).
3. Enlaza `~/.zshrc`, `~/.zshenv`, `~/.zprofile` y `~/.p10k.zsh` a los archivos de `zsh/`.
4. Instala kitty en una versión fija y enlaza `~/.config/kitty/kitty.conf`.
   En Linux además lo integra con el escritorio.

Si ya existe un archivo real en alguno de esos destinos, se respalda como `.bak`
antes de reemplazarlo por el enlace. El script se puede volver a correr sin problema:
solo descarga o cambia lo que no coincide.

## Estructura

```
install.sh                  instalador
omz/plugins.lock            oh-my-zsh y plugins con su commit fijo
omz/patches/                parches que se aplican sobre los plugins
zsh/zshrc                   configuración principal de zsh
zsh/zshenv, zsh/zprofile    entorno y PATH (cargo, Homebrew, ~/.local/bin, OrbStack)
zsh/p10k.zsh                configuración del prompt
zsh/zshrc.local.example     plantilla para la configuración propia de cada máquina
kitty/kitty.conf            configuración de kitty
```

## Configuración por máquina

Lo que solo existe en una máquina (nvm, pyenv, bun, pnpm, Flutter, PATH extra...)
va en `~/.zshrc.local`, que no está en el repo y se carga al final de `zshrc`.
Para empezar:

```sh
cp ~/dotfiles/zsh/zshrc.local.example ~/.zshrc.local
```

y deja solo lo que tengas instalado.

## Actualizar plugins

Las versiones están fijadas y la actualización automática de oh-my-zsh está desactivada.
Para actualizar un plugin, cambia su commit en `omz/plugins.lock` y vuelve a correr
`./install.sh`.

## Personalizar

- Prompt: `p10k configure` o edita `zsh/p10k.zsh`.
- Plugins de oh-my-zsh: lista `plugins=(...)` en `zsh/zshrc`.
- Como `~/.zshrc` y los demás son enlaces, cualquier cambio queda directamente en el repo.

## Parches

`omz/patches/zsh-autocomplete.patch` cambia cómo zsh-autocomplete cierra sus
descriptores de archivo asíncronos: comprueba que el descriptor siga abierto en vez
de usar `-t`. El parche solo se aplica si encaja limpio con el commit fijado.
