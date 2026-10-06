namespace ErpCurtiembre.Modules.Configuracion.Domain.Entities;

public sealed class Formula
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string Nombre { get; init; } = string.Empty;

    public long ProcesoProductivoId { get; init; }

    public string ProcesoProductivoCodigo { get; init; } = string.Empty;

    public string ProcesoProductivoNombre { get; init; } = string.Empty;
    public string? TipoProducto { get; init; }
    public string? Color { get; init; }
    public long? ProductoId { get; init; }
    public string? ProductoCodigo { get; init; }
    public string? ProductoNombre { get; init; }

    public string? Descripcion { get; init; }

    public bool Activo { get; init; }

    public DateTime CreadoEn { get; init; }

    public long? CreadoPorUsuarioId { get; init; }

    public long? VersionVigenteId { get; init; }

    public int? VersionVigenteNumero { get; init; }

    public DateTime? VersionVigenteFechaInicio { get; init; }

    public DateTime? VersionVigenteFechaFin { get; init; }

    public bool? VersionVigente { get; init; }
}
