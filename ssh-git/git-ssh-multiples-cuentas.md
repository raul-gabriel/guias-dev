# Git con múltiples cuentas por SSH (GitHub / GitLab / servidor interno)

Una llave SSH por cuenta + un alias en `~/.ssh/config` por cada una.

> **Regla:** no usar un solo `Host gitlab.com` con varias llaves. SSH prueba las llaves en orden y el servidor acepta la primera que reconozca, así siempre entrarías con la misma cuenta.

## 1) Generar la llave SSH

```bash
cd ~/.ssh
ssh-keygen -t ed25519 -C "gitlab-NOMBRE" -f ~/.ssh/gitlab_NOMBRE -N ""
chmod 600 ~/.ssh/gitlab_NOMBRE
chmod 644 ~/.ssh/gitlab_NOMBRE.pub
```

`-N ""` = sin passphrase.

## 2) Ver y copiar la llave pública

```bash
cat ~/.ssh/gitlab_NOMBRE.pub
```

## 3) Pegarla en el servidor correcto

En GitLab: avatar → Edit profile → SSH Keys → Add new key.
En GitHub: Settings → SSH and GPG keys → New SSH key.

Confirma el dominio real del servidor con:

```bash
git remote -v
```

Puede ser `gitlab.com`, `github.com` o una IP/dominio interno.

## 4) Agregar la llave al ssh-agent (opcional)

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/gitlab_NOMBRE
ssh-add -l
```

## 5) Editar `~/.ssh/config`

```bash
nano ~/.ssh/config
```

Agregar **un bloque por cuenta**, con alias propio y su única llave:

```text
Host ALIAS
  HostName DOMINIO_O_IP
  User git
  IdentityFile ~/.ssh/gitlab_NOMBRE
  IdentitiesOnly yes
```

Ejemplos de `HostName`:

- `gitlab.com`
- `github.com`
- `172.16.5.108` (servidor interno)

### Ejemplo completo

```text
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/github_personal
  IdentitiesOnly yes

Host gitlab-trabajo
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/gitlab_trabajo
  IdentitiesOnly yes

Host gitlab-interno
  HostName 172.16.5.108
  User git
  IdentityFile ~/.ssh/gitlab_interno
  IdentitiesOnly yes
```

## 6) Probar la conexión

```bash
ssh -T git@ALIAS
```

Debe responder con el saludo del usuario correcto (`Welcome to GitLab, @usuario`).

## 7) Usar el alias en las URLs

Ver URL actual:

```bash
git remote -v
```

Cambiar la URL de un repo existente:

```bash
git remote set-url origin git@ALIAS:grupo/repo.git
```

Clonar un repo nuevo:

```bash
git clone git@ALIAS:grupo/repo.git
```

## 8) Identidad de commits (solo en ese repo)

```bash
git config user.name "NOMBRE"
git config user.email "CORREO_DE_ESA_CUENTA"
```

## Solución de problemas

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| `Permission denied (publickey)` | La pública no está en esa cuenta/servidor | Volver a pegarla en el servidor correcto |
| Funciona con otra cuenta | Falta `IdentitiesOnly yes` o se usa la URL sin alias | Usar el alias en la URL y agregar `IdentitiesOnly yes` |
| Nunca funciona aunque la llave sea nueva | El `HostName` es otro (GitLab interno) | Revisar con `git remote -v` el dominio/IP real |
| No conecta al servidor interno | Red privada | Conectarse a la red/VPN correspondiente |

Depurar qué llave se ofrece:

```bash
ssh -vT git@ALIAS 2>&1 | grep -E "identity file|Offering|Permission|Authenticated"
```
