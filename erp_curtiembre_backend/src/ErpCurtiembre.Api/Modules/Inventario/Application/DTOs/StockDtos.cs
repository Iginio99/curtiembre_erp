namespace ErpCurtiembre.Modules.Inventario.Application.DTOs;

public sealed record StockFiltersDto(
    string? Texto = null,
    string? TipoBien = null,
    bool? StockBajo = null,
    bool? Activo = null);

public sealed record StockActualDto(
    long InsumoId,
    string Codigo,
    string Nombre,
    string TipoBien,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    decimal StockMinimo,
    decimal CantidadActual,
    decimal CostoPromedioActual,
    bool Activo,
    bool StockBajo,
    DateTime ActualizadoEn);
