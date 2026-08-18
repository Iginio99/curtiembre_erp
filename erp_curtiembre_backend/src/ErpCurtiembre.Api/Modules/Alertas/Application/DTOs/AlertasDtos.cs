namespace ErpCurtiembre.Modules.Alertas.Application.DTOs;

public sealed record AlertaActivaDto(
    long Id,
    string TipoAlerta,
    string Titulo,
    string Mensaje,
    string Severidad,
    string Estado,
    string ModuloOrigen,
    string? EntidadOrigen,
    long? EntidadOrigenId,
    DateTime GeneradaEn);

public sealed record AlertaFiltersDto(
    string? Estado,
    string? Severidad,
    string? TipoAlerta,
    string? ModuloOrigen,
    DateTime? FechaDesde,
    DateTime? FechaHasta);

public sealed record AlertaDetalleDto(
    long Id,
    string TipoAlerta,
    string Titulo,
    string Mensaje,
    string Severidad,
    string Estado,
    string ModuloOrigen,
    string? EntidadOrigen,
    long? EntidadOrigenId,
    DateTime GeneradaEn,
    DateTime? LeidaEn,
    DateTime? CerradaEn);

public sealed record AlertaHistorialDto(
    long Id,
    string? EstadoAnterior,
    string EstadoNuevo,
    string? Comentario,
    long? CambiadoPorUsuarioId,
    string? CambiadoPorNombre,
    DateTime CambiadoEn);

public sealed record AlertasResumenDto(
    int TotalPendientes,
    int TotalLeidas,
    int TotalAlta,
    int TotalMedia,
    int TotalBaja,
    IReadOnlyCollection<AlertaActivaDto> Recientes);

public sealed record CerrarAlertaRequestDto(string? Comentario);
