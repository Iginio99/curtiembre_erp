# ERP Curtiembre Backend

Esqueleto base del backend en .NET siguiendo la guía de `arquitectura_backend/07_aplicacion_dotnet`.

## Decisión aplicada

- Un proyecto API principal: `src/ErpCurtiembre.Api`
- Monolito modular interno
- Arquitectura hexagonal por módulo
- Contratos entre módulos mediante puertos en `Application/Ports`
- Migraciones separadas por módulo en `Infrastructure/Persistence/Migrations/<Modulo>`

## Módulos creados

- Seguridad
- Configuracion
- Inventario
- Produccion
- Finanzas
- Alertas
- Reportes
- Auditoria

## Punto de arranque

```powershell
dotnet run --project .\src\ErpCurtiembre.Api
```

## Estado actual

La configuración de base de datos quedó centralizada en `src/ErpCurtiembre.Api/appsettings.json`.

`DatabaseOptions` solo enlaza y valida esa configuración al iniciar la aplicación.

## Siguiente paso recomendado

Definir `DbContext` o repositorios por módulo y empezar por `Seguridad`, `Configuracion` e `Inventario`.
