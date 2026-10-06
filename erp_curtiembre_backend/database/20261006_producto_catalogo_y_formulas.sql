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

IF COL_LENGTH(N'configuracion.formula', N'producto_id') IS NULL
BEGIN
    ALTER TABLE configuracion.formula ADD producto_id BIGINT NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_formula_producto'
      AND parent_object_id = OBJECT_ID(N'configuracion.formula')
)
BEGIN
    ALTER TABLE configuracion.formula
        ADD CONSTRAINT FK_formula_producto
        FOREIGN KEY (producto_id) REFERENCES configuracion.producto(id);
END;

/* Las fórmulas históricas de Remojo/Pelambre y Curtido no manejan producto. */
UPDATE f SET tipo_producto = NULL, color = NULL, producto_id = NULL
FROM configuracion.formula f
INNER JOIN configuracion.proceso_productivo pp ON pp.id = f.proceso_productivo_id
WHERE pp.codigo IN ('REMOJO_PELAMBRE', 'CURTIDO');

/* Antes de exigir producto en Recurtido/Acabado, crea los productos y asigna
   configuracion.formula.producto_id a las fórmulas existentes correspondientes. */
