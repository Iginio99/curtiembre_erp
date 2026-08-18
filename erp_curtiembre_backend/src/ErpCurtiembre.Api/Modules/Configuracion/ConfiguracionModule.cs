using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases.Areas;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases.Formulas;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases.TiposPiel;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases.UnidadesMedida;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Repositories;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Services;
using ErpCurtiembre.Modules.Configuracion.Presentation.Endpoints;
using ErpCurtiembre.Shared.Abstractions;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace ErpCurtiembre.Modules.Configuracion;

public sealed class ConfiguracionModule : IErpModule
{
    public string Name => "Configuracion";

    public void RegisterServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();
        services.AddSingleton<IConfiguracionQueryService, ConfiguracionQueryService>();

        services.AddDbContext<ConfiguracionDbContext>((serviceProvider, options) =>
        {
            var databaseOptions = serviceProvider.GetRequiredService<IOptions<DatabaseOptions>>().Value;
            options.UseSqlServer(databaseOptions.DefaultConnection);
        });

        services.AddScoped<IAreaRepository, SqlAreaRepository>();
        services.AddScoped<IUnidadMedidaRepository, SqlUnidadMedidaRepository>();
        services.AddScoped<ITipoPielRepository, SqlTipoPielRepository>();
        services.AddScoped<IFormulaRepository, SqlFormulaRepository>();
        services.AddScoped<IDocumentSequenceService, DocumentSequenceService>();

        services.AddScoped<ListarParametrosConfiguracionUseCase>();
        services.AddScoped<AreaCatalogService>();
        services.AddScoped<UnidadMedidaCatalogService>();
        services.AddScoped<TipoPielCatalogService>();
        services.AddScoped<FormulaCatalogService>();
        services.AddScoped<ProcesoProductivoCatalogService>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app) => app.MapConfiguracionEndpoints();
}
