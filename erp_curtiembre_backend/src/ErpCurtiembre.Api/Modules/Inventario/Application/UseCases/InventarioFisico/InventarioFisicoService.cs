using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Time;
using InventarioFisicoEntity = ErpCurtiembre.Modules.Inventario.Domain.Entities.InventarioFisico;
using InventarioFisicoDetalleEntity = ErpCurtiembre.Modules.Inventario.Domain.Entities.InventarioFisicoDetalle;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.InventarioFisico;

public sealed class InventarioFisicoService(
    IInventarioFisicoRepository inventarioFisicoRepository,
    IInsumoRepository insumoRepository,
    IDocumentSequenceService documentSequenceService,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<InventarioFisicoListItemDto>> ListAsync(
        InventarioFisicoFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await inventarioFisicoRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapListItem).ToArray();
    }

    public async Task<UseCaseResult<InventarioFisicoDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var inventarioFisico = await inventarioFisicoRepository.FindByIdAsync(id, cancellationToken);
        if (inventarioFisico is null)
        {
            return UseCaseResult<InventarioFisicoDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se encontro el inventario fisico.");
        }

        var details = await inventarioFisicoRepository.ListDetailsAsync(id, cancellationToken);
        return UseCaseResult<InventarioFisicoDetailDto>.Ok(MapDetail(inventarioFisico, details));
    }

    public async Task<UseCaseResult<InventarioFisicoDetailDto>> CreateAsync(
        CrearInventarioFisicoRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        string codigo;
        try
        {
            codigo = await documentSequenceService.GenerateNextAsync("IF", cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<InventarioFisicoDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        long inventarioFisicoId;
        try
        {
            inventarioFisicoId = await inventarioFisicoRepository.CreateAsync(
                new InventarioFisicoRegistration(
                    codigo,
                    dateTimeProvider.Now,
                    request.PeriodoAnio,
                    request.PeriodoMes,
                    actorId,
                    NormalizeNullable(request.Observacion)),
                cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<InventarioFisicoDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        return await GetByIdAsync(inventarioFisicoId, cancellationToken);
    }

    public async Task<UseCaseResult<InventarioFisicoDetailDto>> RegisterCountsAsync(
        long inventarioFisicoId,
        RegistrarConteoInventarioFisicoRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var processedInsumoIds = new HashSet<long>();
        var details = new List<InventarioFisicoCountRegistrationDetail>();

        foreach (var detail in request.Detalles)
        {
            if (!processedInsumoIds.Add(detail.InsumoId))
            {
                errors.Add($"El insumo {detail.InsumoId} no debe repetirse en el conteo.");
                continue;
            }

            var insumo = await insumoRepository.FindByIdAsync(detail.InsumoId, cancellationToken);
            if (insumo is null)
            {
                errors.Add($"No se encontro el insumo {detail.InsumoId}.");
                continue;
            }

            if (!insumo.Activo)
            {
                errors.Add($"El insumo {insumo.Codigo} esta inactivo.");
                continue;
            }

            if (detail.StockContado < 0)
            {
                errors.Add($"El stock contado del insumo {insumo.Codigo} no puede ser negativo.");
                continue;
            }

            details.Add(new InventarioFisicoCountRegistrationDetail(
                detail.InsumoId,
                decimal.Round(detail.StockContado, 4),
                NormalizeNullable(detail.Observacion)));
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<InventarioFisicoDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        try
        {
            await inventarioFisicoRepository.RegisterCountsAsync(inventarioFisicoId, details, cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<InventarioFisicoDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        return await GetByIdAsync(inventarioFisicoId, cancellationToken);
    }

    public async Task<UseCaseResult<InventarioFisicoDetailDto>> CloseAsync(
        long inventarioFisicoId,
        CerrarInventarioFisicoRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var inventarioFisico = await inventarioFisicoRepository.FindByIdAsync(inventarioFisicoId, cancellationToken);
        if (inventarioFisico is null)
        {
            return UseCaseResult<InventarioFisicoDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se encontro el inventario fisico.");
        }

        var details = await inventarioFisicoRepository.ListDetailsAsync(inventarioFisicoId, cancellationToken);
        if (details.Count == 0)
        {
            return UseCaseResult<InventarioFisicoDetailDto>.Fail(
                InventarioErrorCodes.Validation,
                "Debes registrar al menos un conteo antes de cerrar el inventario fisico.");
        }

        string? codigoAjustePositivo = null;
        string? codigoAjusteNegativo = null;

        try
        {
            if (details.Any(detail => detail.Diferencia > 0))
            {
                codigoAjustePositivo = await documentSequenceService.GenerateNextAsync("AJ", cancellationToken);
            }

            if (details.Any(detail => detail.Diferencia < 0))
            {
                codigoAjusteNegativo = await documentSequenceService.GenerateNextAsync("AJ", cancellationToken);
            }
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<InventarioFisicoDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        try
        {
            await inventarioFisicoRepository.CloseAsync(
                new InventarioFisicoCloseRegistration(
                    inventarioFisicoId,
                    dateTimeProvider.Now,
                    actorId,
                    NormalizeNullable(request.Observacion),
                    codigoAjustePositivo,
                    codigoAjusteNegativo),
                cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<InventarioFisicoDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        return await GetByIdAsync(inventarioFisicoId, cancellationToken);
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static InventarioFisicoListItemDto MapListItem(InventarioFisicoEntity item) =>
        new(
            item.Id,
            item.Codigo,
            item.FechaInicio,
            item.FechaCierre,
            item.PeriodoAnio,
            item.PeriodoMes,
            item.Estado,
            item.EjecutadoPorUsuarioId,
            item.Observacion,
            item.TotalItems,
            item.ItemsConDiferencia,
            item.TotalDiferenciaAbsoluta);

    private static InventarioFisicoDetailDto MapDetail(
        InventarioFisicoEntity header,
        IReadOnlyCollection<InventarioFisicoDetalleEntity> details)
    {
        var itemsConDiferencia = details.Count(detail => detail.Diferencia != 0);
        var itemsConAjustePositivo = details.Count(detail => detail.Diferencia > 0);
        var itemsConAjusteNegativo = details.Count(detail => detail.Diferencia < 0);
        var totalDiferenciaAbsoluta = details.Sum(detail => Math.Abs(detail.Diferencia));

        return new InventarioFisicoDetailDto(
            header.Id,
            header.Codigo,
            header.FechaInicio,
            header.FechaCierre,
            header.PeriodoAnio,
            header.PeriodoMes,
            header.Estado,
            header.EjecutadoPorUsuarioId,
            header.Observacion,
            new InventarioFisicoSummaryDto(
                details.Count,
                itemsConDiferencia,
                itemsConAjustePositivo,
                itemsConAjusteNegativo,
                totalDiferenciaAbsoluta),
            details.Select(detail => new InventarioFisicoDetalleConteoDto(
                detail.Id,
                detail.InsumoId,
                detail.InsumoCodigo,
                detail.InsumoNombre,
                detail.StockSistema,
                detail.StockContado,
                detail.Diferencia,
                detail.UnidadMedidaCodigo,
                detail.UnidadMedidaNombre,
                detail.Observacion)).ToArray());
    }
}
