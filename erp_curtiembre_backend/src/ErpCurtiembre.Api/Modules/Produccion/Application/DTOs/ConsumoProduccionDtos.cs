using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

public sealed record ConsumoPlanificadoItemDto(
    long Id,
    long OrdenProduccionId,
    long OrdenProcesoId,
    long ProcesoProductivoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    long FormulaVersionId,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    decimal Porcentaje,
    decimal CantidadPlanificada,
    DateTime CreadoEn);

public sealed record SolicitarConsumoDetalleRequestDto(
    [property: Range(1, long.MaxValue)] long InsumoId,
    [property: Range(typeof(decimal), "0.0001", "999999999999999.9999")] decimal Cantidad,
    [property: StringLength(300)] string? Observacion = null);

public sealed record SolicitarConsumoProduccionRequestDto(
    [property: Range(1, long.MaxValue)] long OrdenProcesoId,
    [property: StringLength(150)] string? Motivo,
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<SolicitarConsumoDetalleRequestDto> Detalles);

public sealed record ConsumoRealItemDto(
    long Id,
    long OrdenProduccionId,
    long OrdenProcesoId,
    long ProcesoProductivoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    long? SalidaInventarioDetalleId,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    decimal CantidadConsumida,
    decimal CostoUnitario,
    decimal CostoTotal,
    bool EsExtra,
    DateTime CreadoEn);

public sealed record DesviacionConsumoItemDto(
    long Id,
    long? OrdenConsumoPlanificadoId,
    long OrdenConsumoRealId,
    long OrdenProduccionId,
    long OrdenProcesoId,
    long ProcesoProductivoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    decimal CantidadPlanificada,
    decimal CantidadReal,
    decimal CantidadDesviacion,
    string? Motivo,
    DateTime RegistradoEn);
