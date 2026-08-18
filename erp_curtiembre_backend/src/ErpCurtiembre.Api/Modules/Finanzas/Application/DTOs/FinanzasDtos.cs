namespace ErpCurtiembre.Modules.Finanzas.Application.DTOs;

public sealed record PeriodoCostoFiltersDto(
    int? Anio,
    int? Mes,
    string? Estado);

public sealed record PeriodoCostoListItemDto(
    long Id,
    int Anio,
    int Mes,
    DateTime FechaInicio,
    DateTime FechaFin,
    string Estado,
    DateTime? CerradoEn,
    long? CerradoPorUsuarioId,
    string? Observacion,
    decimal TotalIndirectos);

public sealed record PeriodoCostoDetailDto(
    long Id,
    int Anio,
    int Mes,
    DateTime FechaInicio,
    DateTime FechaFin,
    string Estado,
    DateTime? CerradoEn,
    long? CerradoPorUsuarioId,
    string? Observacion,
    decimal TotalIndirectos);

public sealed record CreatePeriodoCostoRequestDto(
    int Anio,
    int Mes,
    string? Observacion);

public sealed record ClosePeriodoCostoRequestDto(string? Observacion);

public sealed record CostoIndirectoFiltersDto(
    long? PeriodoCostoId,
    string? TipoCosto,
    string? Texto);

public sealed record CostoIndirectoListItemDto(
    long Id,
    long PeriodoCostoId,
    int PeriodoAnio,
    int PeriodoMes,
    string PeriodoEstado,
    string TipoCosto,
    string? Descripcion,
    decimal Monto,
    DateTime RegistradoEn,
    long? RegistradoPorUsuarioId);

public sealed record CostoIndirectoDetailDto(
    long Id,
    long PeriodoCostoId,
    int PeriodoAnio,
    int PeriodoMes,
    string PeriodoEstado,
    string TipoCosto,
    string? Descripcion,
    decimal Monto,
    DateTime RegistradoEn,
    long? RegistradoPorUsuarioId);

public sealed record CreateCostoIndirectoRequestDto(
    long PeriodoCostoId,
    string TipoCosto,
    string? Descripcion,
    decimal Monto);

public sealed record ManoObraDirectaFiltersDto(
    long? OrdenProduccionId,
    long? OrdenProcesoId);

public sealed record ManoObraDirectaListItemDto(
    long Id,
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    decimal Monto,
    string? Descripcion,
    DateTime RegistradoEn,
    long? RegistradoPorUsuarioId);

public sealed record ManoObraDirectaDetailDto(
    long Id,
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    decimal Monto,
    string? Descripcion,
    DateTime RegistradoEn,
    long? RegistradoPorUsuarioId);

public sealed record CreateManoObraDirectaRequestDto(
    long OrdenProduccionId,
    long OrdenProcesoId,
    decimal Monto,
    string? Descripcion);

public sealed record ActivoDepreciableFiltersDto(
    string? Texto,
    bool? Activo);

public sealed record ActivoDepreciableListItemDto(
    long Id,
    string Codigo,
    string Nombre,
    decimal ValorCompra,
    DateTime FechaCompra,
    int VidaUtilMeses,
    decimal ValorResidual,
    bool Activo,
    DateTime CreadoEn);

public sealed record ActivoDepreciableDetailDto(
    long Id,
    string Codigo,
    string Nombre,
    decimal ValorCompra,
    DateTime FechaCompra,
    int VidaUtilMeses,
    decimal ValorResidual,
    bool Activo,
    DateTime CreadoEn,
    decimal DepreciacionMensual);

public sealed record CreateActivoDepreciableRequestDto(
    string Codigo,
    string Nombre,
    decimal ValorCompra,
    DateTime FechaCompra,
    int VidaUtilMeses,
    decimal ValorResidual,
    bool Activo);

public sealed record UpdateActivoDepreciableRequestDto(
    string Codigo,
    string Nombre,
    decimal ValorCompra,
    DateTime FechaCompra,
    int VidaUtilMeses,
    decimal ValorResidual,
    bool Activo);

public sealed record DepreciacionPeriodoFiltersDto(
    long? PeriodoCostoId,
    long? ActivoDepreciableId);

public sealed record DepreciacionPeriodoListItemDto(
    long Id,
    long PeriodoCostoId,
    int PeriodoAnio,
    int PeriodoMes,
    long ActivoDepreciableId,
    string ActivoCodigo,
    string ActivoNombre,
    decimal MontoDepreciacion,
    DateTime CalculadoEn);

public sealed record DepreciacionPeriodoDetailDto(
    long Id,
    long PeriodoCostoId,
    int PeriodoAnio,
    int PeriodoMes,
    long ActivoDepreciableId,
    string ActivoCodigo,
    string ActivoNombre,
    decimal MontoDepreciacion,
    DateTime CalculadoEn);

public sealed record CalculoDepreciacionResultDto(
    long PeriodoCostoId,
    int PeriodoAnio,
    int PeriodoMes,
    int TotalActivosElegibles,
    int TotalDepreciacionesGeneradas,
    decimal MontoTotalGenerado,
    IReadOnlyCollection<DepreciacionPeriodoDetailDto> DepreciacionesGeneradas);

public sealed record CostoProcesoFiltersDto(
    long? OrdenProduccionId,
    long? OrdenProcesoId);

public sealed record CostoProcesoListItemDto(
    long Id,
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    decimal CostoInsumos,
    decimal CostoManoObra,
    decimal CostoTotal,
    DateTime CalculadoEn);

public sealed record CostoProcesoDetailDto(
    long Id,
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    decimal CostoInsumos,
    decimal CostoManoObra,
    decimal CostoTotal,
    DateTime CalculadoEn);

public sealed record CalculoCostoProcesoRequestDto(
    long OrdenProduccionId,
    long OrdenProcesoId);

public sealed record CostoOrdenFiltersDto(
    long? OrdenProduccionId,
    long? PeriodoCostoId,
    string? Estado);

public sealed record CostoOrdenListItemDto(
    long Id,
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    long? PeriodoCostoId,
    int? PeriodoAnio,
    int? PeriodoMes,
    decimal CostoPieles,
    decimal CostoInsumos,
    decimal CostoManoObra,
    decimal CostoIndirectoAsignado,
    decimal CostoDepreciacionAsignado,
    decimal CostoTotal,
    decimal? PielesBuenasFinales,
    decimal? CostoPorPiel,
    decimal? CostoEstimado,
    decimal? CostoReal,
    string Estado,
    DateTime CalculadoEn,
    long? CalculadoPorUsuarioId);

public sealed record CostoOrdenDetailDto(
    long Id,
    long OrdenProduccionId,
    string OrdenProduccionCodigo,
    long? PeriodoCostoId,
    int? PeriodoAnio,
    int? PeriodoMes,
    decimal CostoPieles,
    decimal CostoInsumos,
    decimal CostoManoObra,
    decimal CostoIndirectoAsignado,
    decimal CostoDepreciacionAsignado,
    decimal CostoTotal,
    decimal? PielesBuenasFinales,
    decimal? CostoPorPiel,
    decimal? CostoEstimado,
    decimal? CostoReal,
    string Estado,
    DateTime CalculadoEn,
    long? CalculadoPorUsuarioId);
