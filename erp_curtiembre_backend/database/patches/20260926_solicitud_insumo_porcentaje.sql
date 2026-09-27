SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('produccion.solicitud_insumo_detalle', 'porcentaje') IS NULL
BEGIN
    ALTER TABLE produccion.solicitud_insumo_detalle
        ADD porcentaje decimal(9,4) NULL;
END;

COMMIT TRANSACTION;
