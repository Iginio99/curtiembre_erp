namespace ErpCurtiembre.Modules.Reportes.Application.DTOs;

public sealed record StockBajoReporteDto(
    long InsumoId,
    string CodigoInsumo,
    string Insumo,
    decimal CantidadActual,
    decimal StockMinimo,
    string EstadoStock,
    decimal CostoPromedioActual,
    DateTime ActualizadoEn);
