namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;

public sealed class FormulaDetalleWriteModel
{
    public long Id { get; set; }

    public long FormulaVersionId { get; set; }

    public long InsumoId { get; set; }

    public decimal Porcentaje { get; set; }

    public string? Observacion { get; set; }

    public bool Activo { get; set; }
}
