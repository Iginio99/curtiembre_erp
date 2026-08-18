using ErpCurtiembre.Modules.Auditoria.Domain.Entities;

namespace ErpCurtiembre.Modules.Auditoria.Application.Ports;

public interface IAuditoriaQueryService
{
    Task<IReadOnlyCollection<RegistroAuditoria>> ListAsync(CancellationToken cancellationToken);
}
