SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('produccion.orden_consumo_planificado', 'U') IS NULL
BEGIN
    CREATE TABLE produccion.orden_consumo_planificado (
        id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_orden_consumo_planificado PRIMARY KEY,
        orden_produccion_id bigint NOT NULL,
        orden_proceso_id bigint NOT NULL,
        formula_version_id bigint NOT NULL,
        insumo_id bigint NOT NULL,
        porcentaje decimal(9,4) NOT NULL,
        cantidad_planificada decimal(18,4) NOT NULL,
        creado_en datetime2 NOT NULL CONSTRAINT DF_orden_consumo_planificado_creado_en DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_consumo_planificado_orden FOREIGN KEY (orden_produccion_id) REFERENCES produccion.orden_produccion(id),
        CONSTRAINT FK_consumo_planificado_proceso FOREIGN KEY (orden_proceso_id) REFERENCES produccion.orden_produccion_proceso(id),
        CONSTRAINT FK_consumo_planificado_insumo FOREIGN KEY (insumo_id) REFERENCES inventario.insumo(id)
    );

    CREATE INDEX IX_consumo_planificado_reporte
        ON produccion.orden_consumo_planificado(orden_produccion_id, orden_proceso_id, insumo_id);
END;

COMMIT TRANSACTION;
