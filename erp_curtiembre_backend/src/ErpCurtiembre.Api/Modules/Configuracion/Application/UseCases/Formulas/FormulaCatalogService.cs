using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Application.Support;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.UseCases.Formulas;

public sealed class FormulaCatalogService(IFormulaRepository formulaRepository)
{
    public async Task<IReadOnlyCollection<FormulaListItemDto>> ListAsync(FormulaFiltersDto filters, CancellationToken cancellationToken)
    {
        var items = await formulaRepository.ListFormulasAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<FormulaDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var formula = await formulaRepository.FindFormulaByIdAsync(id, cancellationToken);
        return formula is null
            ? UseCaseResult<FormulaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la formula.")
            : UseCaseResult<FormulaDetailDto>.Ok(MapDetail(formula));
    }

    public async Task<UseCaseResult<FormulaDetailDto>> CreateAsync(
        CreateFormulaRequestDto request,
        long actorUserId,
        CancellationToken cancellationToken)
    {
        var errors = await ValidateFormulaRequestAsync(
            request.Codigo,
            request.Nombre,
            request.ProcesoProductivoId,
            request.Descripcion,
            null,
            cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<FormulaDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await formulaRepository.CreateFormulaAsync(
            new Formula
            {
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                ProcesoProductivoId = request.ProcesoProductivoId,
                Descripcion = NormalizeNullable(request.Descripcion),
                Activo = true
            },
            actorUserId,
            cancellationToken);

        var created = await formulaRepository.FindFormulaByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<FormulaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se pudo recuperar la formula creada.")
            : UseCaseResult<FormulaDetailDto>.Ok(MapDetail(created), "Formula creada correctamente.");
    }

    public async Task<UseCaseResult<FormulaDetailDto>> UpdateAsync(
        long id,
        UpdateFormulaRequestDto request,
        CancellationToken cancellationToken)
    {
        var existing = await formulaRepository.FindFormulaByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<FormulaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la formula.");
        }

        var errors = await ValidateFormulaRequestAsync(
            request.Codigo,
            request.Nombre,
            request.ProcesoProductivoId,
            request.Descripcion,
            id,
            cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<FormulaDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        await formulaRepository.UpdateFormulaAsync(
            new Formula
            {
                Id = id,
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                ProcesoProductivoId = request.ProcesoProductivoId,
                Descripcion = NormalizeNullable(request.Descripcion)
            },
            cancellationToken);

        var updated = await formulaRepository.FindFormulaByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<FormulaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la formula actualizada.")
            : UseCaseResult<FormulaDetailDto>.Ok(MapDetail(updated), "Formula actualizada correctamente.");
    }

    public Task<UseCaseResult<FormulaDetailDto>> ActivateAsync(long id, CancellationToken cancellationToken) =>
        SetFormulaActiveAsync(id, true, "Formula activada correctamente.", cancellationToken);

    public Task<UseCaseResult<FormulaDetailDto>> InactivateAsync(long id, CancellationToken cancellationToken) =>
        SetFormulaActiveAsync(id, false, "Formula inactivada correctamente.", cancellationToken);

    public async Task<IReadOnlyCollection<FormulaVersionListItemDto>> ListVersionsAsync(long formulaId, CancellationToken cancellationToken)
    {
        var versions = await formulaRepository.ListVersionsAsync(formulaId, cancellationToken);
        var detailCounts = await Task.WhenAll(versions.Select(async version =>
            new
            {
                version.Id,
                Count = (await formulaRepository.ListDetailsByVersionIdAsync(version.Id, cancellationToken)).Count(x => x.Activo)
            }));

        var detailCountMap = detailCounts.ToDictionary(x => x.Id, x => x.Count);
        return versions.Select(version => MapVersionList(version, detailCountMap.GetValueOrDefault(version.Id))).ToArray();
    }

    public async Task<UseCaseResult<FormulaVersionDetailDto>> GetVersionByIdAsync(long id, CancellationToken cancellationToken)
    {
        var version = await formulaRepository.FindVersionByIdAsync(id, cancellationToken);
        if (version is null)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la version de formula.");
        }

        var details = await formulaRepository.ListDetailsByVersionIdAsync(id, cancellationToken);
        return UseCaseResult<FormulaVersionDetailDto>.Ok(MapVersionDetail(version, details));
    }

    public async Task<UseCaseResult<FormulaVersionDetailDto>> CreateVersionAsync(
        long formulaId,
        CreateFormulaVersionRequestDto request,
        long actorUserId,
        CancellationToken cancellationToken)
    {
        var formula = await formulaRepository.FindFormulaByIdAsync(formulaId, cancellationToken);
        if (formula is null)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la formula.");
        }

        if (!formula.Activo)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(ConfiguracionErrorCodes.Conflict, "No se puede versionar una formula inactiva.");
        }

        var errors = await ValidateVersionRequestAsync(
            formulaId,
            request.NumeroVersion,
            request.FechaInicioVigencia,
            request.FechaFinVigencia,
            request.Observacion,
            null,
            cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        FormulaVersion? sourceVersion = null;
        if (request.ClonarDesdeVersionId is not null)
        {
            sourceVersion = await formulaRepository.FindVersionByIdAsync(request.ClonarDesdeVersionId.Value, cancellationToken);
            if (sourceVersion is null || sourceVersion.FormulaId != formulaId)
            {
                return UseCaseResult<FormulaVersionDetailDto>.Fail(
                    ConfiguracionErrorCodes.Validation,
                    "La version origen a clonar no pertenece a la formula seleccionada.");
            }
        }

        var versionId = await formulaRepository.CreateVersionAsync(
            new FormulaVersion
            {
                FormulaId = formulaId,
                NumeroVersion = request.NumeroVersion,
                FechaInicioVigencia = request.FechaInicioVigencia.Date,
                FechaFinVigencia = request.FechaFinVigencia?.Date,
                Vigente = false,
                Observacion = NormalizeNullable(request.Observacion)
            },
            actorUserId,
            cancellationToken);

        if (sourceVersion is not null)
        {
            await formulaRepository.CloneActiveDetailsAsync(sourceVersion.Id, versionId, cancellationToken);
        }

        return await GetVersionByIdAsync(versionId, cancellationToken) with
        {
            Message = "Version de formula creada correctamente."
        };
    }

    public async Task<UseCaseResult<FormulaVersionDetailDto>> UpdateVersionAsync(
        long id,
        UpdateFormulaVersionRequestDto request,
        CancellationToken cancellationToken)
    {
        var version = await formulaRepository.FindVersionByIdAsync(id, cancellationToken);
        if (version is null)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la version de formula.");
        }

        if (version.Vigente)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(
                ConfiguracionErrorCodes.Conflict,
                "No se puede editar una version vigente. Crea una nueva version o cambia la vigencia.");
        }

        var errors = await ValidateVersionRequestAsync(
            version.FormulaId,
            version.NumeroVersion,
            request.FechaInicioVigencia,
            request.FechaFinVigencia,
            request.Observacion,
            id,
            cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        await formulaRepository.UpdateVersionAsync(
            new FormulaVersion
            {
                Id = id,
                FormulaId = version.FormulaId,
                NumeroVersion = version.NumeroVersion,
                FechaInicioVigencia = request.FechaInicioVigencia.Date,
                FechaFinVigencia = request.FechaFinVigencia?.Date,
                Observacion = NormalizeNullable(request.Observacion)
            },
            cancellationToken);

        var updated = await GetVersionByIdAsync(id, cancellationToken);
        return updated.Success
            ? updated with { Message = "Version de formula actualizada correctamente." }
            : updated;
    }

    public async Task<UseCaseResult<FormulaVersionDetailDto>> ActivateVersionAsync(long id, CancellationToken cancellationToken)
    {
        var version = await formulaRepository.FindVersionByIdAsync(id, cancellationToken);
        if (version is null)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la version de formula.");
        }

        var formula = await formulaRepository.FindFormulaByIdAsync(version.FormulaId, cancellationToken);
        if (formula is null)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la formula.");
        }

        if (!formula.Activo)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(
                ConfiguracionErrorCodes.Conflict,
                "No se puede activar vigencia sobre una formula inactiva.");
        }

        if (!await formulaRepository.VersionHasActiveDetailsAsync(id, cancellationToken))
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(
                ConfiguracionErrorCodes.Conflict,
                "No se puede activar la version porque no tiene detalles activos.");
        }

        var overlap = await formulaRepository.HasVersionDateOverlapAsync(
            version.FormulaId,
            version.FechaInicioVigencia,
            version.FechaFinVigencia,
            id,
            cancellationToken);
        if (overlap)
        {
            return UseCaseResult<FormulaVersionDetailDto>.Fail(
                ConfiguracionErrorCodes.Conflict,
                "La version se superpone en vigencia con otra version de la misma formula.");
        }

        await formulaRepository.SetVersionVigenteAsync(version.FormulaId, id, cancellationToken);
        var activated = await GetVersionByIdAsync(id, cancellationToken);
        return activated.Success
            ? activated with { Message = "Version vigente actualizada correctamente." }
            : activated;
    }

    public async Task<UseCaseResult<FormulaDetalleItemDto>> CreateDetailAsync(
        long versionId,
        CreateFormulaDetalleRequestDto request,
        CancellationToken cancellationToken)
    {
        var version = await formulaRepository.FindVersionByIdAsync(versionId, cancellationToken);
        if (version is null)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la version de formula.");
        }

        if (version.Vigente)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(
                ConfiguracionErrorCodes.Conflict,
                "No se puede modificar el detalle de una version vigente.");
        }

        var errors = await ValidateDetailRequestAsync(versionId, request.InsumoId, request.Porcentaje, request.Observacion, null, cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await formulaRepository.CreateDetailAsync(
            new FormulaDetalle
            {
                FormulaVersionId = versionId,
                InsumoId = request.InsumoId,
                Porcentaje = request.Porcentaje,
                Observacion = NormalizeNullable(request.Observacion),
                Activo = true
            },
            cancellationToken);

        var created = await formulaRepository.FindDetailByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se pudo recuperar el detalle creado.")
            : UseCaseResult<FormulaDetalleItemDto>.Ok(MapDetailItem(created), "Detalle agregado correctamente.");
    }

    public async Task<UseCaseResult<FormulaDetalleItemDto>> UpdateDetailAsync(
        long id,
        UpdateFormulaDetalleRequestDto request,
        CancellationToken cancellationToken)
    {
        var detail = await formulaRepository.FindDetailByIdAsync(id, cancellationToken);
        if (detail is null)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el detalle de formula.");
        }

        var version = await formulaRepository.FindVersionByIdAsync(detail.FormulaVersionId, cancellationToken);
        if (version is null)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la version de formula.");
        }

        if (version.Vigente)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(
                ConfiguracionErrorCodes.Conflict,
                "No se puede modificar el detalle de una version vigente.");
        }

        var errors = await ValidateDetailRequestAsync(
            detail.FormulaVersionId,
            request.InsumoId,
            request.Porcentaje,
            request.Observacion,
            id,
            cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        await formulaRepository.UpdateDetailAsync(
            new FormulaDetalle
            {
                Id = id,
                FormulaVersionId = detail.FormulaVersionId,
                InsumoId = request.InsumoId,
                Porcentaje = request.Porcentaje,
                Observacion = NormalizeNullable(request.Observacion),
                Activo = request.Activo
            },
            cancellationToken);

        var updated = await formulaRepository.FindDetailByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el detalle actualizado.")
            : UseCaseResult<FormulaDetalleItemDto>.Ok(MapDetailItem(updated), "Detalle actualizado correctamente.");
    }

    public async Task<UseCaseResult<FormulaDetalleItemDto>> DeleteDetailAsync(long id, CancellationToken cancellationToken)
    {
        var detail = await formulaRepository.FindDetailByIdAsync(id, cancellationToken);
        if (detail is null)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el detalle de formula.");
        }

        var version = await formulaRepository.FindVersionByIdAsync(detail.FormulaVersionId, cancellationToken);
        if (version is null)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la version de formula.");
        }

        if (version.Vigente)
        {
            return UseCaseResult<FormulaDetalleItemDto>.Fail(
                ConfiguracionErrorCodes.Conflict,
                "No se puede eliminar detalle de una version vigente.");
        }

        await formulaRepository.SoftDeleteDetailAsync(id, cancellationToken);
        var deleted = await formulaRepository.FindDetailByIdAsync(id, cancellationToken);
        return deleted is null
            ? UseCaseResult<FormulaDetalleItemDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el detalle eliminado.")
            : UseCaseResult<FormulaDetalleItemDto>.Ok(MapDetailItem(deleted), "Detalle inactivado correctamente.");
    }

    private async Task<UseCaseResult<FormulaDetailDto>> SetFormulaActiveAsync(
        long id,
        bool activo,
        string successMessage,
        CancellationToken cancellationToken)
    {
        var formula = await formulaRepository.FindFormulaByIdAsync(id, cancellationToken);
        if (formula is null)
        {
            return UseCaseResult<FormulaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la formula.");
        }

        if (!activo && await formulaRepository.HasAnyVigenteVersionAsync(id, cancellationToken))
        {
            return UseCaseResult<FormulaDetailDto>.Fail(
                ConfiguracionErrorCodes.Conflict,
                "No se puede inactivar la formula mientras tenga una version vigente.");
        }

        await formulaRepository.SetFormulaActiveAsync(id, activo, cancellationToken);
        var updated = await formulaRepository.FindFormulaByIdAsync(id, cancellationToken);

        return updated is null
            ? UseCaseResult<FormulaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la formula actualizada.")
            : UseCaseResult<FormulaDetailDto>.Ok(MapDetail(updated), successMessage);
    }

    private async Task<IReadOnlyCollection<string>> ValidateFormulaRequestAsync(
        string codigo,
        string nombre,
        long procesoProductivoId,
        string? descripcion,
        long? excludeId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var normalizedCodigo = codigo.Trim();
        var normalizedNombre = nombre.Trim();
        var normalizedDescripcion = NormalizeNullable(descripcion);

        if (string.IsNullOrWhiteSpace(normalizedCodigo))
        {
            errors.Add("El codigo es obligatorio.");
        }
        else if (normalizedCodigo.Length > 50)
        {
            errors.Add("El codigo no debe superar 50 caracteres.");
        }

        if (string.IsNullOrWhiteSpace(normalizedNombre))
        {
            errors.Add("El nombre es obligatorio.");
        }
        else if (normalizedNombre.Length > 150)
        {
            errors.Add("El nombre no debe superar 150 caracteres.");
        }

        if (procesoProductivoId <= 0)
        {
            errors.Add("El proceso productivo es obligatorio.");
        }

        if (normalizedDescripcion is not null && normalizedDescripcion.Length > 500)
        {
            errors.Add("La descripcion no debe superar 500 caracteres.");
        }

        if (errors.Count == 0 &&
            await formulaRepository.ExistsFormulaByCodigoAsync(normalizedCodigo, excludeId, cancellationToken))
        {
            errors.Add("El codigo de la formula ya existe.");
        }

        if (errors.Count == 0 &&
            !await formulaRepository.IsProcesoProductivoActiveAsync(procesoProductivoId, cancellationToken))
        {
            errors.Add("El proceso productivo no existe o esta inactivo.");
        }

        return errors;
    }

    private async Task<IReadOnlyCollection<string>> ValidateVersionRequestAsync(
        long formulaId,
        int numeroVersion,
        DateTime fechaInicioVigencia,
        DateTime? fechaFinVigencia,
        string? observacion,
        long? excludeId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var normalizedObservacion = NormalizeNullable(observacion);

        if (numeroVersion <= 0)
        {
            errors.Add("El numero de version debe ser mayor a cero.");
        }

        if (fechaInicioVigencia == default)
        {
            errors.Add("La fecha de inicio de vigencia es obligatoria.");
        }

        if (fechaFinVigencia is not null && fechaFinVigencia.Value.Date < fechaInicioVigencia.Date)
        {
            errors.Add("La fecha fin de vigencia no puede ser menor que la fecha inicio.");
        }

        if (normalizedObservacion is not null && normalizedObservacion.Length > 500)
        {
            errors.Add("La observacion no debe superar 500 caracteres.");
        }

        if (errors.Count == 0 &&
            await formulaRepository.ExistsVersionNumberAsync(formulaId, numeroVersion, excludeId, cancellationToken))
        {
            errors.Add("El numero de version ya existe para esta formula.");
        }

        if (errors.Count == 0 &&
            await formulaRepository.HasVersionDateOverlapAsync(
                formulaId,
                fechaInicioVigencia.Date,
                fechaFinVigencia?.Date,
                excludeId,
                cancellationToken))
        {
            errors.Add("La vigencia de la version se superpone con otra version de la misma formula.");
        }

        return errors;
    }

    private async Task<IReadOnlyCollection<string>> ValidateDetailRequestAsync(
        long versionId,
        long insumoId,
        decimal porcentaje,
        string? observacion,
        long? excludeId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var normalizedObservacion = NormalizeNullable(observacion);

        if (insumoId <= 0)
        {
            errors.Add("El insumo es obligatorio.");
        }

        if (porcentaje <= 0)
        {
            errors.Add("El porcentaje debe ser mayor a cero.");
        }

        if (normalizedObservacion is not null && normalizedObservacion.Length > 300)
        {
            errors.Add("La observacion no debe superar 300 caracteres.");
        }

        if (errors.Count == 0 &&
            !await formulaRepository.IsInsumoActiveAsync(insumoId, cancellationToken))
        {
            errors.Add("El insumo no existe o esta inactivo.");
        }

        if (errors.Count == 0 &&
            await formulaRepository.ExistsActiveDetailInsumoAsync(versionId, insumoId, excludeId, cancellationToken))
        {
            errors.Add("El insumo ya existe en el detalle activo de esta version.");
        }

        return errors;
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static FormulaVersionSummaryDto? MapVersionSummary(Formula formula) =>
        formula.VersionVigenteId is null || formula.VersionVigenteNumero is null || formula.VersionVigenteFechaInicio is null
            ? null
            : new FormulaVersionSummaryDto(
                formula.VersionVigenteId.Value,
                formula.VersionVigenteNumero.Value,
                formula.VersionVigenteFechaInicio.Value,
                formula.VersionVigenteFechaFin,
                formula.VersionVigente ?? true);

    private static FormulaListItemDto MapList(Formula formula) =>
        new(
            formula.Id,
            formula.Codigo,
            formula.Nombre,
            formula.ProcesoProductivoId,
            formula.ProcesoProductivoCodigo,
            formula.ProcesoProductivoNombre,
            formula.Descripcion,
            formula.Activo,
            formula.CreadoEn,
            MapVersionSummary(formula));

    private static FormulaDetailDto MapDetail(Formula formula) =>
        new(
            formula.Id,
            formula.Codigo,
            formula.Nombre,
            formula.ProcesoProductivoId,
            formula.ProcesoProductivoCodigo,
            formula.ProcesoProductivoNombre,
            formula.Descripcion,
            formula.Activo,
            formula.CreadoEn,
            formula.CreadoPorUsuarioId,
            MapVersionSummary(formula));

    private static FormulaVersionListItemDto MapVersionList(FormulaVersion version, int activeDetails) =>
        new(
            version.Id,
            version.FormulaId,
            version.FormulaCodigo,
            version.FormulaNombre,
            version.NumeroVersion,
            version.FechaInicioVigencia,
            version.FechaFinVigencia,
            version.Vigente,
            version.Observacion,
            version.CreadoEn,
            version.CreadoPorUsuarioId,
            activeDetails);

    private static FormulaVersionDetailDto MapVersionDetail(
        FormulaVersion version,
        IReadOnlyCollection<FormulaDetalle> details) =>
        new(
            version.Id,
            version.FormulaId,
            version.FormulaCodigo,
            version.FormulaNombre,
            version.NumeroVersion,
            version.FechaInicioVigencia,
            version.FechaFinVigencia,
            version.Vigente,
            version.Observacion,
            version.CreadoEn,
            version.CreadoPorUsuarioId,
            details.Select(MapDetailItem).ToArray());

    private static FormulaDetalleItemDto MapDetailItem(FormulaDetalle detail) =>
        new(
            detail.Id,
            detail.FormulaVersionId,
            detail.InsumoId,
            detail.InsumoCodigo,
            detail.InsumoNombre,
            detail.Porcentaje,
            detail.Observacion,
            detail.Activo);
}
