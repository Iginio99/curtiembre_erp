using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Activos;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Costos;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Depreciaciones;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Indirectos;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.ManoObra;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Periodos;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Pricing;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Reportes;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Services;
using ErpCurtiembre.Modules.Finanzas.Presentation.Endpoints;
using ErpCurtiembre.Shared.Abstractions;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace ErpCurtiembre.Modules.Finanzas;

public sealed class FinanzasModule : IErpModule
{
    public string Name => "Finanzas";

    public void RegisterServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();

        services.AddDbContext<FinanzasDbContext>((serviceProvider, options) =>
        {
            var databaseOptions = serviceProvider.GetRequiredService<IOptions<DatabaseOptions>>().Value;
            options.UseSqlServer(databaseOptions.DefaultConnection);
        });

        services.AddScoped<IPeriodoCostoRepository, SqlPeriodoCostoRepository>();
        services.AddScoped<ICostoIndirectoRepository, SqlCostoIndirectoRepository>();
        services.AddScoped<IManoObraDirectaRepository, SqlManoObraDirectaRepository>();
        services.AddScoped<IActivoDepreciableRepository, SqlActivoDepreciableRepository>();
        services.AddScoped<IDepreciacionPeriodoRepository, SqlDepreciacionPeriodoRepository>();
        services.AddScoped<IProduccionFinanceLookupRepository, SqlProduccionFinanceLookupRepository>();
        services.AddScoped<ICostoProcesoRepository, SqlCostoProcesoRepository>();
        services.AddScoped<ICostoOrdenRepository, SqlCostoOrdenRepository>();
        services.AddScoped<IPrecioSugeridoRepository, SqlPrecioSugeridoRepository>();
        services.AddScoped<IRentabilidadOrdenRepository, SqlRentabilidadOrdenRepository>();
        services.AddScoped<IFinanzasReportQueryService, SqlFinanzasReportQueryService>();

        services.AddScoped<PeriodoCostoService>();
        services.AddScoped<CostoIndirectoService>();
        services.AddScoped<ManoObraDirectaService>();
        services.AddScoped<ActivoDepreciableService>();
        services.AddScoped<DepreciacionPeriodoService>();
        services.AddScoped<CostoProcesoService>();
        services.AddScoped<CostoOrdenService>();
        services.AddScoped<PrecioSugeridoService>();
        services.AddScoped<RentabilidadOrdenService>();
        services.AddScoped<FinanzasReportesService>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app) => app.MapFinanzasEndpoints();
}
