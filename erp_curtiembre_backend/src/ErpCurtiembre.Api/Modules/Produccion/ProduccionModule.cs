using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Clientes;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Cierre;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Consumo;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Lotes;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Ordenes;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Procesos;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Reportes;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Solicitudes;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Services;
using ErpCurtiembre.Modules.Produccion.Presentation.Endpoints;
using ErpCurtiembre.Shared.Abstractions;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace ErpCurtiembre.Modules.Produccion;

public sealed class ProduccionModule : IErpModule
{
    public string Name => "Produccion";

    public void RegisterServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();

        services.AddDbContext<ProduccionDbContext>((serviceProvider, options) =>
        {
            var databaseOptions = serviceProvider.GetRequiredService<IOptions<DatabaseOptions>>().Value;
            options.UseSqlServer(databaseOptions.DefaultConnection);
        });

        services.AddScoped<IClienteRepository, SqlClienteRepository>();
        services.AddScoped<ILoteRepository, SqlLoteRepository>();
        services.AddScoped<ITipoPielLookupRepository, SqlTipoPielLookupRepository>();
        services.AddScoped<IOrdenProduccionRepository, SqlOrdenProduccionRepository>();
        services.AddScoped<IProcesoProductivoLookupRepository, SqlProcesoProductivoLookupRepository>();
        services.AddScoped<IUsuarioLookupRepository, SqlUsuarioLookupRepository>();
        services.AddScoped<IConsumoProduccionRepository, SqlConsumoProduccionRepository>();
        services.AddScoped<IProduccionInventarioGateway, ProduccionInventarioGateway>();
        services.AddScoped<ICierreProduccionRepository, SqlCierreProduccionRepository>();
        services.AddScoped<ICalidadProductoLookupRepository, SqlCalidadProductoLookupRepository>();
        services.AddScoped<IProduccionReportQueryRepository, SqlProduccionReportQueryRepository>();
        services.AddScoped<ISolicitudInsumoRepository, SqlSolicitudInsumoRepository>();
        services.AddScoped<ISolicitudInsumoAlertService, SolicitudInsumoAlertService>();

        services.AddScoped<ClienteCatalogService>();
        services.AddScoped<LoteCatalogService>();
        services.AddScoped<OrdenProduccionService>();
        services.AddScoped<OrdenProcesoService>();
        services.AddScoped<ConsumoProduccionService>();
        services.AddScoped<CierreProduccionService>();
        services.AddScoped<ProduccionReportesService>();
        services.AddScoped<SolicitudInsumoService>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app) => app.MapProduccionEndpoints();
}
