# Guía: cambiar el logo de arranque de Linux Mint (Plymouth)

Reemplaza el logo que aparece cuando enciende la PC (pantalla de carga del tema `mint-logo`) por una imagen propia.

---

## Requisitos

Imagen:

- Formato: **PNG**
- Tamaño: **256 x 256**
- Modo: **RGBA, con fondo transparente**

En los comandos se usa esta ruta (cambiarla por la tuya):

```
~/Imágenes/iconos/fondo/home.png
```

---

## Procedimiento

Pegar el bloque completo en la terminal:

```bash
LOGO=~/Imágenes/iconos/fondo/home.png
cd /usr/share/plymouth/themes/mint-logo/

# respaldo
sudo mkdir -p /root/mint-logo-bak
sudo cp animation-*.png throbber-*.png /root/mint-logo-bak/

# reemplazo
sudo rm animation-*.png throbber-*.png
sudo cp "$LOGO" animation-0001.png
sudo cp "$LOGO" throbber-0001.png

# aplicar al initramfs
sudo update-initramfs -u -k all

# verificar: debe salir solo animation-0001 y throbber-0001
lsinitramfs /boot/initrd.img-$(uname -r) | grep -i plymouth/themes/mint-logo

sudo reboot
```

### Qué hace cada parte

| Paso | Qué hace |
|------|----------|
| `LOGO=...` | Guarda la ruta de tu imagen en una variable |
| `cd /usr/share/plymouth/themes/mint-logo/` | Entra a la carpeta del tema de arranque |
| Respaldo | Copia las imágenes originales a `/root/mint-logo-bak` |
| Reemplazo | Borra las imágenes originales y pone tu logo como `animation-0001.png` y `throbber-0001.png` |
| `update-initramfs -u -k all` | Regenera el arranque para que incluya el logo nuevo |
| `lsinitramfs ... \| grep` | Verifica que el logo quedó dentro del arranque |
| `sudo reboot` | Reinicia para ver el resultado |

### Verificación

El comando `lsinitramfs` debe mostrar **solo** estos dos archivos:

```
animation-0001.png
throbber-0001.png
```

Si salen más, el reemplazo no se aplicó bien: revisar que el `rm` borró las imágenes originales y repetir desde `update-initramfs`.

Guardar el trabajo antes de ejecutar `sudo reboot`, porque reinicia la PC de inmediato.

---

## Restaurar el logo original

Si algo sale mal o quieres volver al logo de Mint, usar el respaldo:

```bash
cd /usr/share/plymouth/themes/mint-logo/
sudo rm -f animation-*.png throbber-*.png
sudo cp /root/mint-logo-bak/* .
sudo update-initramfs -u -k all
sudo reboot
```

---

## Notas

- Si el paquete del tema se actualiza con el sistema (`apt upgrade`), puede volver a poner las imágenes originales. En ese caso repetir el procedimiento.
- No borrar `/root/mint-logo-bak`: es el único respaldo del logo original.
- Usar `-k all` regenera el arranque de todos los kernels instalados, así que puede tardar un poco.
