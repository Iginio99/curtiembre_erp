using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;

namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface IAuditoriaSeguridadRepository
{
    Task RegisterAsync(AuditoriaSeguridadEvent auditoriaEvent, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<AuditoriaSeguridadItemDto>> ListAsync(
        AuditSecurityFiltersDto filters,
        CancellationToken cancellationToken);
}
