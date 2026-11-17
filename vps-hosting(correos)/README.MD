# Guía: Configurar dominio con web en VPS y correo en cPanel

## 1. Objetivo

Configurar un dominio para que:

- El dominio principal (`dominio.com`) apunte al VPS donde está alojada la página web.
- `www.dominio.com` también apunte al VPS.
- Los subdominios web puedan apuntar al VPS.
- El correo corporativo (`correo@dominio.com`) funcione desde el hosting cPanel.
- El acceso a webmail y los servicios de correo sigan funcionando desde cPanel.

### Ejemplo de configuración

| Servicio | Dirección IP |
|---|---|
| VPS (página web) | `169.58.84.167` |
| Hosting cPanel (correo) | `169.58.200.39` |

*Las IP deben reemplazarse por las correspondientes a cada proyecto.*

---

## 2. Configurar los Nameservers del dominio

Primero, ingresar al panel donde se compró o administra el dominio (registrador).

Buscar la opción **Nameservers / Servidores DNS** y colocar los nameservers proporcionados por el hosting.

Ejemplo utilizado:

```text
ns1.perfect-dns.com
ns2.perfect-dns.com
```

**Importante:**
- Los nameservers se modifican en el panel del registrador del dominio.
- No se modifican desde Zone Editor.
- Cada proveedor puede proporcionar nameservers diferentes.
- No utilizar los nameservers de otro proveedor sin verificar que administren la zona DNS correspondiente.

Guardar los cambios y esperar la propagación.

---

## 3. Ingresar a cPanel y abrir Zone Editor

Una vez configurados los Nameservers:

1. Ingresar al cPanel del hosting.
2. Buscar **Domains → Zone Editor**.
3. Seleccionar el dominio.
4. Administrar los registros DNS desde esta sección.

A partir de este momento, los registros deben configurarse en la zona DNS que administran los nameservers activos.

---

## 4. Configurar la página web en el VPS

Crear o modificar estos registros:

| Nombre | Tipo | Contenido |
|---|---|---|
| `dominio.com` | A | IP del VPS |
| `www.dominio.com` | CNAME | `dominio.com` |
| `*.dominio.com` | A | IP del VPS |

Ejemplo:

```text
dominio.com       A       169.58.84.167
www.dominio.com   CNAME   dominio.com
*.dominio.com     A       169.58.84.167
```

El registro `*` permite que los subdominios que no tengan un registro específico apunten al VPS.

Si necesitas que un subdominio apunte a otro servidor, debes crear un registro específico para ese subdominio.

---

## 5. Configurar el correo corporativo en cPanel

El correo debe permanecer en el hosting, no en el VPS.

### 5.1. Registro A para mail

Crear o modificar:

| Nombre | Tipo | Contenido |
|---|---|---|
| `mail.dominio.com` | A | IP del hosting |

Ejemplo:

```text
mail.dominio.com    A    169.58.200.39
```

Si existe un registro `CNAME` para `mail`, eliminarlo antes de crear el registro `A`. Un mismo nombre no puede tener simultáneamente un CNAME y otros registros DNS.

### 5.2. Registro MX

Configurar el registro MX:

| Nombre | Tipo | Prioridad | Destino |
|---|---|---|---|
| `dominio.com` | MX | 10 | `mail.dominio.com` |

Ejemplo:

```text
dominio.com    MX    10    mail.dominio.com
```

El MX debe apuntar al nombre del servidor de correo, no a la IP directamente.

### 5.3. Otros registros de cPanel

Conservar los registros que el hosting proporciona para sus servicios, siempre que correspondan al servidor utilizado.

Ejemplos:

| Nombre | Tipo | Contenido |
|---|---|---|
| `webmail.dominio.com` | A | IP del hosting |
| `cpanel.dominio.com` | A | IP del hosting |
| `whm.dominio.com` | A | IP del hosting |
| `webdisk.dominio.com` | A | IP del hosting |
| `autoconfig.dominio.com` | A | IP del hosting |
| `autodiscover.dominio.com` | A | IP del hosting |

No reemplazar automáticamente estos registros por la IP del VPS.

---

## 6. Conservar los registros de autenticación del correo

No eliminar los registros de autenticación que proporciona cPanel.

Deben revisarse:

- **SPF:** autoriza los servidores que pueden enviar correos.
- **DKIM:** permite verificar la autenticidad de los mensajes.
- **DMARC:** establece cómo deben tratarse los mensajes que no superan las verificaciones.

En cPanel:

1. Entrar a **Email → Email Deliverability**.
2. Seleccionar el dominio.
3. Revisar los estados de SPF y DKIM.
4. Si aparecen problemas, utilizar los registros recomendados por cPanel.

Importante:
- Mantener un solo registro SPF para el dominio.
- No copiar registros DKIM de otro proveedor.
- No eliminar el registro DMARC existente sin necesidad.
- No cambiar la política DMARC a `quarantine` o `reject` antes de comprobar que SPF y DKIM funcionan correctamente.

---

## 7. Verificar la configuración DNS

Desde una terminal Linux, ejecutar:

### Verificar el dominio principal

```bash
dig dominio.com A +short
```

Resultado esperado: IP del VPS.

### Verificar www

```bash
dig www.dominio.com +short
```

Resultado esperado: resolución hacia la IP del VPS.

### Verificar el correo

```bash
dig mail.dominio.com A +short
```

Resultado esperado: IP del hosting.

### Verificar el MX

```bash
dig dominio.com MX +short
```

Resultado esperado:

```text
10 mail.dominio.com.
```

### Verificar nameservers

```bash
dig dominio.com NS +short
```

Resultado esperado: los nameservers configurados en el registrador.

---

## 8. Comprobar el funcionamiento

Realizar las siguientes pruebas:

- Abrir `https://dominio.com`.
- Abrir `https://www.dominio.com`.
- Comprobar que la página responde desde el VPS.
- Ingresar a `https://webmail.dominio.com`.
- Iniciar sesión con una cuenta corporativa.
- Enviar un correo de prueba a Gmail.
- Responder desde Gmail y comprobar la recepción.
- Revisar si el mensaje llega a Recibidos o Spam.

---

## 9. Arquitectura final

```text
                    DOMINIO
                 dominio.com
                       |
              Nameservers Hosting
                       |
                  Zone Editor
                       |
          +------------+-------------+
          |                          |
     WEB / VPS                 CORREO / CPANEL
     169.58.84.167             169.58.200.39
          |                          |
     dominio.com                mail.dominio.com
     www.dominio.com             webmail.dominio.com
     *.dominio.com               cpanel.dominio.com
                                  correo corporativo
```

## 10. Recomendaciones importantes

1. Configurar primero los Nameservers en el registrador.
2. Administrar los registros DNS desde el Zone Editor de la zona autoritativa.
3. Apuntar el dominio principal y los subdominios web al VPS.
4. Mantener `mail`, `webmail` y los servicios de correo apuntando al hosting.
5. Configurar correctamente el MX.
6. Conservar y verificar SPF, DKIM y DMARC.
7. No cambiar los Nameservers nuevamente después de configurar la zona, salvo que exista una razón para migrar el DNS.
8. Esperar la propagación DNS y verificar con `dig` antes de dar por terminada la configuración.

**Resultado:** la página web se ejecuta en el VPS, mientras que las cuentas de correo corporativo continúan funcionando desde el hosting cPanel.
