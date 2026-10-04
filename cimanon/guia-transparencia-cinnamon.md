# Guía: transparencia en Linux Mint (Cinnamon 6.4.14)

Probado en: Linux Mint con Cinnamon 6.4.14, X11, tema Mint-Y-Dark.
No usa extensiones para la transparencia:

- **Panel (barra de tareas):** se edita el tema (un archivo de texto).
- **Ventanas:** un script que usa `xprop` para ponerles opacidad.

---

## 1. Panel transparente

Copiar el tema a la carpeta del usuario, para no tocar el del sistema:

```bash
mkdir -p ~/.themes
cp -r /usr/share/themes/Mint-Y-Dark ~/.themes/
```

Ver en qué línea está la regla del panel (en esta versión es la 420):

```bash
grep -n -A6 "^\.panel-top" ~/.themes/Mint-Y-Dark/cinnamon/cinnamon.css
```

Cambiar la opacidad (último número de `rgba`) y reiniciar Cinnamon:

```bash
sed -i '420s/rgba(29, 29, 33, [0-9.]*)/rgba(29, 29, 33, 0.85)/' ~/.themes/Mint-Y-Dark/cinnamon/cinnamon.css && cinnamon --replace >/dev/null 2>&1 &
```

- `1` es sólido y `0` es invisible. Rango recomendado: `0.6` a `0.9`.
- Si el panel no cambia, forzar la recarga del tema:

```bash
gsettings set org.cinnamon.theme name 'Mint-Y'; sleep 1; gsettings set org.cinnamon.theme name 'Mint-Y-Dark'
```

- Si en otra versión el número de línea no es 420, usar el `grep` de arriba para encontrarlo.
- Este cambio queda guardado en el archivo: sigue igual al apagar y prender la PC.

---

## 2. Ventanas transparentes (script `auto-opacity`)

### ¿Para qué sirve?

Ponerle transparencia a una ventana con `xprop` funciona **una sola vez y solo en esa ventana**. Sin un script:

- Las ventanas nuevas salen **opacas**.
- Al apagar o reiniciar la PC **se pierde todo**.

El script `auto-opacity` queda corriendo de fondo y **le pone la transparencia solo a cada ventana nueva**. Se inicia solo al entrar a tu sesión.

### ¿Gasta recursos?

No se nota. No revisa cada segundo: se queda dormido y solo despierta cuando se abre o se cierra una ventana, o cuando cambia el foco. Además corre con prioridad baja (`nice -n 19`).

### ¿Qué hace para no dar problemas?

- **Una sola copia:** si se lanza dos veces, la segunda se cierra sola.
- **No toca** menús, tooltips ni notificaciones.
- **Ventanas en pantalla completa** (videos, juegos): las deja opacas y vuelven a ser transparentes al salir.
- **Mínimo 20% de opacidad:** así no puedes dejar una ventana invisible por error.
- **Se puede excluir** cualquier app desde el archivo de configuración.
- No necesita `wmctrl`; solo usa `xprop` y `flock`, que ya vienen en Mint.

### Instalación

Pegar este bloque completo en la terminal:

```bash
# 1. quitar versiones anteriores
~/.local/bin/auto-opacity stop 2>/dev/null
pkill -f auto-opacity.sh 2>/dev/null; pkill -f "xprop -root -spy" 2>/dev/null
rm -f ~/.local/bin/auto-opacity.sh ~/.local/bin/transparente ~/.config/autostart/auto-opacity.desktop

# 2. script
mkdir -p ~/.local/bin ~/.config/autostart
cat > ~/.local/bin/auto-opacity <<'EOF'
#!/usr/bin/env bash
# auto-opacity: transparencia para ventanas en Cinnamon (X11).
# Se activa solo cuando se abre/cierra una ventana o cambia el foco. No hace polling.
# Uso: auto-opacity            -> modo automático (el que arranca con la sesión)
#      auto-opacity now [pct]  -> aplicar ahora a todas las ventanas abiertas
#      auto-opacity reset      -> dejar todas las ventanas opacas
#      auto-opacity stop       -> detener el modo automático
set -u

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/auto-opacity.conf"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/auto-opacity-$(id -u).lock"
OPACITY=95   # porcentaje (1-100)
EXCLUDE=""   # regex de clases a excluir, ej: "vlc|mpv|obs"
# shellcheck disable=SC1090
[ -f "$CONF" ] && . "$CONF"

hex() { local p=$1; [ "$p" -lt 20 ] && p=20; [ "$p" -gt 100 ] && p=100; printf '0x%x' $(( 0xffffffff * p / 100 )); }  # mínimo 20% para no perder ventanas
ids() { xprop -root _NET_CLIENT_LIST 2>/dev/null | grep -o '0x[0-9a-fA-F]\+'; }
set_op() { xprop -id "$1" -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY "$2" 2>/dev/null; }
clear_op() { xprop -id "$1" -remove _NET_WM_WINDOW_OPACITY 2>/dev/null; }
is_fs() { xprop -id "$1" _NET_WM_STATE 2>/dev/null | grep -q _NET_WM_STATE_FULLSCREEN; }

# ¿esta ventana debe quedar opaca? (menús, docks, excluidas)
skip_window() {
  local p
  p=$(xprop -id "$1" _NET_WM_WINDOW_TYPE WM_CLASS 2>/dev/null) || return 0
  grep -Eq 'WINDOW_TYPE_(DOCK|DESKTOP|MENU|DROPDOWN_MENU|POPUP_MENU|TOOLTIP|NOTIFICATION|COMBO|DND|SPLASH)' <<<"$p" && return 0
  [ -n "$EXCLUDE" ] && grep -Eqi "$EXCLUDE" <<<"$p" && return 0
  return 1
}

case "${1:-}" in
  now)
    [ -n "${2:-}" ] && OPACITY="$2"
    case "$OPACITY" in ''|*[!0-9]*) echo "porcentaje inválido" >&2; exit 1;; esac
    H=$(hex "$OPACITY")
    for w in $(ids); do skip_window "$w" || is_fs "$w" || set_op "$w" "$H"; done
    exit 0 ;;
  reset)
    for w in $(ids); do clear_op "$w"; done
    exit 0 ;;
  stop)
    [ -f "$LOCK" ] && kill "$(cat "$LOCK")" 2>/dev/null
    exit 0 ;;
esac

# --- modo automático ---
command -v flock >/dev/null || { echo "falta flock" >&2; exit 1; }
exec 9>>"$LOCK"
flock -n 9 || exit 0            # ya hay una instancia corriendo
: > "$LOCK"; echo $$ >&9

for _ in $(seq 1 60); do        # esperar a que X esté listo
  xprop -root _NET_CLIENT_LIST >/dev/null 2>&1 && break
  sleep 1
done

case "$OPACITY" in ''|*[!0-9]*) OPACITY=95;; esac
H=$(hex "$OPACITY")
declare -A seen fs

coproc XP { xprop -root -spy _NET_CLIENT_LIST _NET_ACTIVE_WINDOW 9>&-; }
trap 'kill "${XP_PID:-}" 2>/dev/null' EXIT
trap 'exit 0' TERM INT HUP

while IFS= read -r line <&"${XP[0]}"; do
  case "$line" in
    _NET_CLIENT_LIST*)
      declare -A cur=()
      for w in $(grep -o '0x[0-9a-fA-F]\+' <<<"$line"); do
        cur[$w]=1
        if [ -z "${seen[$w]:-}" ]; then
          seen[$w]=1
          if ! skip_window "$w"; then
            if is_fs "$w"; then fs[$w]=1; else set_op "$w" "$H"; fi
          fi
        fi
      done
      for w in "${!seen[@]}"; do   # olvidar ventanas cerradas
        [ -z "${cur[$w]:-}" ] && { unset "seen[$w]" "fs[$w]"; }
      done ;;
    _NET_ACTIVE_WINDOW*)
      w=$(grep -o '0x[0-9a-fA-F]\+' <<<"$line" | head -n1)
      [ -z "$w" ] && continue
      [ -z "${seen[$w]:-}" ] && continue
      skip_window "$w" && continue
      if is_fs "$w"; then
        [ -z "${fs[$w]:-}" ] && { fs[$w]=1; clear_op "$w"; }   # pantalla completa -> opaca
      elif [ -n "${fs[$w]:-}" ]; then
        unset "fs[$w]"; set_op "$w" "$H"                        # salió de pantalla completa
      fi ;;
  esac
done

exit 0
EOF
chmod +x ~/.local/bin/auto-opacity

# 3. configuración (solo si no existe)
[ -f ~/.config/auto-opacity.conf ] || cat > ~/.config/auto-opacity.conf <<'EOF'
OPACITY=95
EXCLUDE=""
EOF

# 4. inicio automático
cat > ~/.config/autostart/auto-opacity.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Auto Opacity
Exec=nice -n 19 $HOME/.local/bin/auto-opacity
EOF

# 5. arrancar ya
nohup ~/.local/bin/auto-opacity >/dev/null 2>&1 &
```

Si dice "command not found" al usar `auto-opacity` a secas, cerrar sesión y volver a entrar, o usar la ruta completa `~/.local/bin/auto-opacity`.

### Comandos

| Comando | Qué hace |
|---------|----------|
| `auto-opacity now 90` | Aplica 90% ahora a todas las ventanas abiertas |
| `auto-opacity reset` | Deja todas las ventanas opacas |
| `auto-opacity stop` | Detiene el modo automático |

### ¿Cómo sé si está corriendo?

```bash
pgrep -f "bin/auto-opacity"
```

Si sale un número, está corriendo. Si no sale nada, arrancarlo a mano:

```bash
nohup ~/.local/bin/auto-opacity >/dev/null 2>&1 &
```

### Explicación rápida de las partes

| Parte | Qué hace |
|-------|----------|
| `~/.local/bin/auto-opacity` | El script en sí |
| `~/.config/auto-opacity.conf` | Tu configuración: nivel de opacidad y apps excluidas |
| `~/.config/autostart/auto-opacity.desktop` | Le dice a Mint que arranque el script al iniciar sesión |

### Nota de prueba

El script se probó con un `xprop` simulado (no se duplica, se detiene limpio, respeta pantalla completa, no deja procesos colgados). La prueba real en Cinnamon es abrir unas ventanas y confirmar que quedan transparentes.

---

## 3. Cambiar el nivel de opacidad

**Ventanas:** editar `OPACITY=` en el archivo de configuración (1 a 100, mínimo efectivo 20) y reiniciar el script:

```bash
sed -i 's/^OPACITY=.*/OPACITY=90/' ~/.config/auto-opacity.conf
~/.local/bin/auto-opacity stop; sleep 1
nohup ~/.local/bin/auto-opacity >/dev/null 2>&1 &
~/.local/bin/auto-opacity now 90
```

El último comando es para aplicarlo también a las ventanas que ya están abiertas.

Referencia:

| Opacidad | Valor de `OPACITY` |
|----------|--------------------|
| Sólido | `100` |
| Poco transparente | `95` |
| Medio | `90` |
| Más transparente | `85` |
| Muy transparente | `80` |

**Panel:** cambiar el `0.85` por el número deseado (1 es sólido, 0 es invisible):

```bash
sed -i '420s/rgba(29, 29, 33, [0-9.]*)/rgba(29, 29, 33, 0.85)/' ~/.themes/Mint-Y-Dark/cinnamon/cinnamon.css && cinnamon --replace >/dev/null 2>&1 &
```

**Excluir una app** (que no se le aplique transparencia): editar `EXCLUDE=` en `~/.config/auto-opacity.conf`, por ejemplo `EXCLUDE="vlc|mpv"`, y reiniciar el script como arriba.

---

## 4. Blur (desenfoque) con Blur Cinnamon

Requiere Cinnamon 6.0 o superior y X11.

1. Desactivar antes: Transparent panels, Transparent panels reloaded y Blur Overview (si están instaladas). Juntas pueden dar efectos raros.
2. Configuración del sistema → Extensiones → Descargar → Blur Cinnamon → Instalar.
3. Pestaña Administrar → seleccionarla → botón `+`.
4. Abrir su configuración (engranaje) y ajustar el blur.
5. Para ventanas: hacer transparente la app con su propia configuración (ej. terminal), activar "Application Windows" en "General Setup" y elegir "Windows" en "Component specific settings".
6. Si no aparece el efecto, reiniciar Cinnamon: `Alt+F2`, escribir `r`, Enter.

Notas:
- Blur Cinnamon ya hace transparente el panel por su cuenta. Si choca con la edición del `cinnamon.css`, volver el panel a `0.99`.
- El blur puede no verse en ventanas a las que solo se les puso transparencia con `auto-opacity`.

---

## 5. Revertir todo

Ventanas: dejarlas opacas y quitar el script:

```bash
~/.local/bin/auto-opacity reset
~/.local/bin/auto-opacity stop
rm -f ~/.local/bin/auto-opacity ~/.config/auto-opacity.conf ~/.config/autostart/auto-opacity.desktop
```

Panel a su estado original:

```bash
rm -rf ~/.themes/Mint-Y-Dark && cinnamon --replace >/dev/null 2>&1 &
```

---

## Problemas conocidos

- **Nemo abre con errores de `gi` / `pygobject`:** no viene de la transparencia. Es un entorno virtual o pyenv activo en la terminal. Abrir Nemo desde el menú de Mint o con `env -u VIRTUAL_ENV -u PYTHONHOME -u PYTHONPATH PATH=/usr/bin:/bin nemo &`.
- **El scroll sobre la barra de título no baja la opacidad:** la opción `action-scroll-titlebar` existe en 6.4.14, pero no funciona en ventanas que dibujan su propia barra de título.
- **Cambiar el color de las ventanas (morado, etc.):** no se logró de forma consistente. Cada app se pinta con su propio tema, así que se probó y se descartó.
- **Una app queda rara o transparente cuando no debería:** agregarla a `EXCLUDE=` en la configuración.
