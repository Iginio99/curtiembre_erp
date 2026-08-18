using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.ManoObra;

public sealed class ManoObraDirectaService(
    IManoObraDirectaRepository manoObraDirectaRepository,
    IProduccionFinanceLookupRepository produccionFinanceLookupRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<ManoObraDirectaListItemDto>> ListAsync(
        ManoObraDirectaFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await manoObraDirectaRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<ManoObraDirectaDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var item = await manoObraDirectaRepository.FindByIdAsync(id, cancellationToken);
        return item is null
            ? UseCaseResult<ManoObraDirectaDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el registro de mano de obra.")
            : UseCaseResult<ManoObraDirectaDetailDto>.Ok(MapDetail(item));
    }

    public async Task<UseCaseResult<ManoObraDirectaDetailDto>> CreateAsync(
        long actorId,
        CreateManoObraDirectaRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var proceso = await produccionFinanceLookupRepository.FindProcessAsync(request.OrdenProcesoId, cancellationToken);
        if (proceso is null)
        {
            errors.Add("El proceso productivo de la orden no existe.");
        }
        else
        {
            if (proceso.OrdenProduccionId != request.OrdenProduccionId)
            {
                errors.Add("El proceso indicado no pertenece a la orden de produccion enviada.");
            }

            if (proceso.OrdenEstado == "ANULADA")
            {
                errors.Add("No se puede registrar mano de obra sobre una orden anulada.");
            }
        }

        if (request.Monto < 0)
        {
            errors.Add("El monto no puede ser negativo.");
        }

        var descripcion = NormalizeNullable(request.Descripcion);
        if (descripcion is not null && descripcion.Length > 300)
        {
            errors.Add("La descripcion no debe superar 300 caracteres.");
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<ManoObraDirectaDetailDto>.Fail(FinanzasErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await manoObraDirectaRepository.CreateAsync(
            new ManoObraDirecta
            {
                OrdenProduccionId = request.OrdenProduccionId,
                OrdenProcesoId = request.OrdenProcesoId,
                Monto = request.Monto,
                Descripcion = descripcion,
                RegistradoEn = dateTimeProvider.Now,
                RegistradoPorUsuarioId = actorId
            },
            cancellationToken);

        var created = await manoObraDirectaRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<ManoObraDirectaDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar el registro creado.")
            : UseCaseResult<ManoObraDirectaDetailDto>.Ok(MapDetail(created), "Mano de obra directa registrada correctamente.");
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static ManoObraDirectaListItemDto MapList(ManoObraDirecta item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProduccionCodigo,
            item.OrdenProcesoId,
            item.ProcesoCodigo,
            item.ProcesoNombre,
            item.Monto,
            item.Descripcion,
            item.RegistradoEn,
            item.RegistradoPorUsuarioId);

    private static ManoObraDirectaDetailDto MapDetail(ManoObraDirecta item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProduccionCodigo,
            item.OrdenProcesoId,
            item.ProcesoCodigo,
            item.ProcesoNombre,
            item.Monto,
            item.Descripcion,
            item.RegistradoEn,
            item.RegistradoPorUsuarioId);
}
