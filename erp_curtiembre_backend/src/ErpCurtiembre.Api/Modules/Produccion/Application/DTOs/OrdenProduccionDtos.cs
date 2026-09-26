using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

public sealed record PersonalEmpresaDto(long Id, string Nombre, string Cargo, bool Activo);

public sealed record CreatePersonalEmpresaDto(
    [property: Required, StringLength(150)] string Nombre,
    [property: Required, StringLength(100)] string Cargo);

public sealed record CreateOrdenProduccionRequestDto(
    [property: Range(1, long.MaxValue)] long LoteId,
    [property: Range(1, long.MaxValue)] long ClienteId,
    [property: Range(typeof(decimal), "0.0001", "999999999999999.9999")] decimal CantidadPieles,
    DateTime? FechaInicioPlanificada,
    DateTime FechaFinEstimada,
    [property: Required, StringLength(150)] string ResponsableNombre,
    [property: Required, StringLength(100)] string ResponsableCargo,
    [property: StringLength(500)] string? Observacion);

public sealed record StartOrdenProduccionRequestDto(
    [property: Required, StringLength(150)] string ResponsableNombre,
    [property: Required, StringLength(100)] string ResponsableCargo,
    [property: Range(typeof(decimal), "0.01", "999999999999999.99")] decimal PesoBaseKg,
    DateTime FechaFinEstimada,
    [property: StringLength(500)] string? Observacion);

public sealed record CancelOrdenProduccionRequestDto(
    [property: Required, StringLength(500)] string Motivo);

public sealed record OrdenProduccionFiltersDto(
    string? Texto = null,
    long? ClienteId = null,
    long? LoteId = null,
    string? Estado = null);

public sealed record OrdenProduccionListItemDto(
    long Id,
    string Codigo,
    long LoteId,
    string LoteCodigo,
    long ClienteId,
    string ClienteRazonSocial,
    decimal CantidadPieles,
    DateTime? FechaInicioPlanificada,
    DateTime? FechaInicioReal,
    DateTime FechaFinEstimada,
    DateTime? FechaFinReal,
    long? ResponsableUsuarioId,
    string? ResponsableNombre,
    string? ResponsableCargo,
    string Estado,
    string? Observacion,
    int ProcesosTotales,
    int ProcesosFinalizados,
    DateTime CreadoEn);

public sealed record OrdenProduccionDetailDto(
    long Id,
    string Codigo,
    long LoteId,
    string LoteCodigo,
    long ClienteId,
    string ClienteRazonSocial,
    decimal CantidadPieles,
    DateTime? FechaInicioPlanificada,
    DateTime? FechaInicioReal,
    DateTime FechaFinEstimada,
    DateTime? FechaFinReal,
    long? ResponsableUsuarioId,
    string? ResponsableNombre,
    string? ResponsableCargo,
    string Estado,
    string? MotivoAnulacion,
    string? Observacion,
    int ProcesosTotales,
    int ProcesosFinalizados,
    DateTime CreadoEn,
    long? CreadoPorUsuarioId,
    DateTime? ActualizadoEn,
    long? ActualizadoPorUsuarioId);

public sealed record OrdenProcesoListItemDto(
    long Id,
    long OrdenProduccionId,
    long ProcesoProductivoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    int Secuencia,
    long? ResponsableUsuarioId,
    string? ResponsableNombre,
    string? ResponsableCargo,
    decimal? PesoBaseKg,
    DateTime? FechaFinEstimada,
    DateTime? FechaInicio,
    DateTime? FechaFin,
    int? DiasReales,
    string Estado,
    string? Observacion);

public sealed record StartOrdenProcesoRequestDto(
    [property: Required, StringLength(150)] string ResponsableNombre,
    [property: Required, StringLength(100)] string ResponsableCargo,
    [property: Range(typeof(decimal), "0.01", "999999999999999.99")] decimal PesoBaseKg,
    DateTime FechaFinEstimada,
    [property: StringLength(800)] string? Observacion);

public sealed record FinishOrdenProcesoRequestDto(
    [property: StringLength(800)] string? Observacion);

public sealed record UpdateOrdenProcesoObservacionRequestDto(
    [property: StringLength(800)] string? Observacion);

public sealed record UpdateResponsableRequestDto(
    [property: Range(1, long.MaxValue)] long ResponsableUsuarioId);
