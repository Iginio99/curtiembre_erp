namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;

public sealed class CostoIndirectoWriteModel
{
    public long Id { get; set; }

    public long PeriodoCostoId { get; set; }

    public string TipoCosto { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public decimal Monto { get; set; }

    public DateTime RegistradoEn { get; set; }

    public long? RegistradoPorUsuarioId { get; set; }
}
