namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;

public sealed class SecuenciaDocumentoWriteModel
{
    public long Id { get; set; }

    public string CodigoDocumento { get; set; } = string.Empty;

    public string NombreDocumento { get; set; } = string.Empty;

    public string Prefijo { get; set; } = string.Empty;

    public int UltimoNumero { get; set; }

    public int LongitudNumero { get; set; }

    public bool Activo { get; set; }
}
