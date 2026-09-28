[← Anterior](06-single-type.md) | [Índice](README.md) | [Siguiente →](08-checklist.md)

# Problemas comunes

**La página tarda mucho o no carga**

```bash
php artisan optimize:clear
```

Si sigue lento, revisa que `APP_URL` en `.env` coincida con la URL del navegador y arranca así:

```bash
PHP_CLI_SERVER_WORKERS=4 php artisan serve
```

**La imagen se sube pero no se ve**

```bash
php artisan storage:link
php artisan optimize:clear
```

Y revisa `APP_URL=http://127.0.0.1:8000` en `.env`.

**No aparece el botón Eliminar**

Falta `DeleteAction::make()` en `recordActions` y su `use Filament\Actions\DeleteAction;`.

**Al registrar sigue mostrando el formulario**

Revisa que no presiones **Crear y crear otro** y que `getRedirectUrl()` esté en la página Create.

**En la tabla sale un número en vez del nombre**

Usa la columna con punto: `TextColumn::make('categoria.nombre')`.

**Cuándo correr `php artisan optimize:clear`**

Cuando cambies el `.env`, agregues un campo y no lo veas, algo cargue lento sin razón, o crees un recurso y no aparezca en el menú.

---

[← Anterior](06-single-type.md) | [Índice](README.md) | [Siguiente →](08-checklist.md)
