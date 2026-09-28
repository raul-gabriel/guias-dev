# Guía CRUD con Laravel + Filament

Probado con Filament 5.9.0.

**Regla de oro del orden (siempre igual):**

1. Comando que crea el modelo y la migración
2. Editar la migración (columnas)
3. Editar el modelo (`$fillable`)
4. `php artisan migrate`
5. Comando que crea el recurso de Filament
6. Editar los archivos de Filament (formulario, tabla, página Create)
7. `php artisan optimize:clear`

---

## 0. Instalación (una sola vez)

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

## 1. CRUD básico (ejemplo: Libro)

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

## 2. CRUD con imagen (ejemplo: Cliente con foto)

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

## 3. CRUD con galería de fotos (ejemplo: Departamento)

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

## 4. CRUD con tabla relacionada (Categoría y Producto, sin foto)

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

## 5. Single Type (un solo registro, ejemplo: Nosotros)

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

## 6. Problemas comunes

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

## 7. Checklist rápido de un CRUD

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
