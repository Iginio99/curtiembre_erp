namespace ErpCurtiembre.Shared.Abstractions;

public interface IErpModule
{
    string Name { get; }

    void RegisterServices(IServiceCollection services, IConfiguration configuration);

    void MapEndpoints(IEndpointRouteBuilder app);
}
