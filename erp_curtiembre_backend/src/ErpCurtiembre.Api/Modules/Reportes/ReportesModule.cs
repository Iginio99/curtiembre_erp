using ErpCurtiembre.Modules.Reportes.Application.Ports;
using ErpCurtiembre.Modules.Reportes.Application.UseCases;
using ErpCurtiembre.Modules.Reportes.Infrastructure.Services;
using ErpCurtiembre.Modules.Reportes.Presentation.Endpoints;
using ErpCurtiembre.Shared.Abstractions;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Reportes;

public sealed class ReportesModule : IErpModule
{
    public string Name => "Reportes";

    public void RegisterServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();
        services.AddScoped<IReporteKpiService, ReporteKpiService>();
        services.AddScoped<IReporteStockActualService, ReporteInventarioService>();
        services.AddScoped<IReporteStockBajoService, ReporteStockBajoService>();
        services.AddScoped<IReporteKardexConsultaService, ReporteInventarioService>();
        services.AddScoped<IReporteComprasProveedorService, ReporteInventarioService>();
        services.AddScoped<IReporteConsumoProcesoService, ReporteInventarioService>();
        services.AddScoped<ObtenerDashboardKpiUseCase>();
        services.AddScoped<ListarStockActualReporteUseCase>();
        services.AddScoped<ListarStockBajoReporteUseCase>();
        services.AddScoped<ListarKardexReporteUseCase>();
        services.AddScoped<ListarComprasProveedorReporteUseCase>();
        services.AddScoped<ListarConsumoProcesoReporteUseCase>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app) => app.MapReportesEndpoints();
}
