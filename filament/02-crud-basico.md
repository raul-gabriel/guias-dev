[← Anterior](01-instalacion.md) | [Índice](README.md) | [Siguiente →](03-crud-con-imagen.md)

# CRUD básico (ejemplo: Libro)

### Paso 1. Crear modelo y migración

```bash
php artisan make:model Libro -m
```

### Paso 2. Editar la migración

Archivo: `database/migrations/xxxx_create_libros_table.php`

```php
public function up(): void
{
    Schema::create('libros', function (Blueprint $table) {
        $table->id();
        $table->string('titulo');
        $table->string('autor');
        $table->string('isbn')->nullable()->unique();
        $table->string('editorial')->nullable();
        $table->integer('anio_publicacion')->nullable();
        $table->decimal('precio', 10, 2)->default(0);
        $table->integer('stock')->default(0);
        $table->boolean('activo')->default(true);
        $table->timestamps();
    });
}
```

### Paso 3. Editar el modelo

Archivo: `app/Models/Libro.php`

```php
protected $fillable = [
    'titulo', 'autor', 'isbn', 'editorial',
    'anio_publicacion', 'precio', 'stock', 'activo',
];
```

### Paso 4. Migrar

```bash
php artisan migrate
```

### Paso 5. Crear el recurso de Filament

```bash
php artisan make:filament-resource Libro --generate
```

Cuando pregunte:

```
Title attribute: titulo
Read-only view page: No
```

### Paso 6. Botones Ver, Editar y Eliminar en la tabla

Archivo: `app/Filament/Resources/Libros/Tables/LibrosTable.php`

Arriba, junto a los otros `use`:

```php
use Filament\Actions\ViewAction;
use Filament\Actions\DeleteAction;
```

Dentro de `->recordActions([`:

```php
->recordActions([
    ViewAction::make(),
    EditAction::make(),
    DeleteAction::make(),
])
```

> `ViewAction` abre una ventana de solo lectura. No necesitas crear ninguna página extra.

### Paso 7. Después de registrar, volver a la lista

Archivo: `app/Filament/Resources/Libros/Pages/CreateLibro.php`

Dentro de la clase:

```php
protected function getRedirectUrl(): string
{
    return $this->getResource()::getUrl('index');
}
```

> Si sigue mostrando el formulario, es que presionaste **Crear y crear otro**. Para quitar ese botón agrega en la misma clase:
> `protected static bool $canCreateAnother = false;`

### Paso 8. Limpiar caché y probar

```bash
php artisan optimize:clear
php artisan serve
```

---

[← Anterior](01-instalacion.md) | [Índice](README.md) | [Siguiente →](03-crud-con-imagen.md)
