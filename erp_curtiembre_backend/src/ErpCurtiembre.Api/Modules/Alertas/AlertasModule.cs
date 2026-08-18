using ErpCurtiembre.Modules.Alertas.Application.Ports;
using ErpCurtiembre.Modules.Alertas.Application.UseCases;
using ErpCurtiembre.Modules.Alertas.Infrastructure.Services;
using ErpCurtiembre.Modules.Alertas.Presentation.Endpoints;
using ErpCurtiembre.Shared.Abstractions;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Alertas;

public sealed class AlertasModule : IErpModule
{
    public string Name => "Alertas";

    public void RegisterServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();
        services.AddScoped<IAlertaQueryService, SqlAlertaQueryService>();
        services.AddScoped<IAlertaCommandService, SqlAlertaCommandService>();
        services.AddScoped<IStockAlertIntegrationService, StockAlertIntegrationService>();
        services.AddScoped<ListarAlertasActivasUseCase>();
        services.AddScoped<ListarAlertasUseCase>();
        services.AddScoped<ObtenerAlertaDetalleUseCase>();
        services.AddScoped<ObtenerResumenAlertasUseCase>();
        services.AddScoped<ListarHistorialAlertaUseCase>();
        services.AddScoped<MarcarAlertaLeidaUseCase>();
        services.AddScoped<CerrarAlertaUseCase>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app) => app.MapAlertasEndpoints();
}
