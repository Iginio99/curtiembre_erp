namespace ErpCurtiembre.Modules.Inventario.Application.DTOs;

public sealed record KardexFiltersDto(
    long? InsumoId = null,
    string? TipoMovimiento = null,
    string? DocumentoTipo = null,
    long? UsuarioResponsableId = null,
    DateTime? FechaDesde = null,
    DateTime? FechaHasta = null);

public sealed record KardexMovimientoDto(
    long Id,
    DateTime FechaMovimiento,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    string TipoMovimiento,
    string? DocumentoTipo,
    long? DocumentoId,
    decimal Entrada,
    decimal Salida,
    decimal StockActual,
    string? EstadoStock,
    decimal CostoUnitario,
    decimal CostoTotal,
    long? UsuarioResponsableId,
    string? UsuarioResponsable,
    string? Observacion);
