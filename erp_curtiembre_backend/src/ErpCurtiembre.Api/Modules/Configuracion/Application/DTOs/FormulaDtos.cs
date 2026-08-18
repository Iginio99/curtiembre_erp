using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Configuracion.Application.DTOs;

public sealed record CreateFormulaRequestDto(
    [property: Required, StringLength(50)] string Codigo,
    [property: Required, StringLength(150)] string Nombre,
    [property: Required] long ProcesoProductivoId,
    [property: StringLength(500)] string? Descripcion);

public sealed record UpdateFormulaRequestDto(
    [property: Required, StringLength(50)] string Codigo,
    [property: Required, StringLength(150)] string Nombre,
    [property: Required] long ProcesoProductivoId,
    [property: StringLength(500)] string? Descripcion);

public sealed record FormulaFiltersDto(
    string? Texto = null,
    long? ProcesoProductivoId = null,
    bool? Activo = null);

public sealed record FormulaVersionSummaryDto(
    long Id,
    int NumeroVersion,
    DateTime FechaInicioVigencia,
    DateTime? FechaFinVigencia,
    bool Vigente);

public sealed record FormulaListItemDto(
    long Id,
    string Codigo,
    string Nombre,
    long ProcesoProductivoId,
    string ProcesoProductivoCodigo,
    string ProcesoProductivoNombre,
    string? Descripcion,
    bool Activo,
    DateTime CreadoEn,
    FormulaVersionSummaryDto? VersionVigente);

public sealed record FormulaDetailDto(
    long Id,
    string Codigo,
    string Nombre,
    long ProcesoProductivoId,
    string ProcesoProductivoCodigo,
    string ProcesoProductivoNombre,
    string? Descripcion,
    bool Activo,
    DateTime CreadoEn,
    long? CreadoPorUsuarioId,
    FormulaVersionSummaryDto? VersionVigente);

public sealed record CreateFormulaVersionRequestDto(
    [property: Range(1, int.MaxValue)] int NumeroVersion,
    [property: Required] DateTime FechaInicioVigencia,
    DateTime? FechaFinVigencia,
    [property: StringLength(500)] string? Observacion,
    long? ClonarDesdeVersionId);

public sealed record UpdateFormulaVersionRequestDto(
    [property: Required] DateTime FechaInicioVigencia,
    DateTime? FechaFinVigencia,
    [property: StringLength(500)] string? Observacion);

public sealed record FormulaVersionListItemDto(
    long Id,
    long FormulaId,
    string FormulaCodigo,
    string FormulaNombre,
    int NumeroVersion,
    DateTime FechaInicioVigencia,
    DateTime? FechaFinVigencia,
    bool Vigente,
    string? Observacion,
    DateTime CreadoEn,
    long? CreadoPorUsuarioId,
    int DetallesActivos);

public sealed record FormulaDetalleItemDto(
    long Id,
    long FormulaVersionId,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    decimal Porcentaje,
    string? Observacion,
    bool Activo);

public sealed record FormulaVersionDetailDto(
    long Id,
    long FormulaId,
    string FormulaCodigo,
    string FormulaNombre,
    int NumeroVersion,
    DateTime FechaInicioVigencia,
    DateTime? FechaFinVigencia,
    bool Vigente,
    string? Observacion,
    DateTime CreadoEn,
    long? CreadoPorUsuarioId,
    IReadOnlyCollection<FormulaDetalleItemDto> Detalles);

public sealed record CreateFormulaDetalleRequestDto(
    [property: Required] long InsumoId,
    [property: Range(typeof(decimal), "0.0001", "999999.9999")] decimal Porcentaje,
    [property: StringLength(300)] string? Observacion);

public sealed record UpdateFormulaDetalleRequestDto(
    [property: Required] long InsumoId,
    [property: Range(typeof(decimal), "0.0001", "999999.9999")] decimal Porcentaje,
    [property: StringLength(300)] string? Observacion,
    bool Activo);

public sealed record ProcesoProductivoCatalogItemDto(
    long Id,
    string Codigo,
    string Nombre,
    int OrdenSecuencia);
