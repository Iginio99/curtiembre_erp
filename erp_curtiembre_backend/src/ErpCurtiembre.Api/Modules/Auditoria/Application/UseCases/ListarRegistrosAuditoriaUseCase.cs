using ErpCurtiembre.Modules.Auditoria.Application.DTOs;
using ErpCurtiembre.Modules.Auditoria.Application.Ports;

namespace ErpCurtiembre.Modules.Auditoria.Application.UseCases;

public sealed class ListarRegistrosAuditoriaUseCase(IAuditoriaQueryService auditoriaQueryService)
{
    public async Task<IReadOnlyCollection<RegistroAuditoriaDto>> ExecuteAsync(CancellationToken cancellationToken)
    {
        var items = await auditoriaQueryService.ListAsync(cancellationToken);

        return items
            .Select(item => new RegistroAuditoriaDto(
                item.Id,
                item.Modulo,
                item.Accion,
                item.Usuario,
                item.Fecha))
            .ToArray();
    }
}
