namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class InventarioFisico
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public DateTime FechaInicio { get; init; }

    public DateTime? FechaCierre { get; init; }

    public int PeriodoAnio { get; init; }

    public int PeriodoMes { get; init; }

    public string Estado { get; init; } = string.Empty;

    public long EjecutadoPorUsuarioId { get; init; }

    public string? Observacion { get; init; }

    public int TotalItems { get; init; }

    public int ItemsConDiferencia { get; init; }

    public decimal TotalDiferenciaAbsoluta { get; init; }
}
