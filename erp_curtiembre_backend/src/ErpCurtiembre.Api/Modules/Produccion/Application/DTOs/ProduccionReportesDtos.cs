namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

public sealed record OrdenesActivasReporteItemDto(
    long OrdenProduccionId,
    string CodigoOrden,
    string Cliente,
    string CodigoLote,
    string? Responsable,
    DateTime? FechaInicioReal,
    DateTime FechaFinEstimada,
    string Estado);

public sealed record OrdenesPorClienteReporteFiltersDto(
    long? ClienteId = null,
    string? Estado = null,
    DateTime? FechaDesde = null,
    DateTime? FechaHasta = null);

public sealed record OrdenesPorClienteReporteItemDto(
    long OrdenProduccionId,
    string CodigoOrden,
    long ClienteId,
    string Cliente,
    string CodigoLote,
    decimal CantidadPieles,
    DateTime? FechaInicioReal,
    DateTime FechaFinEstimada,
    DateTime? FechaFinReal,
    string Estado);

public sealed record ConsumoPorProcesoReporteFiltersDto(
    long? OrdenProduccionId = null,
    long? OrdenProcesoId = null);

public sealed record ConsumoPorProcesoReporteItemDto(
    long OrdenProduccionId,
    string CodigoOrden,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    decimal CantidadPlanificada,
    decimal CantidadReal,
    decimal CantidadDesviacion,
    decimal? CostoUnitario,
    decimal CostoTotal);

public sealed record MermaReporteFiltersDto(
    long? OrdenProduccionId = null,
    long? OrdenProcesoId = null,
    DateTime? FechaDesde = null,
    DateTime? FechaHasta = null);

public sealed record MermaReporteItemDto(
    long Id,
    long OrdenProduccionId,
    string CodigoOrden,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    decimal CantidadPerdida,
    string? Motivo,
    DateTime RegistradoEn,
    string? Responsable);

public sealed record TiemposProcesoReporteFiltersDto(
    long? OrdenProduccionId = null,
    long? OrdenProcesoId = null,
    string? Estado = null);

public sealed record TiemposProcesoReporteItemDto(
    long OrdenProduccionId,
    string CodigoOrden,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    DateTime? FechaInicio,
    DateTime? FechaFin,
    int? DiasReales,
    string Estado,
    string? Responsable);

public sealed record CostosOrdenReporteFiltersDto(long? OrdenProduccionId = null);

public sealed record CostosOrdenReporteItemDto(
    long OrdenProduccionId,
    string CodigoOrden,
    string Cliente,
    string CodigoLote,
    decimal CantidadPieles,
    decimal CantidadLados,
    decimal CostoMaterialesReal,
    decimal CostoMaterialesPorPiel,
    decimal CostoMaterialesPorLado);

public sealed record CostosProcesoReporteItemDto(
    long OrdenProduccionId,
    string CodigoOrden,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    decimal CostoMaterialesReal);
