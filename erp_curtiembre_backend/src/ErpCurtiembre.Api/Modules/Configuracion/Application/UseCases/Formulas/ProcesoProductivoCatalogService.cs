using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;

namespace ErpCurtiembre.Modules.Configuracion.Application.UseCases.Formulas;

public sealed class ProcesoProductivoCatalogService(IFormulaRepository formulaRepository)
{
    public async Task<IReadOnlyCollection<ProcesoProductivoCatalogItemDto>> ListActiveOrderedAsync(CancellationToken cancellationToken)
    {
        var items = await formulaRepository.ListActiveProcesosProductivosAsync(cancellationToken);
        return items
            .Select(item => new ProcesoProductivoCatalogItemDto(item.Id, item.Codigo, item.Nombre, item.OrdenSecuencia))
            .ToArray();
    }
}
