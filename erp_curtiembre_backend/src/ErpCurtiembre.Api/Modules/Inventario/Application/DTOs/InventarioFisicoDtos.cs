using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Inventario.Application.DTOs;

public sealed record CrearInventarioFisicoRequestDto(
    [property: Range(2000, 9999)] int PeriodoAnio,
    [property: Range(1, 12)] int PeriodoMes,
    [property: StringLength(500)] string? Observacion);

public sealed record RegistrarConteoInventarioFisicoDetalleRequestDto(
    [property: Range(1, long.MaxValue)] long InsumoId,
    [property: Range(typeof(decimal), "0", "999999999999999.9999")] decimal StockContado,
    [property: StringLength(300)] string? Observacion);

public sealed record RegistrarConteoInventarioFisicoRequestDto(
    [property: MinLength(1)] IReadOnlyCollection<RegistrarConteoInventarioFisicoDetalleRequestDto> Detalles);

public sealed record CerrarInventarioFisicoRequestDto(
    [property: StringLength(500)] string? Observacion = null);

public sealed record InventarioFisicoFiltersDto(
    int? PeriodoAnio = null,
    int? PeriodoMes = null,
    string? Estado = null);

public sealed record InventarioFisicoListItemDto(
    long Id,
    string Codigo,
    DateTime FechaInicio,
    DateTime? FechaCierre,
    int PeriodoAnio,
    int PeriodoMes,
    string Estado,
    long EjecutadoPorUsuarioId,
    string? Observacion,
    int TotalItems,
    int ItemsConDiferencia,
    decimal TotalDiferenciaAbsoluta);

public sealed record InventarioFisicoDetalleConteoDto(
    long Id,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    decimal StockSistema,
    decimal StockContado,
    decimal Diferencia,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    string? Observacion);

public sealed record InventarioFisicoSummaryDto(
    int TotalItems,
    int ItemsConDiferencia,
    int ItemsConAjustePositivo,
    int ItemsConAjusteNegativo,
    decimal TotalDiferenciaAbsoluta);

public sealed record InventarioFisicoDetailDto(
    long Id,
    string Codigo,
    DateTime FechaInicio,
    DateTime? FechaCierre,
    int PeriodoAnio,
    int PeriodoMes,
    string Estado,
    long EjecutadoPorUsuarioId,
    string? Observacion,
    InventarioFisicoSummaryDto Resumen,
    IReadOnlyCollection<InventarioFisicoDetalleConteoDto> Detalles);
