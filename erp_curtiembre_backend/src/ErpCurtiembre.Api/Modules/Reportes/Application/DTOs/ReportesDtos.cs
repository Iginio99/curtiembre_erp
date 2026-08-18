namespace ErpCurtiembre.Modules.Reportes.Application.DTOs;

public sealed record KpiDashboardDto(
    string Codigo,
    string Nombre,
    decimal Valor,
    string UnidadMedida);
