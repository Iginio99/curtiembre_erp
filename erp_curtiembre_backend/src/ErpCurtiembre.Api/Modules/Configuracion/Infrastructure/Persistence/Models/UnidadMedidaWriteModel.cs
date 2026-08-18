namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;

public sealed class UnidadMedidaWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public bool PermiteDecimales { get; set; }

    public bool Activo { get; set; }

    public DateTime CreadoEn { get; set; }
}
