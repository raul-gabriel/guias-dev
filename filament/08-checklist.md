[← Anterior](07-problemas-comunes.md) | [Índice](README.md)

# Checklist rápido de un CRUD

1. `php artisan make:model Modelo -m`
2. Editar columnas en `database/migrations/xxxx_create_modelos_table.php`
3. Editar `$fillable` en `app/Models/Modelo.php` (si hay galería, agregar `$casts`)
4. `php artisan migrate` (si hay imágenes, también `php artisan storage:link`)
5. `php artisan make:filament-resource Modelo --generate` (Title attribute, View page: No)
6. En `Tables/ModelosTable.php`: `ViewAction`, `EditAction`, `DeleteAction`
7. En `Pages/CreateModelo.php`: `getRedirectUrl()`
8. Si tiene imagen: `FileUpload` en el formulario e `ImageColumn` en la tabla
9. Si tiene relación: `Select` con `->relationship()` y columna `relacion.nombre`
10. `php artisan optimize:clear` y `php artisan serve`

---

[← Anterior](07-problemas-comunes.md) | [Índice](README.md)
