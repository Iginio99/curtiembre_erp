using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.Entradas;

public sealed class StockInitialService(
    IEntradaInventarioRepository entradaInventarioRepository,
    IInsumoRepository insumoRepository,
    IDocumentSequenceService documentSequenceService,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<EntradaInventarioDetailDto>> RegisterAsync(
        RegistrarStockInicialRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        if (request.Detalles.Count == 0)
        {
            errors.Add("Debes registrar al menos un detalle.");
        }

        if (request.DocumentoSoporte is not null && string.IsNullOrWhiteSpace(request.DocumentoSoporte))
        {
            errors.Add("El documento soporte no puede estar vacio.");
        }

        if (request.Observacion is not null && string.IsNullOrWhiteSpace(request.Observacion))
        {
            errors.Add("La observacion no puede estar vacia.");
        }

        var details = new List<StockInitialRegistrationDetail>();
        var processedInsumoIds = new HashSet<long>();

        foreach (var detail in request.Detalles)
        {
            if (!processedInsumoIds.Add(detail.InsumoId))
            {
                errors.Add($"El insumo {detail.InsumoId} no debe repetirse en el mismo registro.");
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

            if (detail.Cantidad <= 0)
            {
                errors.Add($"La cantidad del insumo {insumo.Codigo} debe ser mayor que 0.");
                continue;
            }

            if (detail.CostoUnitario < 0)
            {
                errors.Add($"El costo unitario del insumo {insumo.Codigo} no puede ser negativo.");
                continue;
            }

            details.Add(new StockInitialRegistrationDetail(
                detail.InsumoId,
                detail.Cantidad,
                detail.CostoUnitario,
                NormalizeNullable(detail.Observacion)));
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<EntradaInventarioDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        string codigo;
        try
        {
            codigo = await documentSequenceService.GenerateNextAsync("EI", cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<EntradaInventarioDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        long entryId;
        try
        {
            entryId = await entradaInventarioRepository.RegisterStockInitialAsync(
                new StockInitialRegistration(
                    Codigo: codigo,
                    FechaEntrada: dateTimeProvider.Now,
                    DocumentoSoporte: NormalizeNullable(request.DocumentoSoporte),
                    Observacion: NormalizeNullable(request.Observacion),
                    ActorId: actorId,
                    Detalles: details),
                cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<EntradaInventarioDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        var entry = await entradaInventarioRepository.FindByIdAsync(entryId, cancellationToken);
        if (entry is null)
        {
            return UseCaseResult<EntradaInventarioDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se pudo recuperar la entrada de stock inicial registrada.");
        }

        var persistedDetails = await entradaInventarioRepository.ListDetailsAsync(entryId, cancellationToken);

        return UseCaseResult<EntradaInventarioDetailDto>.Ok(
            new EntradaInventarioDetailDto(
                entry.Id,
                entry.Codigo,
                entry.TipoEntrada,
                entry.FechaEntrada,
                entry.DocumentoSoporte,
                entry.Observacion,
                entry.Estado,
                entry.CreadoPorUsuarioId,
                entry.CreadoEn,
                persistedDetails.Select(MapDetail).ToArray()),
            "Stock inicial registrado correctamente.");
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static EntradaInventarioDetalleDto MapDetail(EntradaInventarioDetalle detail) =>
        new(
            detail.Id,
            detail.InsumoId,
            detail.InsumoCodigo,
            detail.InsumoNombre,
            detail.Cantidad,
            detail.CostoUnitario,
            detail.CostoTotal,
            detail.StockActual,
            detail.UnidadMedidaCodigo,
            detail.UnidadMedidaNombre,
            detail.Observacion);
}
