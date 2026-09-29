SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @RemojoId bigint = (SELECT TOP 1 id FROM configuracion.proceso_productivo WHERE codigo IN ('REMOJO_PELAMBRE','REMOJO') ORDER BY CASE WHEN codigo='REMOJO_PELAMBRE' THEN 0 ELSE 1 END);
IF @RemojoId IS NULL THROW 51000, 'No existe el proceso base Remojo.', 1;

UPDATE configuracion.proceso_productivo
SET codigo='REMOJO_PELAMBRE', nombre='Remojo y pelambre', orden_secuencia=1, activo=1, es_obligatorio=1
WHERE id=@RemojoId;
UPDATE configuracion.proceso_productivo SET activo=0, orden_secuencia=99 WHERE codigo='PELAMBRE' AND id<>@RemojoId;
UPDATE configuracion.proceso_productivo SET orden_secuencia=2, activo=1, es_obligatorio=1 WHERE codigo='CURTIDO';
UPDATE configuracion.proceso_productivo SET orden_secuencia=3, activo=1, es_obligatorio=1 WHERE codigo='RECURTIDO';
UPDATE configuracion.proceso_productivo SET orden_secuencia=4, activo=1, es_obligatorio=1 WHERE codigo='ACABADO';

IF OBJECT_ID('produccion.orden_producto','U') IS NULL
BEGIN
    CREATE TABLE produccion.orden_producto (
        id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_orden_producto PRIMARY KEY,
        orden_produccion_id bigint NOT NULL,
        codigo nvarchar(60) NOT NULL,
        nombre nvarchar(150) NOT NULL,
        color nvarchar(80) NULL,
        cantidad_pieles decimal(18,2) NOT NULL,
        cantidad_lados decimal(18,2) NOT NULL,
        kilos_recurtido decimal(18,3) NOT NULL CONSTRAINT DF_orden_producto_kilos_recurtido DEFAULT(0),
        kilos_acabado decimal(18,3) NOT NULL CONSTRAINT DF_orden_producto_kilos_acabado DEFAULT(0),
        observacion nvarchar(500) NULL,
        activo bit NOT NULL CONSTRAINT DF_orden_producto_activo DEFAULT(1),
        creado_en datetime2(3) NOT NULL CONSTRAINT DF_orden_producto_creado DEFAULT(sysdatetime()),
        creado_por_usuario_id bigint NULL,
        CONSTRAINT UQ_orden_producto_codigo UNIQUE(orden_produccion_id,codigo),
        CONSTRAINT CK_orden_producto_cantidades CHECK(cantidad_pieles>0 AND cantidad_lados>0 AND kilos_recurtido>=0 AND kilos_acabado>=0),
        CONSTRAINT FK_orden_producto_orden FOREIGN KEY(orden_produccion_id) REFERENCES produccion.orden_produccion(id)
    );
END;

IF OBJECT_ID('produccion.orden_producto_formula','U') IS NULL
BEGIN
    CREATE TABLE produccion.orden_producto_formula (
        id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_orden_producto_formula PRIMARY KEY,
        orden_producto_id bigint NOT NULL,
        proceso_productivo_id bigint NOT NULL,
        formula_version_id bigint NOT NULL,
        kilos_base decimal(18,3) NOT NULL,
        creado_en datetime2(3) NOT NULL CONSTRAINT DF_orden_producto_formula_creado DEFAULT(sysdatetime()),
        creado_por_usuario_id bigint NULL,
        CONSTRAINT UQ_orden_producto_formula UNIQUE(orden_producto_id,proceso_productivo_id),
        CONSTRAINT CK_orden_producto_formula_kilos CHECK(kilos_base>0),
        CONSTRAINT FK_orden_producto_formula_producto FOREIGN KEY(orden_producto_id) REFERENCES produccion.orden_producto(id),
        CONSTRAINT FK_orden_producto_formula_proceso FOREIGN KEY(proceso_productivo_id) REFERENCES configuracion.proceso_productivo(id),
        CONSTRAINT FK_orden_producto_formula_version FOREIGN KEY(formula_version_id) REFERENCES configuracion.formula_version(id)
    );
END;

COMMIT TRANSACTION;
