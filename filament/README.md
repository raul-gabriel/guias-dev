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

## Índice

1. [Instalación (una sola vez)](01-instalacion.md)
2. [CRUD básico (ejemplo: Libro)](02-crud-basico.md)
3. [CRUD con imagen (ejemplo: Cliente con foto)](03-crud-con-imagen.md)
4. [CRUD con galería de fotos (ejemplo: Departamento)](04-galeria.md)
5. [CRUD con tabla relacionada (Categoría y Producto, sin foto)](05-tablas-relacionadas.md)
6. [Single Type (un solo registro, ejemplo: Nosotros)](06-single-type.md)
7. [Problemas comunes](07-problemas-comunes.md)
8. [Checklist rápido de un CRUD](08-checklist.md)
