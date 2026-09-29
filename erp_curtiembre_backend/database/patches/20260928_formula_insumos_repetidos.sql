SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

IF EXISTS (
    SELECT 1
    FROM sys.key_constraints
    WHERE name = 'UQ_formula_detalle'
      AND parent_object_id = OBJECT_ID('configuracion.formula_detalle')
)
BEGIN
    ALTER TABLE configuracion.formula_detalle
        DROP CONSTRAINT UQ_formula_detalle;
END;

COMMIT TRANSACTION;
