using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Lotes;

public sealed class LoteCatalogService(
    ILoteRepository loteRepository,
    IClienteRepository clienteRepository,
    ITipoPielLookupRepository tipoPielLookupRepository,
    IDocumentSequenceService documentSequenceService)
{
    public async Task<IReadOnlyCollection<LoteListItemDto>> ListAsync(
        LoteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await loteRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<LoteDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var lote = await loteRepository.FindByIdAsync(id, cancellationToken);
        return lote is null
            ? UseCaseResult<LoteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el lote.")
            : UseCaseResult<LoteDetailDto>.Ok(MapDetail(lote));
    }

    public async Task<UseCaseResult<LoteDisponibilidadDto>> GetAvailabilityAsync(long id, CancellationToken cancellationToken)
    {
        var lote = await loteRepository.FindByIdAsync(id, cancellationToken);
        return lote is null
            ? UseCaseResult<LoteDisponibilidadDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el lote.")
            : UseCaseResult<LoteDisponibilidadDto>.Ok(MapAvailability(lote));
    }

    public async Task<UseCaseResult<LoteDetailDto>> CreateAsync(
        CreateLoteRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var validation = await ValidateRequestAsync(
            request.ClienteId,
            request.TipoPielId,
            request.FechaIngreso,
            request.CantidadPielesInicial,
            request.ClienteTraeLote,
            request.CostoPielesTotal,
            null,
            cancellationToken);

        if (validation.Errors.Count > 0)
        {
            return UseCaseResult<LoteDetailDto>.Fail(ProduccionErrorCodes.Validation, string.Join(" ", validation.Errors));
        }

        string codigo;
        try
        {
            codigo = await documentSequenceService.GenerateNextAsync("LT", cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<LoteDetailDto>.Fail(ProduccionErrorCodes.Conflict, exception.Message);
        }

        var id = await loteRepository.CreateAsync(
            new Lote
            {
                Codigo = codigo,
                ClienteId = request.ClienteId,
                TipoPielId = request.TipoPielId,
                FechaIngreso = request.FechaIngreso.Date,
                CantidadPielesInicial = decimal.Round(request.CantidadPielesInicial, 4),
                CantidadPielesDisponible = decimal.Round(request.CantidadPielesInicial, 4),
                ClienteTraeLote = request.ClienteTraeLote,
                CostoPielesTotal = decimal.Round(request.CostoPielesTotal, 2),
                Observacion = NormalizeNullable(request.Observacion),
                Estado = "DISPONIBLE",
                CreadoPorUsuarioId = actorId
            },
            cancellationToken);

        var created = await loteRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<LoteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se pudo recuperar el lote creado.")
            : UseCaseResult<LoteDetailDto>.Ok(MapDetail(created), "Lote creado correctamente.");
    }

    public async Task<UseCaseResult<LoteDetailDto>> UpdateAsync(
        long id,
        UpdateLoteRequestDto request,
        CancellationToken cancellationToken)
    {
        var existing = await loteRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<LoteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el lote.");
        }

        var validation = await ValidateRequestAsync(
            request.ClienteId,
            request.TipoPielId,
            request.FechaIngreso,
            request.CantidadPielesInicial,
            request.ClienteTraeLote,
            request.CostoPielesTotal,
            existing,
            cancellationToken);

        if (validation.Errors.Count > 0)
        {
            return UseCaseResult<LoteDetailDto>.Fail(ProduccionErrorCodes.Validation, string.Join(" ", validation.Errors));
        }

        var used = decimal.Round(existing.CantidadPielesInicial - existing.CantidadPielesDisponible, 4);
        var hasOrders = await loteRepository.HasAnyOrderAsync(id, cancellationToken);

        if (hasOrders)
        {
            if (existing.ClienteId != request.ClienteId)
            {
                validation.Errors.Add("No se puede cambiar el cliente de un lote que ya tiene ordenes de produccion.");
            }

            if (existing.TipoPielId != request.TipoPielId)
            {
                validation.Errors.Add("No se puede cambiar el tipo de piel de un lote que ya tiene ordenes de produccion.");
            }

            if (request.CantidadPielesInicial < used)
            {
                validation.Errors.Add("La nueva cantidad inicial no puede ser menor que la cantidad ya utilizada por el lote.");
            }

            if (existing.CantidadPielesInicial != request.CantidadPielesInicial)
            {
                validation.Errors.Add("No se puede cambiar la cantidad de pieles de un lote que ya tiene ordenes de produccion.");
            }

            if (existing.ClienteTraeLote != request.ClienteTraeLote)
            {
                validation.Errors.Add("No se puede cambiar el origen de un lote que ya tiene ordenes de produccion.");
            }

            if (existing.CostoPielesTotal != request.CostoPielesTotal)
            {
                validation.Errors.Add("No se puede cambiar el costo de pieles de un lote que ya tiene ordenes de produccion.");
            }
        }

        if (validation.Errors.Count > 0)
        {
            return UseCaseResult<LoteDetailDto>.Fail(ProduccionErrorCodes.Validation, string.Join(" ", validation.Errors));
        }

        var nuevaCantidadDisponible = decimal.Round(request.CantidadPielesInicial - used, 4);
        var nuevoEstado = existing.Estado == "ANULADO"
            ? "ANULADO"
            : nuevaCantidadDisponible <= 0 ? "AGOTADO" : "DISPONIBLE";

        await loteRepository.UpdateAsync(
            new Lote
            {
                Id = id,
                Codigo = existing.Codigo,
                ClienteId = request.ClienteId,
                TipoPielId = request.TipoPielId,
                FechaIngreso = request.FechaIngreso.Date,
                CantidadPielesInicial = decimal.Round(request.CantidadPielesInicial, 4),
                CantidadPielesDisponible = nuevaCantidadDisponible,
                ClienteTraeLote = request.ClienteTraeLote,
                CostoPielesTotal = decimal.Round(request.CostoPielesTotal, 2),
                Observacion = NormalizeNullable(request.Observacion),
                Estado = nuevoEstado
            },
            cancellationToken);

        var updated = await loteRepository.FindByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<LoteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el lote actualizado.")
            : UseCaseResult<LoteDetailDto>.Ok(MapDetail(updated), "Lote actualizado correctamente.");
    }

    private async Task<(List<string> Errors, Cliente? Cliente, TipoPielLookup? TipoPiel)> ValidateRequestAsync(
        long clienteId,
        long tipoPielId,
        DateTime fechaIngreso,
        decimal cantidadPielesInicial,
        bool clienteTraeLote,
        decimal costoPielesTotal,
        Lote? existing,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        var cliente = await clienteRepository.FindByIdAsync(clienteId, cancellationToken);
        if (cliente is null)
        {
            errors.Add("No se encontro el cliente seleccionado.");
        }
        else if (!cliente.Activo)
        {
            errors.Add("El cliente seleccionado esta inactivo.");
        }

        var tipoPiel = await tipoPielLookupRepository.FindByIdAsync(tipoPielId, cancellationToken);
        if (tipoPiel is null)
        {
            errors.Add("No se encontro el tipo de piel seleccionado.");
        }
        else if (!tipoPiel.Activo)
        {
            errors.Add("El tipo de piel seleccionado esta inactivo.");
        }

        if (fechaIngreso == default)
        {
            errors.Add("La fecha de ingreso es obligatoria.");
        }

        if (cantidadPielesInicial <= 0)
        {
            errors.Add("La cantidad de pieles inicial debe ser mayor que 0.");
        }

        if (costoPielesTotal < 0)
        {
            errors.Add("El costo de pieles total no puede ser negativo.");
        }

        if (clienteTraeLote && costoPielesTotal != 0)
        {
            errors.Add("Cuando el lote es del cliente, el costo de pieles debe ser 0.00.");
        }

        if (existing is not null && existing.Estado == "ANULADO")
        {
            errors.Add("No se puede editar un lote anulado.");
        }

        return (errors, cliente, tipoPiel);
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static LoteListItemDto MapList(Lote lote) =>
        new(
            lote.Id,
            lote.Codigo,
            lote.ClienteId,
            lote.ClienteRazonSocial,
            lote.TipoPielId,
            lote.TipoPielCodigo,
            lote.TipoPielNombre,
            lote.FechaIngreso,
            lote.CantidadPielesInicial,
            lote.CantidadPielesUtilizada,
            lote.CantidadPielesDisponible,
            lote.CantidadLadosCalculada,
            lote.ClienteTraeLote,
            lote.CostoPielesTotal,
            lote.Estado,
            lote.Observacion,
            lote.CreadoEn,
            lote.CreadoPorUsuarioId);

    private static LoteDetailDto MapDetail(Lote lote) =>
        new(
            lote.Id,
            lote.Codigo,
            lote.ClienteId,
            lote.ClienteRazonSocial,
            lote.TipoPielId,
            lote.TipoPielCodigo,
            lote.TipoPielNombre,
            lote.FechaIngreso,
            lote.CantidadPielesInicial,
            lote.CantidadPielesUtilizada,
            lote.CantidadPielesDisponible,
            lote.CantidadLadosCalculada,
            lote.ClienteTraeLote,
            lote.CostoPielesTotal,
            lote.Estado,
            lote.Observacion,
            lote.CreadoEn,
            lote.CreadoPorUsuarioId);

    private static LoteDisponibilidadDto MapAvailability(Lote lote) =>
        new(
            lote.Id,
            lote.Codigo,
            lote.ClienteId,
            lote.ClienteRazonSocial,
            lote.CantidadPielesInicial,
            lote.CantidadPielesUtilizada,
            lote.CantidadPielesDisponible,
            lote.CantidadLadosCalculada,
            lote.Estado);
}
