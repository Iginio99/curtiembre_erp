namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class InventarioFisicoWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public DateTime FechaInicio { get; set; }

    public DateTime? FechaCierre { get; set; }

    public int PeriodoAnio { get; set; }

    public int PeriodoMes { get; set; }

    public string Estado { get; set; } = string.Empty;

    public long EjecutadoPorUsuarioId { get; set; }

    public string? Observacion { get; set; }
}
