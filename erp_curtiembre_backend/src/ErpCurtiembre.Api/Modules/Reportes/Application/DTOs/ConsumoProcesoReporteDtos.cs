namespace ErpCurtiembre.Modules.Reportes.Application.DTOs;

public sealed record ConsumoProcesoReporteFiltersDto(
    long? OrdenProduccionId = null,
    long? OrdenProcesoId = null,
    DateTime? FechaDesde = null,
    DateTime? FechaHasta = null);

public sealed record ConsumoProcesoReporteDto(
    long? OrdenProduccionId,
    long? OrdenProcesoId,
    int TotalSalidas,
    int TotalItems,
    decimal CantidadConsumidaTotal,
    decimal CostoConsumidoTotal,
    DateTime? PrimeraSalida,
    DateTime? UltimaSalida);
