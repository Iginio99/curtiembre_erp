using ErpCurtiembre.Modules.Auditoria.Application.Ports;
using ErpCurtiembre.Modules.Auditoria.Application.UseCases;
using ErpCurtiembre.Modules.Auditoria.Infrastructure.Services;
using ErpCurtiembre.Modules.Auditoria.Presentation.Endpoints;
using ErpCurtiembre.Shared.Abstractions;

namespace ErpCurtiembre.Modules.Auditoria;

public sealed class AuditoriaModule : IErpModule
{
    public string Name => "Auditoria";

    public void RegisterServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<IAuditoriaQueryService, AuditoriaQueryService>();
        services.AddSingleton<ListarRegistrosAuditoriaUseCase>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app) => app.MapAuditoriaEndpoints();
}
