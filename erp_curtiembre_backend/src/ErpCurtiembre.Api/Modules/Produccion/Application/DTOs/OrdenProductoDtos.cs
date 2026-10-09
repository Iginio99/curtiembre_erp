using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

public sealed record ProductoProduccionOptionDto(long Id, string Codigo, string Nombre, string Tipo, string? Color);

public sealed record OrdenProductoFormulaRequestDto(
    [property: Range(1, long.MaxValue)] long ProcesoProductivoId,
    [property: Range(1, long.MaxValue)] long FormulaVersionId,
    [property: Range(typeof(decimal), "0.001", "999999999999999.999")] decimal KilosBase);

public sealed record UpsertOrdenProductoRequestDto(
    [property: Required, StringLength(60)] string Codigo,
    [property: Required, StringLength(150)] string Nombre,
    [property: StringLength(80)] string? Color,
    [property: Range(typeof(decimal), "0.01", "999999999999999.99")] decimal CantidadPieles,
    [property: Range(typeof(decimal), "0.01", "999999999999999.99")] decimal CantidadLados,
    [property: Range(typeof(decimal), "0", "999999999999999.999")] decimal KilosRecurtido,
    [property: Range(typeof(decimal), "0", "999999999999999.999")] decimal KilosAcabado,
    [property: StringLength(500)] string? Observacion,
    IReadOnlyCollection<OrdenProductoFormulaRequestDto> Formulas);

public sealed record FinalizarProductoProcesoRequestDto(
    [property: Range(typeof(decimal), "0", "999999999999999.99")] decimal? CantidadPielesTerminadas,
    [property: StringLength(500)] string? Observacion);

public sealed record IniciarProductoProcesoRequestDto(
    [property: Range(1, long.MaxValue)] long FormulaVersionId,
    [property: Range(typeof(decimal), "0.001", "999999999999999.999")] decimal PesoBaseKg,
    [property: Range(1, long.MaxValue)] long? ResponsableId);

public sealed record OrdenProductoFormulaDto(
    long Id,
    long ProcesoProductivoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    long FormulaVersionId,
    long FormulaId,
    string FormulaCodigo,
    string FormulaNombre,
    int NumeroVersion,
    decimal KilosBase,
    decimal CostoEstimado);

public sealed record OrdenProductoDto(
    long Id,
    long OrdenProduccionId,
    string Codigo,
    string Nombre,
    string? Color,
    decimal CantidadPieles,
    decimal CantidadLados,
    decimal KilosRecurtido,
    decimal KilosAcabado,
    string? Observacion,
    bool Activo,
    DateTime CreadoEn,
    decimal CostoEstimado,
    decimal CostoPorLado,
    string EstadoRecurtido,
    DateTime? InicioRecurtido,
    DateTime? FinRecurtido,
    long? ResponsableRecurtidoId,
    string? ResponsableRecurtidoNombre,
    string EstadoAcabado,
    DateTime? InicioAcabado,
    DateTime? FinAcabado,
    long? ResponsableAcabadoId,
    string? ResponsableAcabadoNombre,
    decimal? CantidadPielesTerminadas,
    long? ProductoTerminadoId,
    string? SolicitudRecurtidoEstado,
    string? SolicitudAcabadoEstado,
    IReadOnlyCollection<OrdenProductoFormulaDto> Formulas);

public sealed record FormulaProduccionOptionDto(
    long FormulaId,
    string FormulaCodigo,
    string FormulaNombre,
    long ProcesoProductivoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    long FormulaVersionId,
    int NumeroVersion,
    IReadOnlyCollection<FormulaInsumoDto> Insumos);

public sealed record FormulaInsumoDto(long InsumoId, string InsumoCodigo, string InsumoNombre, decimal Porcentaje, string? Observacion);
