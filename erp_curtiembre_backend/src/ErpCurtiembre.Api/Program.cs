using ErpCurtiembre.Shared.Composition;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using System.Text.Encodings.Web;

var builder = WebApplication.CreateBuilder(args);

// Evita que Windows Event Log convierta un error de aplicacion en otro fallo
// cuando el proceso se ejecuta sin permisos para escribir en el registro.
builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole();
// Conserva advertencias y errores de EF Core, pero evita imprimir en consola
// cada consulta SQL ejecutada correctamente (incluido el ajuste idempotente de esquema).
builder.Logging.AddFilter("Microsoft.EntityFrameworkCore.Database.Command", LogLevel.Warning);

// JSON se entrega como UTF-8. Al no escapar los caracteres Unicode, los
// clientes reciben directamente ñ, tildes y demás texto en español.
builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping);

builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendDevelopment", policy =>
    {
        policy
            .SetIsOriginAllowed(origin =>
            {
                if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                {
                    return false;
                }

                return uri.Host is "localhost" or "127.0.0.1";
            })
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new()
    {
        Title = "ERP Curtiembre API",
        Version = "v1",
        Description = "Documentacion OpenAPI de los endpoints actuales del backend ERP Curtiembre."
    });
});
builder.Services.AddProblemDetails();
builder.Services.AddErpModules(builder.Configuration);

var app = builder.Build();

await using (var scope = app.Services.CreateAsyncScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ConfiguracionDbContext>();
    await db.Database.ExecuteSqlRawAsync("""
        IF OBJECT_ID(N'configuracion.producto', N'U') IS NULL
        BEGIN
            CREATE TABLE configuracion.producto (
                id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                codigo NVARCHAR(50) NOT NULL CONSTRAINT UQ_producto_codigo UNIQUE,
                tipo NVARCHAR(120) NOT NULL,
                nombre NVARCHAR(150) NOT NULL,
                color NVARCHAR(80) NULL,
                activo BIT NOT NULL CONSTRAINT DF_producto_activo DEFAULT 1,
                creado_en DATETIME2 NOT NULL CONSTRAINT DF_producto_creado_en DEFAULT SYSDATETIME()
            );
        END;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_formula_producto' AND parent_object_id = OBJECT_ID(N'configuracion.formula'))
            ALTER TABLE configuracion.formula DROP CONSTRAINT FK_formula_producto;
        IF COL_LENGTH(N'configuracion.formula', N'producto_id') IS NOT NULL
            ALTER TABLE configuracion.formula DROP COLUMN producto_id;
        IF COL_LENGTH(N'configuracion.formula', N'tipo_producto') IS NOT NULL
            ALTER TABLE configuracion.formula DROP COLUMN tipo_producto;
        IF COL_LENGTH(N'configuracion.formula', N'color') IS NOT NULL
            ALTER TABLE configuracion.formula DROP COLUMN color;

        IF OBJECT_ID(N'produccion.orden_producto', N'U') IS NOT NULL
        BEGIN
            IF COL_LENGTH(N'produccion.orden_producto', N'estado_recurtido') IS NULL
                ALTER TABLE produccion.orden_producto ADD estado_recurtido NVARCHAR(30) NOT NULL CONSTRAINT DF_orden_producto_estado_recurtido DEFAULT 'PENDIENTE';
            IF COL_LENGTH(N'produccion.orden_producto', N'inicio_recurtido') IS NULL
                ALTER TABLE produccion.orden_producto ADD inicio_recurtido DATETIME2 NULL;
            IF COL_LENGTH(N'produccion.orden_producto', N'fin_recurtido') IS NULL
                ALTER TABLE produccion.orden_producto ADD fin_recurtido DATETIME2 NULL;
            IF COL_LENGTH(N'produccion.orden_producto', N'estado_acabado') IS NULL
                ALTER TABLE produccion.orden_producto ADD estado_acabado NVARCHAR(30) NOT NULL CONSTRAINT DF_orden_producto_estado_acabado DEFAULT 'PENDIENTE';
            IF COL_LENGTH(N'produccion.orden_producto', N'inicio_acabado') IS NULL
                ALTER TABLE produccion.orden_producto ADD inicio_acabado DATETIME2 NULL;
            IF COL_LENGTH(N'produccion.orden_producto', N'fin_acabado') IS NULL
                ALTER TABLE produccion.orden_producto ADD fin_acabado DATETIME2 NULL;
            IF COL_LENGTH(N'produccion.orden_producto', N'responsable_recurtido_id') IS NULL
            BEGIN
                ALTER TABLE produccion.orden_producto ADD responsable_recurtido_id BIGINT NULL;
                ALTER TABLE produccion.orden_producto ADD CONSTRAINT FK_orden_producto_responsable_recurtido
                    FOREIGN KEY (responsable_recurtido_id) REFERENCES produccion.personal_empresa(id);
            END;
            IF COL_LENGTH(N'produccion.orden_producto', N'responsable_acabado_id') IS NULL
            BEGIN
                ALTER TABLE produccion.orden_producto ADD responsable_acabado_id BIGINT NULL;
                ALTER TABLE produccion.orden_producto ADD CONSTRAINT FK_orden_producto_responsable_acabado
                    FOREIGN KEY (responsable_acabado_id) REFERENCES produccion.personal_empresa(id);
            END;

        END;

        IF OBJECT_ID(N'produccion.orden_producto_terminado', N'U') IS NULL
        BEGIN
            CREATE TABLE produccion.orden_producto_terminado (
                id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                orden_producto_id BIGINT NOT NULL CONSTRAINT UQ_orden_producto_terminado UNIQUE,
                cantidad_pieles DECIMAL(18,2) NOT NULL,
                fecha_ingreso DATETIME2 NOT NULL CONSTRAINT DF_orden_producto_terminado_fecha DEFAULT SYSDATETIME(),
                observacion NVARCHAR(500) NULL,
                CONSTRAINT FK_orden_producto_terminado_producto FOREIGN KEY (orden_producto_id) REFERENCES produccion.orden_producto(id)
            );
        END;

        IF OBJECT_ID(N'produccion.entrega_producto_terminado', N'U') IS NULL
        BEGIN
            CREATE TABLE produccion.entrega_producto_terminado (
                id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                orden_producto_terminado_id BIGINT NOT NULL,
                cantidad_lados DECIMAL(18,4) NOT NULL,
                entregado_en DATETIME2 NOT NULL CONSTRAINT DF_entrega_producto_terminado_fecha DEFAULT SYSDATETIME(),
                observacion NVARCHAR(500) NULL,
                entregado_por_usuario_id BIGINT NOT NULL,
                CONSTRAINT CK_entrega_producto_terminado_cantidad CHECK (cantidad_lados > 0),
                CONSTRAINT FK_entrega_producto_terminado_producto FOREIGN KEY (orden_producto_terminado_id) REFERENCES produccion.orden_producto_terminado(id),
                CONSTRAINT FK_entrega_producto_terminado_usuario FOREIGN KEY (entregado_por_usuario_id) REFERENCES seguridad.usuario(id)
            );
            CREATE INDEX IX_entrega_producto_terminado_producto ON produccion.entrega_producto_terminado(orden_producto_terminado_id, entregado_en DESC);
        END;

        IF OBJECT_ID(N'produccion.entrega_producto_terminado_cabecera', N'U') IS NULL
        BEGIN
            CREATE TABLE produccion.entrega_producto_terminado_cabecera (
                id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                codigo NVARCHAR(30) NULL,
                orden_produccion_id BIGINT NOT NULL,
                entregado_en DATETIME2 NOT NULL CONSTRAINT DF_entrega_pt_cabecera_fecha DEFAULT SYSDATETIME(),
                recibido_por NVARCHAR(150) NULL,
                observacion NVARCHAR(500) NULL,
                entregado_por_usuario_id BIGINT NOT NULL,
                CONSTRAINT FK_entrega_pt_cabecera_orden FOREIGN KEY (orden_produccion_id) REFERENCES produccion.orden_produccion(id),
                CONSTRAINT FK_entrega_pt_cabecera_usuario FOREIGN KEY (entregado_por_usuario_id) REFERENCES seguridad.usuario(id)
            );
        END;
        IF COL_LENGTH(N'produccion.entrega_producto_terminado_cabecera', N'recibido_por') IS NULL
            ALTER TABLE produccion.entrega_producto_terminado_cabecera ADD recibido_por NVARCHAR(150) NULL;
        IF COL_LENGTH(N'produccion.entrega_producto_terminado', N'entrega_cabecera_id') IS NULL
            ALTER TABLE produccion.entrega_producto_terminado ADD entrega_cabecera_id BIGINT NULL;

        /* Se conservan control_calidad y producto_terminado: el flujo de cierre
           de órdenes todavía los consulta y registra resultados en esas tablas. */

        IF OBJECT_ID(N'produccion.solicitud_insumo', N'U') IS NOT NULL
           AND COL_LENGTH(N'produccion.solicitud_insumo', N'orden_producto_id') IS NULL
        BEGIN
            ALTER TABLE produccion.solicitud_insumo ADD orden_producto_id BIGINT NULL;
            ALTER TABLE produccion.solicitud_insumo ADD CONSTRAINT FK_solicitud_insumo_orden_producto
                FOREIGN KEY (orden_producto_id) REFERENCES produccion.orden_producto(id);
        END;

        IF OBJECT_ID(N'produccion.orden_consumo_real', N'U') IS NOT NULL
           AND COL_LENGTH(N'produccion.orden_consumo_real', N'orden_producto_id') IS NULL
        BEGIN
            ALTER TABLE produccion.orden_consumo_real ADD orden_producto_id BIGINT NULL;
            ALTER TABLE produccion.orden_consumo_real ADD CONSTRAINT FK_orden_consumo_real_orden_producto
                FOREIGN KEY (orden_producto_id) REFERENCES produccion.orden_producto(id);
        END;

        IF OBJECT_ID(N'produccion.orden_consumo_planificado', N'U') IS NOT NULL
           AND COL_LENGTH(N'produccion.orden_consumo_planificado', N'orden_producto_id') IS NULL
        BEGIN
            ALTER TABLE produccion.orden_consumo_planificado ADD orden_producto_id BIGINT NULL;
            ALTER TABLE produccion.orden_consumo_planificado ADD CONSTRAINT FK_orden_consumo_planificado_orden_producto
                FOREIGN KEY (orden_producto_id) REFERENCES produccion.orden_producto(id);
        END;

        /* Completa órdenes antiguas que fueron creadas cuando el flujo solo
           tenía Remojo-Pelambre y Curtido. Recurtido y Acabado permanecen
           como etapas contenedoras; su avance real se controla por producto. */
        IF OBJECT_ID(N'produccion.orden_produccion_proceso', N'U') IS NOT NULL
        BEGIN
            INSERT INTO produccion.orden_produccion_proceso
                (orden_produccion_id, proceso_productivo_id, secuencia, estado, creado_en)
            SELECT op.id, pp.id, pp.orden_secuencia, 'PENDIENTE', SYSDATETIME()
            FROM produccion.orden_produccion op
            CROSS JOIN configuracion.proceso_productivo pp
            WHERE pp.codigo IN ('RECURTIDO', 'ACABADO')
              AND NOT EXISTS (
                  SELECT 1
                  FROM produccion.orden_produccion_proceso opp
                  WHERE opp.orden_produccion_id = op.id
                    AND opp.proceso_productivo_id = pp.id
              );

            /* Sincroniza las etapas contenedoras con productos que ya fueron
               iniciados antes de incorporar el avance individual. */
            UPDATE opp
            SET opp.estado = 'EN_PROCESO',
                opp.fecha_inicio = ISNULL(opp.fecha_inicio, estados.inicio)
            FROM produccion.orden_produccion_proceso opp
            INNER JOIN configuracion.proceso_productivo pp
                ON pp.id = opp.proceso_productivo_id AND pp.codigo = 'RECURTIDO'
            CROSS APPLY (
                SELECT MIN(p.inicio_recurtido) AS inicio
                FROM produccion.orden_producto p
                WHERE p.orden_produccion_id = opp.orden_produccion_id
                  AND p.activo = 1
                  AND p.estado_recurtido = 'EN_PROCESO'
            ) estados
            WHERE estados.inicio IS NOT NULL
              AND opp.estado <> 'FINALIZADO';

            UPDATE opp
            SET opp.estado = 'EN_PROCESO',
                opp.fecha_inicio = ISNULL(opp.fecha_inicio, estados.inicio)
            FROM produccion.orden_produccion_proceso opp
            INNER JOIN configuracion.proceso_productivo pp
                ON pp.id = opp.proceso_productivo_id AND pp.codigo = 'ACABADO'
            CROSS APPLY (
                SELECT MIN(p.inicio_acabado) AS inicio
                FROM produccion.orden_producto p
                WHERE p.orden_produccion_id = opp.orden_produccion_id
                  AND p.activo = 1
                  AND p.estado_acabado = 'EN_PROCESO'
            ) estados
            WHERE estados.inicio IS NOT NULL
              AND opp.estado <> 'FINALIZADO';
        END;
        """);

    // El lote anterior agrega entrega_cabecera_id. Ejecutar estas referencias
    // en otro lote evita que SQL Server las compile antes de aplicar el ALTER.
    await db.Database.ExecuteSqlRawAsync("""
        /* Conserva los movimientos que ya existan: los anteriores se convierten
           en operaciones individuales antes de enlazar el detalle con su cabecera. */
        DECLARE @legacyEntregaMap TABLE (detalle_id BIGINT NOT NULL, cabecera_id BIGINT NOT NULL);
        MERGE produccion.entrega_producto_terminado_cabecera AS target
        USING (
            SELECT e.id AS DetalleId, p.orden_produccion_id AS OrdenId,
                   e.entregado_en AS Fecha, e.observacion AS Observacion, e.entregado_por_usuario_id AS UsuarioId
            FROM produccion.entrega_producto_terminado e
            INNER JOIN produccion.orden_producto_terminado opt ON opt.id = e.orden_producto_terminado_id
            INNER JOIN produccion.orden_producto p ON p.id = opt.orden_producto_id
            WHERE e.entrega_cabecera_id IS NULL
        ) AS source ON 1 = 0
        WHEN NOT MATCHED THEN INSERT (orden_produccion_id, entregado_en, observacion, entregado_por_usuario_id)
            VALUES (source.OrdenId, source.Fecha, source.Observacion, source.UsuarioId)
        OUTPUT source.DetalleId, inserted.id INTO @legacyEntregaMap(detalle_id, cabecera_id);
        UPDATE h SET codigo = CONCAT('ENT-', RIGHT(CONCAT('000000', h.id), 6))
        FROM produccion.entrega_producto_terminado_cabecera h WHERE h.codigo IS NULL;
        UPDATE e SET entrega_cabecera_id = m.cabecera_id
        FROM produccion.entrega_producto_terminado e
        INNER JOIN @legacyEntregaMap m ON m.detalle_id = e.id;
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_entrega_pt_detalle_cabecera')
            ALTER TABLE produccion.entrega_producto_terminado WITH CHECK ADD CONSTRAINT FK_entrega_pt_detalle_cabecera
                FOREIGN KEY (entrega_cabecera_id) REFERENCES produccion.entrega_producto_terminado_cabecera(id);
        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_entrega_pt_cabecera_codigo' AND object_id = OBJECT_ID(N'produccion.entrega_producto_terminado_cabecera'))
            CREATE UNIQUE INDEX UX_entrega_pt_cabecera_codigo ON produccion.entrega_producto_terminado_cabecera(codigo) WHERE codigo IS NOT NULL;
        """);

    await db.Database.ExecuteSqlRawAsync("""
        DECLARE @responsableProductoDefault BIGINT = (
            SELECT TOP 1 id FROM produccion.personal_empresa WHERE activo=1 ORDER BY id
        );
        IF @responsableProductoDefault IS NOT NULL
           AND COL_LENGTH(N'produccion.orden_producto', N'responsable_recurtido_id') IS NOT NULL
           AND COL_LENGTH(N'produccion.orden_producto', N'responsable_acabado_id') IS NOT NULL
        BEGIN
            UPDATE produccion.orden_producto
            SET responsable_recurtido_id=ISNULL(responsable_recurtido_id,@responsableProductoDefault),
                responsable_acabado_id=ISNULL(responsable_acabado_id,@responsableProductoDefault)
            WHERE responsable_recurtido_id IS NULL OR responsable_acabado_id IS NULL;
        END;

        UPDATE s
        SET s.orden_producto_id = coincidencia.producto_id
        FROM produccion.solicitud_insumo s
        CROSS APPLY (
            SELECT TOP 1 p.id AS producto_id
            FROM produccion.orden_producto p
            WHERE p.orden_produccion_id = s.orden_produccion_id
              AND s.observacion LIKE p.nombre + ':%'
            ORDER BY LEN(p.nombre) DESC, p.id
        ) coincidencia
        WHERE s.orden_producto_id IS NULL;

        UPDATE r
        SET r.orden_producto_id = coincidencia.orden_producto_id
        FROM produccion.orden_consumo_real r
        CROSS APPLY (
            SELECT MIN(s.orden_producto_id) AS orden_producto_id,
                   COUNT(DISTINCT s.orden_producto_id) AS coincidencias
            FROM produccion.solicitud_insumo s
            INNER JOIN produccion.solicitud_insumo_detalle d
                ON d.solicitud_insumo_id = s.id
            WHERE s.orden_produccion_id = r.orden_produccion_id
              AND s.orden_proceso_id = r.orden_proceso_id
              AND s.orden_producto_id IS NOT NULL
              AND d.insumo_id = r.insumo_id
              AND d.cantidad_solicitada = r.cantidad_consumida
        ) coincidencia
        WHERE r.orden_producto_id IS NULL
          AND coincidencia.coincidencias = 1;

        UPDATE planificado
        SET planificado.orden_producto_id = coincidencia.orden_producto_id
        FROM produccion.orden_consumo_planificado planificado
        CROSS APPLY (
            SELECT MIN(p.id) AS orden_producto_id,
                   COUNT(DISTINCT p.id) AS coincidencias
            FROM produccion.orden_producto p
            INNER JOIN produccion.orden_producto_formula pf
                ON pf.orden_producto_id = p.id
               AND pf.formula_version_id = planificado.formula_version_id
            WHERE p.orden_produccion_id = planificado.orden_produccion_id
              AND p.activo = 1
        ) coincidencia
        WHERE planificado.orden_producto_id IS NULL
          AND coincidencia.coincidencias = 1;
        """);
}

app.UseExceptionHandler();
if (app.Environment.IsDevelopment())
{
    app.UseCors("FrontendDevelopment");
}
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "ERP Curtiembre API v1");
    options.RoutePrefix = "swagger";
    options.DocumentTitle = "ERP Curtiembre API";
});

app.MapGet("/", () => Results.Ok(new
{
    application = "ErpCurtiembre.Api",
    architecture = "Monolito modular con arquitectura hexagonal por modulo",
    modules = ErpModuleCatalog.ModuleNames
}));

app.MapErpModules();

app.Run();

public partial class Program;
