namespace ErpCurtiembre.Modules.Reportes.Domain.Entities;

public sealed record KpiOperativo(
    string Codigo,
    string Nombre,
    decimal Valor,
    string UnidadMedida);
