namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;

public sealed class ManoObraDirectaWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public long OrdenProcesoId { get; set; }

    public decimal Monto { get; set; }

    public string? Descripcion { get; set; }

    public DateTime RegistradoEn { get; set; }

    public long? RegistradoPorUsuarioId { get; set; }
}
