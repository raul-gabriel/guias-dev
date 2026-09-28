[Índice](README.md) | [Siguiente →](02-crud-basico.md)

# Instalación (una sola vez)

```bash
composer create-project laravel/laravel nombre-del-proyecto
cd nombre-del-proyecto
composer require filament/filament
php artisan filament:install --panels
```

Configurar la base de datos en `.env`:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nombre_de_la_bd
DB_USERNAME=root
DB_PASSWORD=
APP_URL=http://127.0.0.1:8000
```

Luego:

```bash
php artisan migrate
php artisan make:filament-user     # crear usuario, usuario: cuscocode
php artisan serve                  # http://127.0.0.1:8000/admin/login
```

Entrar a: http://127.0.0.1:8000/admin/login

Usuario de acceso: `cuscocode`

> Entra siempre con la misma URL que pusiste en `APP_URL` (127.0.0.1:8000, no localhost).

Idioma español (opcional), en `config/app.php`:

```php
'locale' => 'es',
```

---

[Índice](README.md) | [Siguiente →](02-crud-basico.md)
