namespace ErpCurtiembre.Modules.Alertas.Domain.Entities;

public sealed record AlertaHistorialItem(
    long Id,
    string? EstadoAnterior,
    string EstadoNuevo,
    string? Comentario,
    long? CambiadoPorUsuarioId,
    string? CambiadoPorNombre,
    DateTime CambiadoEn);
