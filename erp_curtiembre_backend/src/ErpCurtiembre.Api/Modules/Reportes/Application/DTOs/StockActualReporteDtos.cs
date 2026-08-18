namespace ErpCurtiembre.Modules.Reportes.Application.DTOs;

public sealed record StockActualReporteFiltersDto(
    string? Texto = null,
    string? TipoBien = null,
    bool? Activo = null);

public sealed record StockActualReporteDto(
    long InsumoId,
    string CodigoInsumo,
    string Insumo,
    string TipoBien,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    decimal CantidadActual,
    decimal StockMinimo,
    string EstadoStock,
    decimal CostoPromedioActual,
    decimal ValorStock,
    bool Activo,
    DateTime ActualizadoEn);
