using ErpCurtiembre.Shared.Persistence;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Shared.Composition;

public static class ErpModuleRegistrationExtensions
{
    public static IServiceCollection AddErpModules(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services
            .AddOptions<DatabaseOptions>()
            .Bind(configuration.GetSection(DatabaseOptions.SectionName))
            .ValidateDataAnnotations()
            .Validate(
                options => options.Schemas.All(schema => !string.IsNullOrWhiteSpace(schema)),
                "Database:Schemas no debe contener valores vacios.")
            .ValidateOnStart();

        services
            .AddOptions<TimeOptions>()
            .Bind(configuration.GetSection(TimeOptions.SectionName))
            .ValidateDataAnnotations()
            .ValidateOnStart();

        services.AddSingleton<IDateTimeProvider, PeruDateTimeProvider>();

        foreach (var module in ErpModuleCatalog.Modules)
        {
            module.RegisterServices(services, configuration);
        }

        return services;
    }

    public static IEndpointRouteBuilder MapErpModules(this IEndpointRouteBuilder app)
    {
        foreach (var module in ErpModuleCatalog.Modules)
        {
            module.MapEndpoints(app);
        }

        return app;
    }
}
