using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Users;

public sealed class ListAuditSecurityUseCase(IAuditoriaSeguridadRepository auditoriaSeguridadRepository)
{
    public Task<IReadOnlyCollection<AuditoriaSeguridadItemDto>> ExecuteAsync(
        AuditSecurityFiltersDto filters,
        CancellationToken cancellationToken) =>
        auditoriaSeguridadRepository.ListAsync(filters, cancellationToken);
}
