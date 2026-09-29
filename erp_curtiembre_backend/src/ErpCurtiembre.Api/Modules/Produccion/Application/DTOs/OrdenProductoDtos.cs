using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

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
    IReadOnlyCollection<OrdenProductoFormulaDto> Formulas);

public sealed record FormulaProduccionOptionDto(
    long FormulaId,
    string FormulaCodigo,
    string FormulaNombre,
    string? TipoProducto,
    string? Color,
    long ProcesoProductivoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    long FormulaVersionId,
    int NumeroVersion,
    IReadOnlyCollection<FormulaInsumoDto> Insumos);

public sealed record FormulaInsumoDto(long InsumoId, string InsumoCodigo, string InsumoNombre, decimal Porcentaje, string? Observacion);
