using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Ajustes;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Compras;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Entradas;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Insumos;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.InventarioFisico;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Kardex;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Proveedores;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Salidas;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Stock;
using ErpCurtiembre.Modules.Inventario.Domain.Services;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Repositories;
using ErpCurtiembre.Modules.Inventario.Presentation.Endpoints;
using ErpCurtiembre.Shared.Abstractions;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace ErpCurtiembre.Modules.Inventario;

public sealed class InventarioModule : IErpModule
{
    public string Name => "Inventario";

    public void RegisterServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();

        services.AddDbContext<InventarioDbContext>((serviceProvider, options) =>
        {
            var databaseOptions = serviceProvider.GetRequiredService<IOptions<DatabaseOptions>>().Value;
            options.UseSqlServer(databaseOptions.DefaultConnection);
        });

        services.AddScoped<IInsumoRepository, SqlInsumoRepository>();
        services.AddScoped<IProveedorRepository, SqlProveedorRepository>();
        services.AddScoped<IUnidadMedidaLookupRepository, SqlUnidadMedidaLookupRepository>();
        services.AddScoped<IEntradaInventarioRepository, SqlEntradaInventarioRepository>();
        services.AddScoped<IStockRepository, SqlStockRepository>();
        services.AddScoped<IOrdenCompraRepository, SqlOrdenCompraRepository>();
        services.AddScoped<ISalidaInventarioRepository, SqlSalidaInventarioRepository>();
        services.AddScoped<IAjusteInventarioRepository, SqlAjusteInventarioRepository>();
        services.AddScoped<IInventarioFisicoRepository, SqlInventarioFisicoRepository>();
        services.AddScoped<IKardexRepository, SqlKardexRepository>();
        services.AddScoped<InboundStockCalculator>();
        services.AddScoped<OutboundStockCalculator>();

        services.AddScoped<InsumoCatalogService>();
        services.AddScoped<InventarioFisicoService>();
        services.AddScoped<ProveedorCatalogService>();
        services.AddScoped<AjusteInventarioService>();
        services.AddScoped<OrdenCompraService>();
        services.AddScoped<PurchaseEntryService>();
        services.AddScoped<SalidaInventarioService>();
        services.AddScoped<StockInitialService>();
        services.AddScoped<StockQueryService>();
        services.AddScoped<KardexQueryService>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app) => app.MapInventarioEndpoints();
}
