using ErpCurtiembre.Modules.Auditoria.Application.Ports;
using ErpCurtiembre.Modules.Auditoria.Domain.Entities;

namespace ErpCurtiembre.Modules.Auditoria.Infrastructure.Services;

public sealed class AuditoriaQueryService : IAuditoriaQueryService
{
    private static readonly RegistroAuditoria[] Items =
    [
        new(
            Guid.Parse("40000000-0000-0000-0000-000000000001"),
            "Seguridad",
            "Inicio de sesion",
            "admin",
            DateTimeOffset.UtcNow.AddMinutes(-45)),
        new(
            Guid.Parse("40000000-0000-0000-0000-000000000002"),
            "Inventario",
            "Registro de salida por proceso",
            "admin",
            DateTimeOffset.UtcNow.AddMinutes(-20))
    ];

    public Task<IReadOnlyCollection<RegistroAuditoria>> ListAsync(CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyCollection<RegistroAuditoria>>(Items);
}
