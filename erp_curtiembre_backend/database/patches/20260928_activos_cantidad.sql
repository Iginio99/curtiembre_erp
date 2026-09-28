SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('finanzas.activo_depreciable', 'cantidad') IS NULL
BEGIN
    ALTER TABLE finanzas.activo_depreciable
        ADD cantidad int NOT NULL
            CONSTRAINT DF_activo_depreciable_cantidad DEFAULT (1);
END;

COMMIT TRANSACTION;
