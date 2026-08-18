namespace ErpCurtiembre.Modules.Finanzas.Application.DTOs;

public sealed record CalcularPrecioSugeridoRequestDto(decimal MargenPorcentaje);

public sealed record PrecioSugeridoDetailDto(
    long Id,
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    decimal CostoBaseSinIgv,
    decimal MargenPorcentaje,
    decimal PrecioSugeridoSinIgv,
    decimal IgvPorcentaje,
    decimal PrecioSugeridoConIgv,
    DateTime CalculadoEn);

public sealed record CalcularRentabilidadRequestDto(decimal PrecioVenta);

public sealed record RentabilidadOrdenDetailDto(
    long Id,
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    decimal PrecioVenta,
    decimal CostoTotal,
    decimal Utilidad,
    decimal? MargenPorcentaje,
    DateTime CalculadoEn);

public sealed record ReporteCostoOrdenItemDto(
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    string ClienteRazonSocial,
    string EstadoCosto,
    decimal CostoTotal,
    decimal? CostoPorPiel,
    DateTime CalculadoEn);

public sealed record ReporteCostoProcesoItemDto(
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    string ProcesoCodigo,
    string ProcesoNombre,
    decimal CostoInsumos,
    decimal CostoManoObra,
    decimal CostoTotal,
    DateTime CalculadoEn);

public sealed record ReporteCostoClienteItemDto(
    long ClienteId,
    string ClienteRazonSocial,
    int OrdenesCosteadas,
    decimal CostoTotal,
    decimal CostoPromedioOrden);

public sealed record ReporteIndirectoPeriodoItemDto(
    long PeriodoCostoId,
    int Anio,
    int Mes,
    string Estado,
    decimal TotalIndirectos,
    int TotalRegistros);

public sealed record ReporteRentabilidadItemDto(
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    string ClienteRazonSocial,
    decimal PrecioVenta,
    decimal CostoTotal,
    decimal Utilidad,
    decimal? MargenPorcentaje,
    DateTime CalculadoEn);

public sealed record ReportePrecioSugeridoItemDto(
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    string ClienteRazonSocial,
    decimal CostoBaseSinIgv,
    decimal MargenPorcentaje,
    decimal PrecioSugeridoSinIgv,
    decimal IgvPorcentaje,
    decimal PrecioSugeridoConIgv,
    DateTime CalculadoEn);
