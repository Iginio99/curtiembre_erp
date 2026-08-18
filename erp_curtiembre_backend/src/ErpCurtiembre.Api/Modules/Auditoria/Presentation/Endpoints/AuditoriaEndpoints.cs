using ErpCurtiembre.Modules.Auditoria.Application.UseCases;

namespace ErpCurtiembre.Modules.Auditoria.Presentation.Endpoints;

public static class AuditoriaEndpoints
{
    public static IEndpointRouteBuilder MapAuditoriaEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auditoria").WithTags("Auditoria");

        group.MapGet("/health", () => Results.Ok(new
        {
            module = "Auditoria",
            status = "ready"
        }));

        group.MapGet("/registros", async (
            ListarRegistrosAuditoriaUseCase useCase,
            CancellationToken cancellationToken) =>
            Results.Ok(await useCase.ExecuteAsync(cancellationToken)));

        return app;
    }
}
