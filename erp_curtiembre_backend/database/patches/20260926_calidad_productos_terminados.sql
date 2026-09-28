SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('produccion.control_calidad', 'cantidad_lados_a') IS NULL
    ALTER TABLE produccion.control_calidad ADD cantidad_lados_a decimal(18,2) NOT NULL CONSTRAINT DF_control_calidad_lados_a DEFAULT (0);
IF COL_LENGTH('produccion.control_calidad', 'cantidad_lados_b') IS NULL
    ALTER TABLE produccion.control_calidad ADD cantidad_lados_b decimal(18,2) NOT NULL CONSTRAINT DF_control_calidad_lados_b DEFAULT (0);
IF COL_LENGTH('produccion.control_calidad', 'cantidad_lados_c') IS NULL
    ALTER TABLE produccion.control_calidad ADD cantidad_lados_c decimal(18,2) NOT NULL CONSTRAINT DF_control_calidad_lados_c DEFAULT (0);
IF COL_LENGTH('produccion.control_calidad', 'cantidad_lados_merma') IS NULL
    ALTER TABLE produccion.control_calidad ADD cantidad_lados_merma decimal(18,2) NOT NULL CONSTRAINT DF_control_calidad_lados_merma DEFAULT (0);

IF COL_LENGTH('produccion.producto_terminado', 'cantidad_lados_a') IS NULL
    ALTER TABLE produccion.producto_terminado ADD cantidad_lados_a decimal(18,2) NOT NULL CONSTRAINT DF_producto_terminado_lados_a DEFAULT (0);
IF COL_LENGTH('produccion.producto_terminado', 'cantidad_lados_b') IS NULL
    ALTER TABLE produccion.producto_terminado ADD cantidad_lados_b decimal(18,2) NOT NULL CONSTRAINT DF_producto_terminado_lados_b DEFAULT (0);
IF COL_LENGTH('produccion.producto_terminado', 'cantidad_lados_c') IS NULL
    ALTER TABLE produccion.producto_terminado ADD cantidad_lados_c decimal(18,2) NOT NULL CONSTRAINT DF_producto_terminado_lados_c DEFAULT (0);
IF COL_LENGTH('produccion.producto_terminado', 'cantidad_lados_merma') IS NULL
    ALTER TABLE produccion.producto_terminado ADD cantidad_lados_merma decimal(18,2) NOT NULL CONSTRAINT DF_producto_terminado_lados_merma DEFAULT (0);
-- Una piel terminada produce dos lados. La formula anterior dividia entre dos.
IF EXISTS (
    SELECT 1
    FROM sys.computed_columns
    WHERE object_id = OBJECT_ID('produccion.producto_terminado')
      AND name = 'cantidad_lados_calculada'
      AND definition NOT LIKE '%*%(2.0)%'
)
BEGIN
    ALTER TABLE produccion.producto_terminado DROP COLUMN cantidad_lados_calculada;
    ALTER TABLE produccion.producto_terminado
        ADD cantidad_lados_calculada AS CONVERT(decimal(18,4), cantidad_pieles_buenas * (2.0));
END;

COMMIT TRANSACTION;
