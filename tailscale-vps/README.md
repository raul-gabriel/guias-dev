# Guía de Tailscale (Linux Debian/Ubuntu, Android y Windows)

Tailscale crea una **red privada (VPN)** entre tus dispositivos. Cada uno recibe una IP `100.x.x.x` y se pueden hablar entre sí aunque estén en WiFis distintos o con datos móviles.

> **Importante:** es solo para tus **pruebas de desarrollo**. En producción tus usuarios no usarán Tailscale: el backend va en un servidor con IP pública o dominio (`wss://tu-dominio/...`).

---

## 0. Crear la cuenta (una sola vez)

1. Entra a **https://login.tailscale.com/start**
2. Elige cómo registrarte: **Google, Microsoft, GitHub o Apple**.
3. Listo. Tu cuenta gratuita sirve para uso personal (hasta 100 dispositivos).

> Usa **la misma cuenta** en todos tus dispositivos (laptop, celular, PC de Windows). Así quedan en la misma red.

Panel de administración (ver tus dispositivos e IPs): **https://login.tailscale.com/admin/machines**

---

## 1. Linux (Debian / Ubuntu / Mint)

### Paso 1: Instalar

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Este script detecta tu distro e instala Tailscale automáticamente.

### Paso 2: Conectar e iniciar sesión

```bash
sudo tailscale up
```

Te mostrará un enlace parecido a:

```
To authenticate, visit:
        https://login.tailscale.com/a/xxxxxxxxxx
```

Ábrelo en el navegador, inicia sesión con tu cuenta y aprueba el dispositivo.

### Paso 3: Ver tu IP de Tailscale

```bash
tailscale ip -4
```

Ejemplo de salida: `100.64.12.34`

### Paso 4: Ver todos tus dispositivos conectados

```bash
tailscale status
```

Muestra una tabla con la IP y nombre de cada dispositivo (laptop, celular, etc.).

### Paso 5: Probar que el celular llega a la laptop

Con tu backend corriendo en la laptop, desde el celular usa:

```
http://100.64.12.34:8000
ws://100.64.12.34:8000/...
```

(Cambia la IP por la tuya y el puerto por el de tu backend.)

### Paso 6: Que tu backend acepte conexiones

Tu servidor debe escuchar en `0.0.0.0`, no solo en `localhost`. Ejemplos:

```bash
# FastAPI / Uvicorn
uvicorn main:app --host 0.0.0.0 --port 8000

# Node / Express: app.listen(8000, '0.0.0.0')
```

Si usas `ufw` (firewall), permite el tráfico de Tailscale:

```bash
sudo ufw allow in on tailscale0
```

### Comandos útiles

| Acción | Comando |
|---|---|
| Conectar | `sudo tailscale up` |
| Desconectar (temporal) | `sudo tailscale down` |
| Cerrar sesión | `sudo tailscale logout` |
| Ver mi IP | `tailscale ip -4` |
| Ver dispositivos | `tailscale status` |
| Probar conexión a otro dispositivo | `tailscale ping 100.x.x.x` |
| Ver versión | `tailscale version` |

---

## 2. Android

1. Abre **Google Play Store** e instala **Tailscale**.
2. Abre la app y toca **Get started / Sign in**.
3. Inicia sesión con **la misma cuenta** que usaste en la laptop.
4. Acepta la solicitud de VPN de Android (es normal, es el túnel de Tailscale).
5. Activa el interruptor para quedar **conectado**.
6. En la pantalla principal verás la **IP de tu celular** (`100.x.x.x`) y la lista de tus otros dispositivos con sus IPs.

Para probar: abre el navegador del celular y entra a `http://IP-TAILSCALE-DE-LA-LAPTOP:8000`.

> Tailscale en el celular **no cambia tu internet normal**. Solo el tráfico hacia las IPs `100.x.x.x` pasa por el túnel.

---

## 3. Windows (10 / 11)

Útil cuando usas una PC de Windows.

### Paso 1: Instalar

1. Descarga desde **https://tailscale.com/download/windows**
2. Ejecuta el instalador (`.exe`) y sigue los pasos.

### Paso 2: Iniciar sesión

1. Aparece el ícono de Tailscale junto al reloj (bandeja del sistema).
2. Clic en el ícono, luego **Log in**.
3. Se abre el navegador: inicia sesión con **la misma cuenta**.

### Paso 3: Ver tu IP

- Clic en el ícono de la bandeja: ahí aparece tu IP `100.x.x.x`.
- O en **PowerShell**:

```powershell
tailscale ip -4
```

### Comandos en Windows (PowerShell)

| Acción | Comando |
|---|---|
| Conectar | `tailscale up` |
| Desconectar | `tailscale down` |
| Cerrar sesión | `tailscale logout` |
| Ver mi IP | `tailscale ip -4` |
| Ver dispositivos | `tailscale status` |

También puedes usar el ícono de la bandeja: **Connect / Disconnect / Log out**.

### Firewall de Windows

Si tu backend corre en Windows y el celular no conecta, permite el puerto (PowerShell **como administrador**):

```powershell
New-NetFirewallRule -DisplayName "Backend 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow
```

---

## 4. Si algo no funciona

| Problema | Solución |
|---|---|
| El celular no llega a la laptop | Revisa que **ambos** estén conectados a Tailscale y con la **misma cuenta** (`tailscale status`) |
| Conecta el ping pero no la app | El backend debe escuchar en `0.0.0.0` y el firewall permitir el puerto |
| `tailscale: command not found` | Cierra y abre la terminal, o repite la instalación |
| No sale el enlace de login | Ejecuta `sudo tailscale up` otra vez |
| Quiero ver qué IP tiene cada equipo | https://login.tailscale.com/admin/machines |
| Conexión lenta | `tailscale ping 100.x.x.x` muestra si va directa o por relay |

---

## 5. Resumen rápido (Linux)

```bash
# 1. Instalar
curl -fsSL https://tailscale.com/install.sh | sh

# 2. Conectar (abre el link y entra con tu cuenta)
sudo tailscale up

# 3. Ver tu IP
tailscale ip -4

# 4. Correr tu backend accesible
uvicorn main:app --host 0.0.0.0 --port 8000

# 5. En el celular (con Tailscale activo)
#    usar http://TU-IP-100.x.x.x:8000
```

---

## 6. Para producción

Tailscale **no** es para tus usuarios finales. Para producción necesitas un **VPS** (DigitalOcean, Hetzner, Contabo, etc.) con IP pública o dominio, y tu app usará `wss://tu-dominio/...` con HTTPS.
