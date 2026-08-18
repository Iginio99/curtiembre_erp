using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;

namespace ErpCurtiembre.Modules.Configuracion.Application.UseCases;

public sealed class ListarParametrosConfiguracionUseCase(IConfiguracionQueryService configuracionQueryService)
{
    public async Task<IReadOnlyCollection<ParametroConfiguracionDto>> ExecuteAsync(
        CancellationToken cancellationToken)
    {
        var items = await configuracionQueryService.ListAsync(cancellationToken);

        return items
            .Select(item => new ParametroConfiguracionDto(
                item.Id,
                item.Clave,
                item.Valor,
                item.Descripcion,
                item.TipoDato,
                item.Editable,
                item.ActualizadoEn))
            .ToArray();
    }
}
