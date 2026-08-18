using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Inventario.Application.DTOs;

public sealed record RegistrarStockInicialDetalleRequestDto(
    [property: Range(1, long.MaxValue)] long InsumoId,
    [property: Range(typeof(decimal), "0.0001", "999999999999999.9999")] decimal Cantidad,
    [property: Range(typeof(decimal), "0", "999999999999999.9999")] decimal CostoUnitario,
    [property: StringLength(300)] string? Observacion = null);

public sealed record RegistrarStockInicialRequestDto(
    [property: StringLength(100)] string? DocumentoSoporte,
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<RegistrarStockInicialDetalleRequestDto> Detalles);

public sealed record RegistrarEntradaCompraDetalleRequestDto(
    [property: Range(1, long.MaxValue)] long OrdenCompraDetalleId,
    [property: Range(1, long.MaxValue)] long InsumoId,
    [property: Range(typeof(decimal), "0.0001", "999999999999999.9999")] decimal Cantidad,
    [property: Range(typeof(decimal), "0", "999999999999999.9999")] decimal CostoUnitario,
    [property: StringLength(300)] string? Observacion = null);

public sealed record RegistrarEntradaCompraRequestDto(
    [property: Range(1, long.MaxValue)] long OrdenCompraId,
    [property: Required]
    [property: StringLength(100)]
    string DocumentoSoporte,
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<RegistrarEntradaCompraDetalleRequestDto> Detalles);

public sealed record EntradaInventarioDetalleDto(
    long Id,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    decimal Cantidad,
    decimal CostoUnitario,
    decimal CostoTotal,
    decimal StockActual,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    string? Observacion);

public sealed record EntradaInventarioDetailDto(
    long Id,
    string Codigo,
    string TipoEntrada,
    DateTime FechaEntrada,
    string? DocumentoSoporte,
    string? Observacion,
    string Estado,
    long? CreadoPorUsuarioId,
    DateTime CreadoEn,
    IReadOnlyCollection<EntradaInventarioDetalleDto> Detalles);
