namespace ErpCurtiembre.Modules.Alertas.Domain.Entities;

public sealed record AlertaDetalle(
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
