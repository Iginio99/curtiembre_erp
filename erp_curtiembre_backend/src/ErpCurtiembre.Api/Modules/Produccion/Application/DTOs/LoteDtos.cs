using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

public sealed record CreateLoteRequestDto(
    [property: Range(1, long.MaxValue)] long ClienteId,
    [property: Range(1, long.MaxValue)] long TipoPielId,
    DateTime FechaIngreso,
    [property: Range(typeof(decimal), "0.0001", "999999999999999.9999")] decimal CantidadPielesInicial,
    bool ClienteTraeLote,
    [property: Range(typeof(decimal), "0", "999999999999999.99")] decimal CostoPielesTotal,
    [property: StringLength(500)] string? Observacion);

public sealed record UpdateLoteRequestDto(
    [property: Range(1, long.MaxValue)] long ClienteId,
    [property: Range(1, long.MaxValue)] long TipoPielId,
    DateTime FechaIngreso,
    [property: Range(typeof(decimal), "0.0001", "999999999999999.9999")] decimal CantidadPielesInicial,
    bool ClienteTraeLote,
    [property: Range(typeof(decimal), "0", "999999999999999.99")] decimal CostoPielesTotal,
    [property: StringLength(500)] string? Observacion);

public sealed record LoteFiltersDto(
    string? Texto = null,
    long? ClienteId = null,
    long? TipoPielId = null,
    string? Estado = null);

public sealed record LoteListItemDto(
    long Id,
    string Codigo,
    long ClienteId,
    string ClienteRazonSocial,
    long TipoPielId,
    string TipoPielCodigo,
    string TipoPielNombre,
    DateTime FechaIngreso,
    decimal CantidadPielesInicial,
    decimal CantidadPielesUtilizada,
    decimal CantidadPielesDisponible,
    decimal CantidadLadosCalculada,
    bool ClienteTraeLote,
    decimal CostoPielesTotal,
    string Estado,
    string? Observacion,
    DateTime CreadoEn,
    long? CreadoPorUsuarioId);

public sealed record LoteDetailDto(
    long Id,
    string Codigo,
    long ClienteId,
    string ClienteRazonSocial,
    long TipoPielId,
    string TipoPielCodigo,
    string TipoPielNombre,
    DateTime FechaIngreso,
    decimal CantidadPielesInicial,
    decimal CantidadPielesUtilizada,
    decimal CantidadPielesDisponible,
    decimal CantidadLadosCalculada,
    bool ClienteTraeLote,
    decimal CostoPielesTotal,
    string Estado,
    string? Observacion,
    DateTime CreadoEn,
    long? CreadoPorUsuarioId);

public sealed record LoteDisponibilidadDto(
    long Id,
    string Codigo,
    long ClienteId,
    string ClienteRazonSocial,
    decimal CantidadPielesInicial,
    decimal CantidadPielesUtilizada,
    decimal CantidadPielesDisponible,
    decimal CantidadLadosCalculada,
    string Estado);
