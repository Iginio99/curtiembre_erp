namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class MermaProcesoWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public long OrdenProcesoId { get; set; }

    public decimal CantidadPerdida { get; set; }

    public string? Motivo { get; set; }

    public string? Observacion { get; set; }

    public DateTime RegistradoEn { get; set; }

    public long? RegistradoPorUsuarioId { get; set; }
}
