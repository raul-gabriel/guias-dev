[← Anterior](04-galeria.md) | [Índice](README.md) | [Siguiente →](06-single-type.md)

# CRUD con tabla relacionada (Categoría y Producto, sin foto)

Una **Categoría** tiene muchos **Productos**. Cada Producto pertenece a una Categoría.
La tabla principal (Categoría) se crea **primero**.

### Paso 1. Crear los dos modelos con migración (en este orden)

```bash
php artisan make:model Categoria -m
php artisan make:model Producto -m
```

### Paso 2. Editar la migración de Categoría

Archivo: `database/migrations/xxxx_create_categorias_table.php`

```php
public function up(): void
{
    Schema::create('categorias', function (Blueprint $table) {
        $table->id();
        $table->string('nombre')->unique();
        $table->text('descripcion')->nullable();
        $table->boolean('activo')->default(true);
        $table->timestamps();
    });
}
```

### Paso 3. Editar la migración de Producto

Archivo: `database/migrations/xxxx_create_productos_table.php`

```php
public function up(): void
{
    Schema::create('productos', function (Blueprint $table) {
        $table->id();
        $table->foreignId('categoria_id')
              ->constrained('categorias')->cascadeOnDelete();
        $table->string('nombre');
        $table->text('descripcion')->nullable();
        $table->decimal('precio', 10, 2)->default(0);
        $table->integer('stock')->default(0);
        $table->boolean('activo')->default(true);
        $table->timestamps();
    });
}
```

> La migración de `categorias` debe tener fecha **anterior** a la de `productos`. Si ejecutaste los comandos en el orden del Paso 1, ya está bien.

### Paso 4. Editar los modelos

Archivo: `app/Models/Categoria.php`

```php
protected $fillable = ['nombre', 'descripcion', 'activo'];

public function productos()
{
    return $this->hasMany(Producto::class);
}
```

Archivo: `app/Models/Producto.php`

```php
protected $fillable = [
    'categoria_id', 'nombre', 'descripcion', 'precio', 'stock', 'activo',
];

public function categoria()
{
    return $this->belongsTo(Categoria::class);
}
```

### Paso 5. Migrar

```bash
php artisan migrate
```

### Paso 6. Crear los recursos de Filament

```bash
php artisan make:filament-resource Categoria --generate
php artisan make:filament-resource Producto --generate
```

```
Title attribute: nombre   (en ambos)
Read-only view page: No
```

### Paso 7. Select de categoría en el formulario de Producto

Archivo: `app/Filament/Resources/Productos/Schemas/ProductoForm.php`

Arriba:

```php
use Filament\Forms\Components\Select;
```

Reemplaza el campo `categoria_id` (Filament lo genera como número) por:

```php
Select::make('categoria_id')
    ->label('Categoría')
    ->relationship('categoria', 'nombre')
    ->searchable()
    ->preload()
    ->required(),
```

### Paso 8. Mostrar el nombre (no el número) en la tabla

Archivo: `app/Filament/Resources/Productos/Tables/ProductosTable.php`

Reemplaza la columna `categoria_id` por:

```php
TextColumn::make('categoria.nombre')
    ->label('Categoría')
    ->sortable()
    ->searchable(),
```

Y las acciones:

```php
->recordActions([
    ViewAction::make(),
    EditAction::make(),
    DeleteAction::make(),
])
```

### Paso 9. Volver a la lista después de registrar

En `Pages/CreateProducto.php` y en `Pages/CreateCategoria.php`:

```php
protected function getRedirectUrl(): string
{
    return $this->getResource()::getUrl('index');
}
```

### Paso 10. Limpiar caché y probar

```bash
php artisan optimize:clear
php artisan serve
```

Primero crea 2 o 3 categorías, luego crea productos y elige la categoría.

> **Cuidado al eliminar:** con `cascadeOnDelete()`, si borras una categoría se borran todos sus productos. Si prefieres conservarlos usa `nullOnDelete()` y deja la columna `nullable()`.

### Si Producto ya existe (sin categoría)

No lo crees de nuevo. En este orden:

**1. Crear el modelo principal y la migración nueva**

```bash
php artisan make:model Categoria -m
php artisan make:migration add_categoria_id_to_productos_table --table=productos
```

**2. Editar la migración de `categorias`** (columnas, igual que el Paso 2).

**3. Editar la migración nueva `add_categoria_id_to_productos_table`**

```php
public function up(): void
{
    Schema::table('productos', function (Blueprint $table) {
        $table->foreignId('categoria_id')->nullable()->after('id')
            ->constrained('categorias')->nullOnDelete();
    });
}

public function down(): void
{
    Schema::table('productos', function (Blueprint $table) {
        $table->dropConstrainedForeignId('categoria_id');
    });
}
```

> La migración de `categorias` debe tener fecha anterior a esta. Si da error de tabla inexistente, renombra el archivo para que su fecha sea posterior.

**4. Editar los modelos**

- `Categoria.php`: `$fillable` y el método `productos()` con `hasMany`.
- `Producto.php`: agrega `'categoria_id'` al `$fillable` y el método `categoria()` con `belongsTo`.

**5. Migrar**

```bash
php artisan migrate
```

**6. Crear el recurso de Categoría**

```bash
php artisan make:filament-resource Categoria --generate
```

**7. Agregar el Select y la columna en Producto** (igual que los pasos 7 y 8 de arriba).

**8. Limpiar caché**

```bash
php artisan optimize:clear
```

---

[← Anterior](04-galeria.md) | [Índice](README.md) | [Siguiente →](06-single-type.md)
