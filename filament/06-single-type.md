[← Anterior](05-tablas-relacionadas.md) | [Índice](README.md) | [Siguiente →](07-problemas-comunes.md)

# Single Type (un solo registro, ejemplo: Nosotros)

Equivale al **Single Type** de Strapi: no hay lista, solo un formulario que se edita. En Filament se hace con un Resource limitado a **una sola fila**: al entrar al menú abre directo el formulario.

Sirve para: Nosotros, Inicio, Contacto, Configuración, etc.

### Paso 1. Crear modelo y migración

```bash
php artisan make:model Nosotros -m
```

### Paso 2. Editar la migración

Archivo: `database/migrations/xxxx_create_nosotros_table.php`

Todo va `nullable()`, porque el registro se crea vacío la primera vez. El nombre de la tabla debe ser `nosotros`.

```php
public function up(): void
{
    Schema::create('nosotros', function (Blueprint $table) {
        $table->id();
        $table->string('foto')->nullable();
        $table->text('sobre_nosotros')->nullable();
        $table->text('mision')->nullable();
        $table->text('vision')->nullable();
        $table->json('logos')->nullable();
        $table->string('imagen_experiencia')->nullable();
        $table->string('meta_title')->nullable();
        $table->text('meta_description')->nullable();
        $table->string('meta_keywords')->nullable();
        $table->timestamps();
    });
}
```

### Paso 3. Editar el modelo

Archivo: `app/Models/Nosotros.php`

```php
protected $table = 'nosotros';

protected $fillable = [
    'foto', 'sobre_nosotros', 'mision', 'vision', 'logos',
    'imagen_experiencia', 'meta_title', 'meta_description', 'meta_keywords',
];

protected $casts = [
    'logos' => 'array',
];
```

### Paso 4. Migrar y enlazar el storage

```bash
php artisan migrate
php artisan storage:link
```

### Paso 5. Crear el recurso de Filament

```bash
php artisan make:filament-resource Nosotros --generate
```

```
Title attribute: sobre_nosotros
Read-only view page: No
```

> La carpeta puede llamarse `Nosotros` o `Nosotroses`, según cómo pluralice Filament. Usa la que se creó en `app/Filament/Resources/`.

### Paso 6. Formulario con imágenes y textos

Archivo: `app/Filament/Resources/Nosotros/Schemas/NosotrosForm.php`

Arriba:

```php
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
```

Deja los campos así:

```php
FileUpload::make('foto')
    ->image()->disk('public')->directory('nosotros')
    ->required(),

Textarea::make('sobre_nosotros')->rows(5)->required()->columnSpanFull(),
Textarea::make('mision')->rows(4)->required()->columnSpanFull(),
Textarea::make('vision')->rows(4)->required()->columnSpanFull(),

FileUpload::make('logos')
    ->image()->multiple()->disk('public')->directory('nosotros/logos')
    ->columnSpanFull(),

FileUpload::make('imagen_experiencia')
    ->image()->disk('public')->directory('nosotros')
    ->required(),

TextInput::make('meta_title'),
Textarea::make('meta_description')->columnSpanFull(),
TextInput::make('meta_keywords'),
```

### Paso 7. Que el menú abra directo el formulario

Archivo: `app/Filament/Resources/Nosotros/Pages/ListNosotros.php`

Reemplaza todo por:

```php
<?php

namespace App\Filament\Resources\Nosotros\Pages;

use App\Filament\Resources\Nosotros\NosotrosResource;
use App\Models\Nosotros;
use Filament\Resources\Pages\ListRecords;

class ListNosotros extends ListRecords
{
    protected static string $resource = NosotrosResource::class;

    public function mount(): void
    {
        $registro = Nosotros::firstOrCreate([]);

        $this->redirect(NosotrosResource::getUrl('edit', ['record' => $registro]));
    }
}
```

Al hacer clic en **Nosotros** en el menú, crea el registro la primera vez y siempre abre el mismo.

### Paso 8. Quitar el botón Eliminar de la página de edición

Archivo: `app/Filament/Resources/Nosotros/Pages/EditNosotros.php`

Dentro de la clase:

```php
protected function getHeaderActions(): array
{
    return [];
}
```

### Paso 9. Bloquear la creación de más registros

Archivo: `app/Filament/Resources/Nosotros/NosotrosResource.php`

Dentro de la clase:

```php
public static function canCreate(): bool
{
    return false;
}
```

### Paso 10. Limpiar caché y probar

```bash
php artisan optimize:clear
php artisan serve
```

### Leer los datos en tu web

```php
$nosotros = \App\Models\Nosotros::first();
```

Ese patrón sirve para cualquier Single Type: solo cambias el nombre y los campos.

### Equivalencias con Strapi

| Strapi | Filament |
|---|---|
| Collection Type (lista de registros) | Resource normal (secciones 1 a 4) |
| Single Type (un solo registro) | Resource limitado a una fila (esta sección) |

---

[← Anterior](05-tablas-relacionadas.md) | [Índice](README.md) | [Siguiente →](07-problemas-comunes.md)
