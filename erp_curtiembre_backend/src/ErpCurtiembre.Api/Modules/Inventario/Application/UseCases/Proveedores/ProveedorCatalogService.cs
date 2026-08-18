using System.ComponentModel.DataAnnotations;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.Proveedores;

public sealed class ProveedorCatalogService(
    IProveedorRepository proveedorRepository,
    IDateTimeProvider dateTimeProvider)
{
    private static readonly EmailAddressAttribute EmailValidator = new();

    public async Task<IReadOnlyCollection<ProveedorListItemDto>> ListAsync(
        ProveedorFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await proveedorRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<IReadOnlyCollection<ProveedorLookupDto>> ListActiveAsync(CancellationToken cancellationToken)
    {
        var items = await proveedorRepository.ListActiveAsync(cancellationToken);
        return items.Select(MapLookup).ToArray();
    }

    public async Task<UseCaseResult<ProveedorDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var proveedor = await proveedorRepository.FindByIdAsync(id, cancellationToken);
        return proveedor is null
            ? UseCaseResult<ProveedorDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el proveedor.")
            : UseCaseResult<ProveedorDetailDto>.Ok(MapDetail(proveedor));
    }

    public async Task<UseCaseResult<ProveedorDetailDto>> CreateAsync(
        CreateProveedorRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = await ValidateRequestAsync(
            request.RucDocumento,
            request.RazonSocial,
            request.Direccion,
            request.Telefono,
            request.Correo,
            request.Contacto,
            null,
            cancellationToken);

        if (errors.Count > 0)
        {
            return UseCaseResult<ProveedorDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await proveedorRepository.CreateAsync(
            new Proveedor
            {
                RucDocumento = request.RucDocumento.Trim(),
                RazonSocial = request.RazonSocial.Trim(),
                Direccion = NormalizeNullable(request.Direccion),
                Telefono = NormalizeNullable(request.Telefono),
                Correo = NormalizeNullable(request.Correo),
                Contacto = NormalizeNullable(request.Contacto),
                Activo = true
            },
            cancellationToken);

        var created = await proveedorRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<ProveedorDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se pudo recuperar el proveedor creado.")
            : UseCaseResult<ProveedorDetailDto>.Ok(MapDetail(created), "Proveedor creado correctamente.");
    }

    public async Task<UseCaseResult<ProveedorDetailDto>> UpdateAsync(
        long id,
        UpdateProveedorRequestDto request,
        CancellationToken cancellationToken)
    {
        var existing = await proveedorRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<ProveedorDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el proveedor.");
        }

        var errors = await ValidateRequestAsync(
            request.RucDocumento,
            request.RazonSocial,
            request.Direccion,
            request.Telefono,
            request.Correo,
            request.Contacto,
            id,
            cancellationToken);

        if (errors.Count > 0)
        {
            return UseCaseResult<ProveedorDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        var normalizedDocumento = request.RucDocumento.Trim();
        if (!string.Equals(existing.RucDocumento, normalizedDocumento, StringComparison.OrdinalIgnoreCase) &&
            await proveedorRepository.HasAnyOrderAsync(id, cancellationToken))
        {
            return UseCaseResult<ProveedorDetailDto>.Fail(
                InventarioErrorCodes.Validation,
                "No se puede cambiar el documento de un proveedor que ya tiene ordenes de compra.");
        }

        await proveedorRepository.UpdateAsync(
            new Proveedor
            {
                Id = id,
                RucDocumento = normalizedDocumento,
                RazonSocial = request.RazonSocial.Trim(),
                Direccion = NormalizeNullable(request.Direccion),
                Telefono = NormalizeNullable(request.Telefono),
                Correo = NormalizeNullable(request.Correo),
                Contacto = NormalizeNullable(request.Contacto),
                ActualizadoEn = dateTimeProvider.Now
            },
            cancellationToken);

        var updated = await proveedorRepository.FindByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<ProveedorDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el proveedor actualizado.")
            : UseCaseResult<ProveedorDetailDto>.Ok(MapDetail(updated), "Proveedor actualizado correctamente.");
    }

    public Task<UseCaseResult<ProveedorDetailDto>> ActivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, true, "Proveedor activado correctamente.", cancellationToken);

    public Task<UseCaseResult<ProveedorDetailDto>> InactivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, false, "Proveedor inactivado correctamente.", cancellationToken);

    private async Task<UseCaseResult<ProveedorDetailDto>> SetActiveAsync(
        long id,
        bool activo,
        string successMessage,
        CancellationToken cancellationToken)
    {
        var existing = await proveedorRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<ProveedorDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el proveedor.");
        }

        await proveedorRepository.SetActiveAsync(id, activo, dateTimeProvider.Now, cancellationToken);
        var updated = await proveedorRepository.FindByIdAsync(id, cancellationToken);

        return updated is null
            ? UseCaseResult<ProveedorDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el proveedor actualizado.")
            : UseCaseResult<ProveedorDetailDto>.Ok(MapDetail(updated), successMessage);
    }

    private async Task<IReadOnlyCollection<string>> ValidateRequestAsync(
        string rucDocumento,
        string razonSocial,
        string? direccion,
        string? telefono,
        string? correo,
        string? contacto,
        long? excludeId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var normalizedDocumento = rucDocumento.Trim();
        var normalizedRazonSocial = razonSocial.Trim();
        var normalizedDireccion = NormalizeNullable(direccion);
        var normalizedTelefono = NormalizeNullable(telefono);
        var normalizedCorreo = NormalizeNullable(correo);
        var normalizedContacto = NormalizeNullable(contacto);

        if (string.IsNullOrWhiteSpace(normalizedDocumento))
        {
            errors.Add("El documento del proveedor es obligatorio.");
        }
        else if (normalizedDocumento.Length > 20)
        {
            errors.Add("El documento del proveedor no debe superar 20 caracteres.");
        }

        if (string.IsNullOrWhiteSpace(normalizedRazonSocial))
        {
            errors.Add("La razon social es obligatoria.");
        }
        else if (normalizedRazonSocial.Length > 180)
        {
            errors.Add("La razon social no debe superar 180 caracteres.");
        }

        if (normalizedDireccion is not null && normalizedDireccion.Length > 250)
        {
            errors.Add("La direccion no debe superar 250 caracteres.");
        }

        if (normalizedTelefono is not null && normalizedTelefono.Length > 30)
        {
            errors.Add("El telefono no debe superar 30 caracteres.");
        }

        if (normalizedCorreo is not null)
        {
            if (normalizedCorreo.Length > 150)
            {
                errors.Add("El correo no debe superar 150 caracteres.");
            }
            else if (!EmailValidator.IsValid(normalizedCorreo))
            {
                errors.Add("El correo del proveedor no tiene un formato valido.");
            }
        }

        if (normalizedContacto is not null && normalizedContacto.Length > 150)
        {
            errors.Add("El contacto no debe superar 150 caracteres.");
        }

        if (errors.Count == 0 &&
            await proveedorRepository.ExistsByDocumentoAsync(normalizedDocumento, excludeId, cancellationToken))
        {
            errors.Add("El documento del proveedor ya existe.");
        }

        return errors;
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static ProveedorListItemDto MapList(Proveedor proveedor) =>
        new(
            proveedor.Id,
            proveedor.RucDocumento,
            proveedor.RazonSocial,
            proveedor.Direccion,
            proveedor.Telefono,
            proveedor.Correo,
            proveedor.Contacto,
            proveedor.Activo,
            proveedor.CreadoEn,
            proveedor.ActualizadoEn);

    private static ProveedorDetailDto MapDetail(Proveedor proveedor) =>
        new(
            proveedor.Id,
            proveedor.RucDocumento,
            proveedor.RazonSocial,
            proveedor.Direccion,
            proveedor.Telefono,
            proveedor.Correo,
            proveedor.Contacto,
            proveedor.Activo,
            proveedor.CreadoEn,
            proveedor.ActualizadoEn);

    private static ProveedorLookupDto MapLookup(Proveedor proveedor) =>
        new(proveedor.Id, proveedor.RucDocumento, proveedor.RazonSocial);
}
