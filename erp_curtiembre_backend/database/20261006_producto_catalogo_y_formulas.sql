/* Catálogo de productos para Recurtido y Acabado. SQL Server.
   Es idempotente para poder recuperarse de una ejecución parcial. */
IF OBJECT_ID(N'configuracion.producto', N'U') IS NULL
BEGIN
    CREATE TABLE configuracion.producto (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        codigo NVARCHAR(50) NOT NULL,
        tipo NVARCHAR(120) NOT NULL,
        nombre NVARCHAR(150) NOT NULL,
        color NVARCHAR(80) NULL,
        activo BIT NOT NULL CONSTRAINT DF_producto_activo DEFAULT 1,
        creado_en DATETIME2 NOT NULL CONSTRAINT DF_producto_creado_en DEFAULT SYSDATETIME(),
        CONSTRAINT UQ_producto_codigo UNIQUE (codigo)
    );
END;

IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_formula_producto'
      AND parent_object_id = OBJECT_ID(N'configuracion.formula')
)
BEGIN
    ALTER TABLE configuracion.formula
        DROP CONSTRAINT FK_formula_producto;
END;

IF COL_LENGTH(N'configuracion.formula', N'producto_id') IS NOT NULL
BEGIN
    ALTER TABLE configuracion.formula DROP COLUMN producto_id;
END;

IF COL_LENGTH(N'configuracion.formula', N'tipo_producto') IS NOT NULL
BEGIN
    ALTER TABLE configuracion.formula DROP COLUMN tipo_producto;
END;

IF COL_LENGTH(N'configuracion.formula', N'color') IS NOT NULL
BEGIN
    ALTER TABLE configuracion.formula DROP COLUMN color;
END;

/* Las fórmulas son independientes del catálogo de productos. */
