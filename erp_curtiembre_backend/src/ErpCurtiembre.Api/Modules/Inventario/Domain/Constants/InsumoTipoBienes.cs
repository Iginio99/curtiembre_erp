namespace ErpCurtiembre.Modules.Inventario.Domain.Constants;

public static class InsumoTipoBienes
{
    public const string InsumoQuimico = "INSUMO_QUIMICO";
    public const string MateriaPrima = "MATERIA_PRIMA";
    public const string ProductoTerminado = "PRODUCTO_TERMINADO";

    public static readonly IReadOnlySet<string> Todos = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
    {
        InsumoQuimico,
        MateriaPrima,
        ProductoTerminado
    };
}
