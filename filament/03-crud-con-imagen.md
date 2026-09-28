[← Anterior](02-crud-basico.md) | [Índice](README.md) | [Siguiente →](04-galeria.md)

# CRUD con imagen (ejemplo: Cliente con foto)

### Paso 1. Crear modelo y migración

```bash
php artisan make:model Cliente -m
```

### Paso 2. Editar la migración

Archivo: `database/migrations/xxxx_create_clientes_table.php`

```php
public function up(): void
{
    Schema::create('clientes', function (Blueprint $table) {
        $table->id();
        $table->string('nombre');
        $table->string('apellido');
        $table->string('dni', 8)->nullable()->unique();
        $table->string('telefono')->nullable();
        $table->string('email')->nullable();
        $table->string('foto')->nullable(); // guarda solo la ruta
        $table->boolean('activo')->default(true);
        $table->timestamps();
    });
}
```

### Paso 3. Editar el modelo

Archivo: `app/Models/Cliente.php`

```php
protected $fillable = [
    'nombre', 'apellido', 'dni', 'telefono', 'email', 'foto', 'activo',
];
```

### Paso 4. Migrar y enlazar el storage

```bash
php artisan migrate
php artisan storage:link
```

> `storage:link` es **obligatorio**. Sin él las imágenes se suben pero no se ven. Si dice que el enlace ya existe, está bien.

### Paso 5. Crear el recurso de Filament

```bash
php artisan make:filament-resource Cliente --generate
```

```
Title attribute: nombre
Read-only view page: No
```

### Paso 6. Campo de foto en el formulario

Archivo: `app/Filament/Resources/Clientes/Schemas/ClienteForm.php`

Arriba:

```php
use Filament\Forms\Components\FileUpload;
```

Reemplaza el campo `foto` (Filament lo genera como TextInput) por:

```php
FileUpload::make('foto')
    ->label('Foto')
    ->image()
    ->disk('public')
    ->directory('clientes')
    ->maxSize(2048),
```

### Paso 7. Mostrar la foto en la tabla

Archivo: `app/Filament/Resources/Clientes/Tables/ClientesTable.php`

Arriba:

```php
use Filament\Tables\Columns\ImageColumn;
use Filament\Actions\ViewAction;
use Filament\Actions\DeleteAction;
```

Reemplaza la columna `foto` por:

```php
ImageColumn::make('foto')
    ->disk('public')
    ->circular()
    ->size(60),
```

Y las acciones:

```php
->recordActions([
    ViewAction::make(),
    EditAction::make(),
    DeleteAction::make(),
])
```

### Paso 8. Volver a la lista después de registrar

Archivo: `app/Filament/Resources/Clientes/Pages/CreateCliente.php`

```php
protected function getRedirectUrl(): string
{
    return $this->getResource()::getUrl('index');
}
```

### Paso 9. Limpiar caché y probar

```bash
php artisan optimize:clear
php artisan serve
```

---

[← Anterior](02-crud-basico.md) | [Índice](README.md) | [Siguiente →](04-galeria.md)
