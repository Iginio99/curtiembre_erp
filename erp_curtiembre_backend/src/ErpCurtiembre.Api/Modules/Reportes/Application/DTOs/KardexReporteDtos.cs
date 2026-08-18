namespace ErpCurtiembre.Modules.Reportes.Application.DTOs;

public sealed record KardexReporteFiltersDto(
    long? InsumoId = null,
    string? TipoMovimiento = null,
    string? DocumentoTipo = null,
    string? Texto = null,
    DateTime? FechaDesde = null,
    DateTime? FechaHasta = null);

public sealed record KardexReporteDto(
    long Id,
    DateTime FechaMovimiento,
    string CodigoInsumo,
    string Insumo,
    string TipoMovimiento,
    string? DocumentoTipo,
    long? DocumentoId,
    decimal Entrada,
    decimal Salida,
    decimal StockActual,
    string? EstadoStock,
    decimal CostoUnitario,
    decimal CostoTotal,
    string? UsuarioResponsable);
