[← Anterior](03-crud-con-imagen.md) | [Índice](README.md) | [Siguiente →](05-tablas-relacionadas.md)

# CRUD con galería de fotos (ejemplo: Departamento)

Las fotos se guardan en **una sola columna JSON**. Es la forma más simple.

### Paso 1. Crear modelo y migración

```bash
php artisan make:model Departamento -m
```

### Paso 2. Editar la migración

Archivo: `database/migrations/xxxx_create_departamentos_table.php`

```php
public function up(): void
{
    Schema::create('departamentos', function (Blueprint $table) {
        $table->id();
        $table->string('nombre');
        $table->text('descripcion')->nullable();
        $table->string('direccion')->nullable();
        $table->decimal('precio', 10, 2)->default(0);
        $table->integer('habitaciones')->default(1);
        $table->string('foto_principal')->nullable();
        $table->json('galeria')->nullable(); // varias rutas
        $table->boolean('activo')->default(true);
        $table->timestamps();
    });
}
```

### Paso 3. Editar el modelo

Archivo: `app/Models/Departamento.php`

```php
protected $fillable = [
    'nombre', 'descripcion', 'direccion', 'precio',
    'habitaciones', 'foto_principal', 'galeria', 'activo',
];

protected $casts = [
    'galeria' => 'array',
];
```

> El `$casts` es **obligatorio**. Sin él la galería no se guarda bien.

### Paso 4. Migrar y enlazar el storage

```bash
php artisan migrate
php artisan storage:link
```

### Paso 5. Crear el recurso de Filament

```bash
php artisan make:filament-resource Departamento --generate
```

```
Title attribute: nombre
Read-only view page: No
```

### Paso 6. Campos de imagen en el formulario

Archivo: `app/Filament/Resources/Departamentos/Schemas/DepartamentoForm.php`

Arriba:

```php
use Filament\Forms\Components\FileUpload;
```

Reemplaza los campos `foto_principal` y `galeria` por (versión mínima, la más segura):

```php
FileUpload::make('foto_principal')
    ->image()
    ->disk('public')
    ->directory('departamentos'),

FileUpload::make('galeria')
    ->image()
    ->multiple()
    ->disk('public')
    ->directory('departamentos/galeria')
    ->columnSpanFull(),
```

Cuando confirmes que sube bien, puedes agregar a `galeria`:

```php
->reorderable()     // arrastrar para ordenar
->appendFiles()     // agrega sin borrar las anteriores
->maxFiles(10)      // máximo 10 fotos
->maxSize(2048)     // máximo 2 MB por foto
```

### Paso 7. Tabla y acciones

Archivo: `app/Filament/Resources/Departamentos/Tables/DepartamentosTable.php`

Solo con las acciones basta (mostrar la galería en la tabla es opcional):

```php
->recordActions([
    ViewAction::make(),
    EditAction::make(),
    DeleteAction::make(),
])
```

### Paso 8. Volver a la lista después de registrar

Archivo: `app/Filament/Resources/Departamentos/Pages/CreateDepartamento.php`

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

[← Anterior](03-crud-con-imagen.md) | [Índice](README.md) | [Siguiente →](05-tablas-relacionadas.md)
