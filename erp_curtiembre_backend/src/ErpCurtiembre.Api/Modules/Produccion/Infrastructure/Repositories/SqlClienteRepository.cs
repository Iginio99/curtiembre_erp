using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlClienteRepository(
    ISqlConnectionFactory connectionFactory,
    ProduccionDbContext dbContext) : IClienteRepository
{
    public Task<bool> ExistsByDocumentoAsync(string rucDocumento, long? excludeId, CancellationToken cancellationToken) =>
        dbContext.Clientes.AnyAsync(
            x => x.RucDocumento == rucDocumento && (!excludeId.HasValue || x.Id != excludeId.Value),
            cancellationToken);

    public async Task<Cliente?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                c.id AS Id,
                c.ruc_documento AS RucDocumento,
                c.razon_social AS RazonSocial,
                c.direccion AS Direccion,
                c.celular AS Celular,
                c.correo AS Correo,
                c.contacto AS Contacto,
                c.activo AS Activo,
                c.creado_en AS CreadoEn,
                c.actualizado_en AS ActualizadoEn
            FROM produccion.cliente c
            WHERE c.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Cliente>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(Cliente cliente, CancellationToken cancellationToken)
    {
        var entity = new ClienteWriteModel
        {
            RucDocumento = cliente.RucDocumento,
            RazonSocial = cliente.RazonSocial,
            Direccion = cliente.Direccion,
            Celular = cliente.Celular,
            Correo = cliente.Correo,
            Contacto = cliente.Contacto,
            Activo = cliente.Activo
        };

        dbContext.Clientes.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(Cliente cliente, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Clientes.SingleAsync(x => x.Id == cliente.Id, cancellationToken);
        entity.RucDocumento = cliente.RucDocumento;
        entity.RazonSocial = cliente.RazonSocial;
        entity.Direccion = cliente.Direccion;
        entity.Celular = cliente.Celular;
        entity.Correo = cliente.Correo;
        entity.Contacto = cliente.Contacto;
        entity.ActualizadoEn = cliente.ActualizadoEn;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetActiveAsync(long id, bool activo, DateTime updatedAt, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Clientes.SingleAsync(x => x.Id == id, cancellationToken);
        entity.Activo = activo;
        entity.ActualizadoEn = updatedAt;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public Task<bool> HasAnyLoteAsync(long clienteId, CancellationToken cancellationToken) =>
        dbContext.Lotes.AnyAsync(x => x.ClienteId == clienteId, cancellationToken);

    public async Task<IReadOnlyCollection<Cliente>> ListAsync(ClienteFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                c.id AS Id,
                c.ruc_documento AS RucDocumento,
                c.razon_social AS RazonSocial,
                c.direccion AS Direccion,
                c.celular AS Celular,
                c.correo AS Correo,
                c.contacto AS Contacto,
                c.activo AS Activo,
                c.creado_en AS CreadoEn,
                c.actualizado_en AS ActualizadoEn
            FROM produccion.cliente c
            WHERE (
                    @Texto IS NULL OR
                    c.ruc_documento LIKE @TextoLike OR
                    c.razon_social LIKE @TextoLike OR
                    ISNULL(c.contacto, '') LIKE @TextoLike
                )
              AND (@Activo IS NULL OR c.activo = @Activo)
            ORDER BY c.razon_social, c.ruc_documento;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Cliente>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.Activo
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<Cliente>> ListActiveAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                c.id AS Id,
                c.ruc_documento AS RucDocumento,
                c.razon_social AS RazonSocial,
                c.direccion AS Direccion,
                c.celular AS Celular,
                c.correo AS Correo,
                c.contacto AS Contacto,
                c.activo AS Activo,
                c.creado_en AS CreadoEn,
                c.actualizado_en AS ActualizadoEn
            FROM produccion.cliente c
            WHERE c.activo = 1
            ORDER BY c.razon_social, c.ruc_documento;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Cliente>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
