# Guía de Cloudflare Zero Trust para un equipo pequeño (hasta 20 personas)

Permite que tu equipo (programadores y practicantes) llegue al backend de desarrollo **sin VPS, sin IP pública y sin pagar**, desde cualquier red (WiFi, datos móviles, casa).

> **Nota:** Cloudflare cambia los nombres de menús y comandos con frecuencia. Si algo no coincide con esta guía, usa el asistente **Get started** del panel (te guía paso a paso) y la documentación: https://developers.cloudflare.com/cloudflare-one/

---

## 0. Cómo funciona (en 30 segundos)

```
 Celular / PC del equipo                Cloudflare                 Tu laptop (backend)
 ┌────────────────────┐   túnel   ┌──────────────┐   túnel   ┌──────────────────────┐
 │ Cloudflare One     │──────────▶│  Red global  │◀──────────│ cloudflared          │
 │ Client (WARP)      │           │  Cloudflare  │  (salida) │ + tu backend :8000   │
 └────────────────────┘           └──────────────┘           └──────────────────────┘
```

- En la máquina del backend instalas **`cloudflared`** (el conector). Hace una conexión **de salida**, así que no abres puertos ni necesitas IP pública.
- En cada equipo del equipo instalas el **Cloudflare One Client** (antes llamado WARP).
- Cada persona inicia sesión con **su correo**: Cloudflare le envía un **código de un solo uso (One-time PIN)**. No hace falta Gmail ni SSO.

**Plan gratis:** hasta 50 usuarios, así que 20 personas caben de sobra.

---

## 1. Crear la cuenta de Cloudflare (una sola vez)

1. Entra a **https://dash.cloudflare.com/sign-up**
2. Regístrate con **correo y contraseña** (no necesitas Google).
3. Confirma tu correo.

## 2. Activar Zero Trust (plan Free)

1. Entra a **https://one.dash.cloudflare.com/** (panel de Cloudflare One / Zero Trust).
2. Si es la primera vez, te pedirá un **nombre de equipo (team name)**. Ejemplo: `miestartup`.
   - **Anótalo**: cada persona lo necesitará para iniciar sesión (será `miestartup.cloudflareaccess.com`).
3. Elige el plan **Free**.
   - Es posible que te pida registrar un método de pago (tarjeta o PayPal) como verificación aunque el plan sea gratis. Si pasa, revisa en pantalla qué te cobrarían antes de confirmar. El plan Free no debería generar cargos mientras no pases de 50 usuarios.

> El plan gratis es válido para uso en tu empresa. Pasando de 50 usuarios se cambia a pago por uso.

---

## 3. Configurar el login por código al correo (One-time PIN)

Normalmente **ya viene activado por defecto** si no conectas otro proveedor de identidad. Para comprobarlo:

1. En el panel: **Integrations → Identity providers** (en algunas versiones: *Settings → Authentication*).
2. Verifica que **One-time PIN** esté en la lista.

---

## 4. Instalar el conector `cloudflared` en la máquina del backend

Haz esto en la **laptop o máquina donde corre tu backend**.

### 4.1 Crear el túnel (en el panel)

1. En el panel ve a la pestaña **Get started** (Empezar).
2. Elige **Connect a remote device to a private network** (o similar: *"Device to network"*).
3. Ponle nombre al túnel, por ejemplo `backend-dev`.
4. El panel te mostrará **un comando con tu token** para instalar el conector. **Cópialo de ahí**, porque incluye tu token único.

Si prefieres crearlo manualmente: **Networks → Connectors → Cloudflare Tunnels → Create a tunnel** (el nombre del menú puede variar).

### 4.2 Instalar en Debian / Ubuntu

```bash
# Agregar el repositorio oficial de Cloudflare
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

# Instalar
sudo apt-get update && sudo apt-get install cloudflared
```

> Si estos comandos fallan, copia los que muestra el panel en el paso 4.1: son los vigentes.

### 4.3 Conectar el túnel con tu token

```bash
sudo cloudflared service install <TU_TOKEN_DEL_TUNEL>
```

Esto lo instala como servicio y arranca solo con el sistema.

Comprueba que está activo:

```bash
sudo systemctl status cloudflared
```

En el panel, el túnel debe aparecer como **Healthy** (saludable).

### 4.4 En Windows (si el backend corre en Windows)

El panel te da el instalador y el comando exacto. Normalmente es descargar el `.msi` de `cloudflared` y, en PowerShell **como administrador**:

```powershell
cloudflared.exe service install <TU_TOKEN_DEL_TUNEL>
```

---

## 5. Decirle al túnel qué red privada puede alcanzar

El túnel necesita saber qué IP(s) puede dar a tu equipo.

1. En el panel ve a **Networks → Routes** (o dentro del túnel: pestaña **Private networks / CIDR routes**).
2. Agrega una ruta con la **IP privada de la máquina del backend**.

Para ver esa IP en Linux:

```bash
ip a
```

Busca algo como `192.168.1.25` o `10.0.0.25`.

3. Agrega la ruta como **`192.168.1.25/32`** (el `/32` significa "solo esa IP").

> **Recomendado:** usa `/32` en vez de toda la red (`/24`). Así tu equipo solo puede llegar a esa máquina y no a todo lo demás que esté en esa red.

> **Tip:** Haz que esa IP no cambie. Reserva una IP fija en tu router o configura IP estática en la máquina, o la ruta dejará de funcionar si se reinicia con otra IP.

---

## 6. Permitir que tu equipo conecte sus dispositivos

Aquí defines **quién** puede unirse.

1. Panel: **Team & Resources → Devices → Device profiles → Management** (o *Settings → WARP Client → Device enrollment permissions*).
2. En **Device enrollment permissions** pulsa **Manage**.
3. En la pestaña **Policies** crea una política:
   - **Action:** Allow
   - **Include → Emails:** agrega los correos de tu equipo, uno por uno (por ejemplo `ana@gmail.com`, `luis@outlook.com`, `practicante1@proton.me`).
   - Si todos usan el dominio de tu empresa, puedes usar **Emails ending in** `@tuempresa.com`.
4. Guarda.

> **Cuando alguien se va del equipo:** quita su correo de esta política y revoca su sesión en **Team & Resources → Users**.

---

## 7. Quitar la exclusión de IPs privadas (Split Tunnels)

Por defecto, el cliente de Cloudflare **no envía por el túnel** el tráfico hacia IPs privadas (`10.0.0.0/8`, `192.168.0.0/16`, etc.). Hay que quitar tu rango de esa lista, o tu equipo nunca llegará a tu backend.

1. Panel: **Team & Resources → Devices → Device profiles**.
2. Edita el perfil **Default** (o el que uses).
3. Entra a **Split Tunnels**.
4. Si el modo es **Exclude IPs and domains**, **elimina de la lista** el rango que contiene la IP de tu backend (por ejemplo `192.168.0.0/16` o `10.0.0.0/8`).
   - Si quieres ser más fino, puedes agregar de vuelta rangos más pequeños que no incluyan tu IP.
5. Guarda.

> El asistente **Get started** (paso 4.1) suele hacer esto por ti. Revisa de todas formas que el rango no siga excluido.

---

## 8. Instalar el Cloudflare One Client en cada dispositivo

Descarga oficial: **https://one.one.one.one/** (o desde el panel: *Team & Resources → Devices → Download*).

### 8.1 Linux (Debian / Ubuntu)

```bash
# Repositorio oficial del cliente
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

# Instalar
sudo apt-get update && sudo apt-get install cloudflare-warp
```

Luego inscribe el equipo en tu organización. La forma más simple es con el comando que indica la documentación vigente de tu panel; revisa las opciones con:

```bash
warp-cli --help
```

Comandos útiles:

```bash
warp-cli status        # ver estado
warp-cli connect       # conectar
warp-cli disconnect    # desconectar
```

### 8.2 Android

1. Abre **Google Play Store** y busca **Cloudflare One Agent** (o la app **1.1.1.1 / Cloudflare One**).
2. Instálala y ábrela.
3. Ve a **Settings / Ajustes → Account → Login to Cloudflare Zero Trust**.
4. Ingresa tu **team name** (por ejemplo `miestartup`).
5. Pon tu correo, te llegará un **código de un solo uso**, escríbelo.
6. Activa el interruptor para conectar.

### 8.3 Windows

1. Descarga el instalador desde **https://one.one.one.one/** (o desde el panel) e instálalo.
2. Abre el ícono de la bandeja del sistema (junto al reloj).
3. Ve a **Preferences → Account → Login with Cloudflare Zero Trust**.
4. Ingresa el **team name**.
5. Escribe tu correo, recibe el código de un solo uso y escríbelo.
6. Verifica que quede en estado **Connected**.

---

## 9. Probar que funciona

Con el backend corriendo en la máquina del túnel y escuchando en `0.0.0.0` (no solo `localhost`):

```bash
# Ejemplos para levantar el backend
uvicorn main:app --host 0.0.0.0 --port 8000
# Node/Express: app.listen(8000, '0.0.0.0')
```

Desde el dispositivo del equipo (con el cliente conectado):

```bash
curl http://192.168.1.25:8000
```

Cambia la IP por la de tu backend y el puerto por el tuyo. En el celular, abre `http://192.168.1.25:8000` en el navegador. En tu app, usa `ws://192.168.1.25:8000/...`.

---

## 10. Invitar al equipo (qué decirles)

Envía a cada integrante este mensaje:

> 1. Instala **Cloudflare One Client** (https://one.one.one.one/).
> 2. En el cliente: **Login to Cloudflare Zero Trust**.
> 3. Team name: **`miestartup`** (usa el tuyo).
> 4. Escribe tu correo (el que te registré). Te llegará un código, pégalo.
> 5. Con el cliente conectado, abre `http://IP-DEL-BACKEND:8000`.

---

## 11. Si algo no funciona

| Problema | Qué revisar |
|---|---|
| El túnel aparece "Down" | `sudo systemctl status cloudflared` y que la máquina tenga internet |
| No llega el código al correo | Revisa spam, y que el correo esté en la política de **Device enrollment permissions** |
| Dice "no tienes permiso" al iniciar sesión | El correo no está en la política del paso 6 |
| Conecta el cliente pero no llega al backend | Revisa la ruta `/32` (paso 5) y el **Split Tunnels** (paso 7) |
| Funciona en unas redes y en otras no | Puede haber choque de rangos: si la red de la persona usa la misma IP privada (por ejemplo `192.168.1.25`), el tráfico se confunde. Prueba con una IP de un rango poco común, como `10.77.x.x`, para el backend si puedes configurarla |
| Timeout al llamar a la IP | El backend debe escuchar en `0.0.0.0` y el firewall (`ufw` / Windows) debe permitir el puerto |
| Se pierde la conexión al reiniciar la laptop | Asegúrate de usar `service install` (arranca solo) y una IP fija |

Comandos útiles de diagnóstico en Linux:

```bash
sudo systemctl status cloudflared     # estado del conector
sudo journalctl -u cloudflared -f     # logs del conector en vivo
warp-cli status                       # estado del cliente
```

---

## 12. Buenas prácticas de seguridad

- Usa rutas `/32` (solo las máquinas necesarias), no toda tu red.
- Agrega solo los correos que necesiten acceso y quita los de quien se vaya.
- No compartas el **token del túnel**: quien lo tenga puede conectarse como tu conector. Si se filtra, rótalo/borra el túnel y crea otro.
- Activa verificación en dos pasos en tu cuenta de Cloudflare.

---

## 13. Límites y costos

- **Gratis:** hasta **50 usuarios**.
- Si pasas de 50, se cambia a **pago por uso** (una fuente indica alrededor de 7 dólares por usuario al mes). Verifica el precio actual en la página oficial.
- Esto sirve para **desarrollo y pruebas internas**. Tus usuarios finales no instalarán Cloudflare One Client.

---

## 14. Para producción

Tus clientes y usuarios reales no usarán este túnel. Para producción necesitas que el backend esté accesible por internet con un dominio y HTTPS (`wss://tu-dominio/...`). Opciones:

- Un VPS económico (Hetzner, Contabo, DigitalOcean).
- **Cloudflare Tunnel con un hostname público**: expones tu backend con un dominio sin abrir puertos (requiere un dominio en Cloudflare, unos 10 dólares al año).

---

## Resumen rápido

1. Cuenta en https://dash.cloudflare.com/sign-up (correo + contraseña).
2. Zero Trust → team name → plan **Free**.
3. En la máquina del backend: instalar `cloudflared` y `sudo cloudflared service install <TOKEN>`.
4. Ruta privada: `IP-DEL-BACKEND/32`.
5. **Device enrollment permissions**: agregar los correos del equipo.
6. **Split Tunnels**: quitar de la exclusión el rango privado.
7. Cada persona instala **Cloudflare One Client** → login con team name + código por correo.
8. Probar: `http://IP-DEL-BACKEND:8000`.




video: https://www.youtube.com/watch?v=vyp3CIz6PaY
