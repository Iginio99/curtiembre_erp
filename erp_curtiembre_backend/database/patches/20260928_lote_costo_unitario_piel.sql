SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

IF COL_LENGTH('produccion.lote', 'costo_unitario_piel') IS NULL
BEGIN
    ALTER TABLE produccion.lote
        ADD costo_unitario_piel DECIMAL(18,4) NOT NULL
            CONSTRAINT DF_lote_costo_unitario_piel DEFAULT (0);
END;

EXEC(N'
    UPDATE produccion.lote
    SET costo_unitario_piel = CASE
            WHEN cliente_trae_lote = 1 OR cantidad_pieles_inicial = 0 THEN 0
            ELSE ROUND(costo_pieles_total / cantidad_pieles_inicial, 4)
        END,
        costo_pieles_total = CASE
            WHEN cliente_trae_lote = 1 THEN 0
            ELSE costo_pieles_total
        END;
');

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_lote_costo_unitario_piel_no_negativo'
)
BEGIN
    EXEC(N'
        ALTER TABLE produccion.lote WITH CHECK
            ADD CONSTRAINT CK_lote_costo_unitario_piel_no_negativo
            CHECK (costo_unitario_piel >= 0);
    ');
END;

COMMIT TRANSACTION;
