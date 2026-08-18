using System.ComponentModel.DataAnnotations;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Clientes;

public sealed class ClienteCatalogService(
    IClienteRepository clienteRepository,
    IDateTimeProvider dateTimeProvider)
{
    private static readonly EmailAddressAttribute EmailValidator = new();

    public async Task<IReadOnlyCollection<ClienteListItemDto>> ListAsync(
        ClienteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await clienteRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<IReadOnlyCollection<ClienteLookupDto>> ListActiveAsync(CancellationToken cancellationToken)
    {
        var items = await clienteRepository.ListActiveAsync(cancellationToken);
        return items.Select(MapLookup).ToArray();
    }

    public async Task<UseCaseResult<ClienteDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var cliente = await clienteRepository.FindByIdAsync(id, cancellationToken);
        return cliente is null
            ? UseCaseResult<ClienteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el cliente.")
            : UseCaseResult<ClienteDetailDto>.Ok(MapDetail(cliente));
    }

    public async Task<UseCaseResult<ClienteDetailDto>> CreateAsync(
        CreateClienteRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = await ValidateRequestAsync(
            request.RucDocumento,
            request.RazonSocial,
            request.Direccion,
            request.Celular,
            request.Correo,
            request.Contacto,
            null,
            cancellationToken);

        if (errors.Count > 0)
        {
            return UseCaseResult<ClienteDetailDto>.Fail(ProduccionErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await clienteRepository.CreateAsync(
            new Cliente
            {
                RucDocumento = request.RucDocumento.Trim(),
                RazonSocial = request.RazonSocial.Trim(),
                Direccion = NormalizeNullable(request.Direccion),
                Celular = NormalizeNullable(request.Celular),
                Correo = NormalizeNullable(request.Correo),
                Contacto = NormalizeNullable(request.Contacto),
                Activo = true
            },
            cancellationToken);

        var created = await clienteRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<ClienteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se pudo recuperar el cliente creado.")
            : UseCaseResult<ClienteDetailDto>.Ok(MapDetail(created), "Cliente creado correctamente.");
    }

    public async Task<UseCaseResult<ClienteDetailDto>> UpdateAsync(
        long id,
        UpdateClienteRequestDto request,
        CancellationToken cancellationToken)
    {
        var existing = await clienteRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<ClienteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el cliente.");
        }

        var errors = await ValidateRequestAsync(
            request.RucDocumento,
            request.RazonSocial,
            request.Direccion,
            request.Celular,
            request.Correo,
            request.Contacto,
            id,
            cancellationToken);

        if (errors.Count > 0)
        {
            return UseCaseResult<ClienteDetailDto>.Fail(ProduccionErrorCodes.Validation, string.Join(" ", errors));
        }

        var normalizedDocumento = request.RucDocumento.Trim();
        if (!string.Equals(existing.RucDocumento, normalizedDocumento, StringComparison.OrdinalIgnoreCase) &&
            await clienteRepository.HasAnyLoteAsync(id, cancellationToken))
        {
            return UseCaseResult<ClienteDetailDto>.Fail(
                ProduccionErrorCodes.Validation,
                "No se puede cambiar el documento de un cliente que ya tiene lotes registrados.");
        }

        await clienteRepository.UpdateAsync(
            new Cliente
            {
                Id = id,
                RucDocumento = normalizedDocumento,
                RazonSocial = request.RazonSocial.Trim(),
                Direccion = NormalizeNullable(request.Direccion),
                Celular = NormalizeNullable(request.Celular),
                Correo = NormalizeNullable(request.Correo),
                Contacto = NormalizeNullable(request.Contacto),
                ActualizadoEn = dateTimeProvider.Now
            },
            cancellationToken);

        var updated = await clienteRepository.FindByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<ClienteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el cliente actualizado.")
            : UseCaseResult<ClienteDetailDto>.Ok(MapDetail(updated), "Cliente actualizado correctamente.");
    }

    public Task<UseCaseResult<ClienteDetailDto>> ActivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, true, "Cliente activado correctamente.", cancellationToken);

    public Task<UseCaseResult<ClienteDetailDto>> InactivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, false, "Cliente inactivado correctamente.", cancellationToken);

    private async Task<UseCaseResult<ClienteDetailDto>> SetActiveAsync(
        long id,
        bool activo,
        string successMessage,
        CancellationToken cancellationToken)
    {
        var existing = await clienteRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<ClienteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el cliente.");
        }

        await clienteRepository.SetActiveAsync(id, activo, dateTimeProvider.Now, cancellationToken);
        var updated = await clienteRepository.FindByIdAsync(id, cancellationToken);

        return updated is null
            ? UseCaseResult<ClienteDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el cliente actualizado.")
            : UseCaseResult<ClienteDetailDto>.Ok(MapDetail(updated), successMessage);
    }

    private async Task<IReadOnlyCollection<string>> ValidateRequestAsync(
        string rucDocumento,
        string razonSocial,
        string? direccion,
        string? celular,
        string? correo,
        string? contacto,
        long? excludeId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var normalizedDocumento = rucDocumento.Trim();
        var normalizedRazonSocial = razonSocial.Trim();
        var normalizedDireccion = NormalizeNullable(direccion);
        var normalizedCelular = NormalizeNullable(celular);
        var normalizedCorreo = NormalizeNullable(correo);
        var normalizedContacto = NormalizeNullable(contacto);

        if (string.IsNullOrWhiteSpace(normalizedDocumento))
        {
            errors.Add("El documento del cliente es obligatorio.");
        }
        else if (normalizedDocumento.Length > 20)
        {
            errors.Add("El documento del cliente no debe superar 20 caracteres.");
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

        if (normalizedCelular is not null && normalizedCelular.Length > 30)
        {
            errors.Add("El celular no debe superar 30 caracteres.");
        }

        if (normalizedCorreo is not null)
        {
            if (normalizedCorreo.Length > 150)
            {
                errors.Add("El correo no debe superar 150 caracteres.");
            }
            else if (!EmailValidator.IsValid(normalizedCorreo))
            {
                errors.Add("El correo del cliente no tiene un formato valido.");
            }
        }

        if (normalizedContacto is not null && normalizedContacto.Length > 150)
        {
            errors.Add("El contacto no debe superar 150 caracteres.");
        }

        if (errors.Count == 0 &&
            await clienteRepository.ExistsByDocumentoAsync(normalizedDocumento, excludeId, cancellationToken))
        {
            errors.Add("El documento del cliente ya existe.");
        }

        return errors;
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static ClienteListItemDto MapList(Cliente cliente) =>
        new(
            cliente.Id,
            cliente.RucDocumento,
            cliente.RazonSocial,
            cliente.Direccion,
            cliente.Celular,
            cliente.Correo,
            cliente.Contacto,
            cliente.Activo,
            cliente.CreadoEn,
            cliente.ActualizadoEn);

    private static ClienteDetailDto MapDetail(Cliente cliente) =>
        new(
            cliente.Id,
            cliente.RucDocumento,
            cliente.RazonSocial,
            cliente.Direccion,
            cliente.Celular,
            cliente.Correo,
            cliente.Contacto,
            cliente.Activo,
            cliente.CreadoEn,
            cliente.ActualizadoEn);

    private static ClienteLookupDto MapLookup(Cliente cliente) =>
        new(cliente.Id, cliente.RucDocumento, cliente.RazonSocial);
}
