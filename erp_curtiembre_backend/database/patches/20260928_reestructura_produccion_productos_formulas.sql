SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('configuracion.formula', 'U') IS NULL
BEGIN
    CREATE TABLE configuracion.formula (
        id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_formula PRIMARY KEY,
        codigo nvarchar(50) NOT NULL,
        nombre nvarchar(150) NOT NULL,
        proceso_productivo_id bigint NOT NULL,
        tipo_producto nvarchar(120) NULL,
        color nvarchar(80) NULL,
        descripcion nvarchar(500) NULL,
        activo bit NOT NULL CONSTRAINT DF_formula_activo DEFAULT (1),
        creado_en datetime2(3) NOT NULL CONSTRAINT DF_formula_creado DEFAULT (sysdatetime()),
        creado_por_usuario_id bigint NULL,
        CONSTRAINT UQ_formula_codigo UNIQUE (codigo),
        CONSTRAINT FK_formula_proceso FOREIGN KEY (proceso_productivo_id) REFERENCES configuracion.proceso_productivo(id)
    );
END;

IF COL_LENGTH('configuracion.formula', 'tipo_producto') IS NULL
    ALTER TABLE configuracion.formula ADD tipo_producto nvarchar(120) NULL;
IF COL_LENGTH('configuracion.formula', 'color') IS NULL
    ALTER TABLE configuracion.formula ADD color nvarchar(80) NULL;

IF OBJECT_ID('configuracion.formula_version', 'U') IS NULL
BEGIN
    CREATE TABLE configuracion.formula_version (
        id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_formula_version PRIMARY KEY,
        formula_id bigint NOT NULL,
        numero_version int NOT NULL,
        fecha_inicio_vigencia datetime2(3) NOT NULL,
        fecha_fin_vigencia datetime2(3) NULL,
        vigente bit NOT NULL CONSTRAINT DF_formula_version_vigente DEFAULT (0),
        observacion nvarchar(500) NULL,
        creado_en datetime2(3) NOT NULL CONSTRAINT DF_formula_version_creado DEFAULT (sysdatetime()),
        creado_por_usuario_id bigint NULL,
        CONSTRAINT UQ_formula_version UNIQUE (formula_id, numero_version),
        CONSTRAINT FK_formula_version_formula FOREIGN KEY (formula_id) REFERENCES configuracion.formula(id)
    );
END;

IF OBJECT_ID('configuracion.formula_detalle', 'U') IS NULL
BEGIN
    CREATE TABLE configuracion.formula_detalle (
        id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_formula_detalle PRIMARY KEY,
        formula_version_id bigint NOT NULL,
        insumo_id bigint NOT NULL,
        porcentaje decimal(9,4) NOT NULL,
        observacion nvarchar(300) NULL,
        activo bit NOT NULL CONSTRAINT DF_formula_detalle_activo DEFAULT (1),
        CONSTRAINT UQ_formula_detalle UNIQUE (formula_version_id, insumo_id),
        CONSTRAINT FK_formula_detalle_version FOREIGN KEY (formula_version_id) REFERENCES configuracion.formula_version(id),
        CONSTRAINT FK_formula_detalle_insumo FOREIGN KEY (insumo_id) REFERENCES inventario.insumo(id)
    );
END;

-- Se conservan los procesos históricos; las nuevas órdenes trabajan solo cuatro etapas.
UPDATE configuracion.proceso_productivo SET orden_secuencia = 99, activo = 0 WHERE id = 2;
UPDATE configuracion.proceso_productivo SET orden_secuencia = 102 WHERE id = 3;
UPDATE configuracion.proceso_productivo SET orden_secuencia = 103 WHERE id = 4;
UPDATE configuracion.proceso_productivo SET orden_secuencia = 104 WHERE id = 5;
UPDATE configuracion.proceso_productivo
SET codigo = 'REMOJO_PELAMBRE', nombre = 'Remojo y pelambre', orden_secuencia = 1, activo = 1
WHERE id = 1;
UPDATE configuracion.proceso_productivo SET orden_secuencia = 2 WHERE id = 3;
UPDATE configuracion.proceso_productivo SET orden_secuencia = 3 WHERE id = 4;
UPDATE configuracion.proceso_productivo SET orden_secuencia = 4 WHERE id = 5;

IF OBJECT_ID('produccion.orden_producto', 'U') IS NULL
BEGIN
    CREATE TABLE produccion.orden_producto (
        id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_orden_producto PRIMARY KEY,
        orden_produccion_id bigint NOT NULL,
        codigo nvarchar(60) NOT NULL,
        nombre nvarchar(150) NOT NULL,
        color nvarchar(80) NULL,
        cantidad_pieles decimal(18,2) NOT NULL,
        cantidad_lados decimal(18,2) NOT NULL,
        kilos_recurtido decimal(18,3) NOT NULL CONSTRAINT DF_orden_producto_kilos_recurtido DEFAULT (0),
        kilos_acabado decimal(18,3) NOT NULL CONSTRAINT DF_orden_producto_kilos_acabado DEFAULT (0),
        observacion nvarchar(500) NULL,
        activo bit NOT NULL CONSTRAINT DF_orden_producto_activo DEFAULT (1),
        creado_en datetime2(3) NOT NULL CONSTRAINT DF_orden_producto_creado DEFAULT (sysdatetime()),
        creado_por_usuario_id bigint NULL,
        CONSTRAINT UQ_orden_producto_codigo UNIQUE (orden_produccion_id, codigo),
        CONSTRAINT CK_orden_producto_cantidades CHECK (cantidad_pieles > 0 AND cantidad_lados > 0 AND kilos_recurtido >= 0 AND kilos_acabado >= 0),
        CONSTRAINT FK_orden_producto_orden FOREIGN KEY (orden_produccion_id) REFERENCES produccion.orden_produccion(id)
    );
END;

IF OBJECT_ID('produccion.orden_producto_formula', 'U') IS NULL
BEGIN
    CREATE TABLE produccion.orden_producto_formula (
        id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_orden_producto_formula PRIMARY KEY,
        orden_producto_id bigint NOT NULL,
        proceso_productivo_id bigint NOT NULL,
        formula_version_id bigint NOT NULL,
        kilos_base decimal(18,3) NOT NULL,
        creado_en datetime2(3) NOT NULL CONSTRAINT DF_orden_producto_formula_creado DEFAULT (sysdatetime()),
        creado_por_usuario_id bigint NULL,
        CONSTRAINT UQ_orden_producto_formula UNIQUE (orden_producto_id, proceso_productivo_id),
        CONSTRAINT CK_orden_producto_formula_kilos CHECK (kilos_base > 0),
        CONSTRAINT FK_orden_producto_formula_producto FOREIGN KEY (orden_producto_id) REFERENCES produccion.orden_producto(id),
        CONSTRAINT FK_orden_producto_formula_proceso FOREIGN KEY (proceso_productivo_id) REFERENCES configuracion.proceso_productivo(id),
        CONSTRAINT FK_orden_producto_formula_version FOREIGN KEY (formula_version_id) REFERENCES configuracion.formula_version(id)
    );
END;

IF COL_LENGTH('produccion.orden_consumo_planificado', 'orden_producto_id') IS NULL
BEGIN
    ALTER TABLE produccion.orden_consumo_planificado ADD orden_producto_id bigint NULL;
    ALTER TABLE produccion.orden_consumo_planificado ADD CONSTRAINT FK_consumo_planificado_producto
        FOREIGN KEY (orden_producto_id) REFERENCES produccion.orden_producto(id);
END;

IF COL_LENGTH('produccion.orden_consumo_real', 'orden_producto_id') IS NULL
BEGIN
    ALTER TABLE produccion.orden_consumo_real ADD orden_producto_id bigint NULL;
    ALTER TABLE produccion.orden_consumo_real ADD CONSTRAINT FK_consumo_real_producto
        FOREIGN KEY (orden_producto_id) REFERENCES produccion.orden_producto(id);
END;

COMMIT TRANSACTION;
