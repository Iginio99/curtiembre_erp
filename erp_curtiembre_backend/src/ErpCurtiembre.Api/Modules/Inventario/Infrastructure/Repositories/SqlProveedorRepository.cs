using Dapper;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Repositories;

public sealed class SqlProveedorRepository(
    ISqlConnectionFactory connectionFactory,
    InventarioDbContext dbContext) : IProveedorRepository
{
    public async Task<bool> ExistsByDocumentoAsync(string rucDocumento, long? excludeId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM inventario.proveedor
                WHERE ruc_documento = @RucDocumento
                  AND (@ExcludeId IS NULL OR id <> @ExcludeId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { RucDocumento = rucDocumento, ExcludeId = excludeId }, cancellationToken: cancellationToken));
    }

    public async Task<bool> HasAnyOrderAsync(long proveedorId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM inventario.orden_compra
                WHERE proveedor_id = @ProveedorId
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { ProveedorId = proveedorId }, cancellationToken: cancellationToken));
    }

    public async Task<Proveedor?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                id AS Id,
                ruc_documento AS RucDocumento,
                razon_social AS RazonSocial,
                direccion AS Direccion,
                telefono AS Telefono,
                correo AS Correo,
                contacto AS Contacto,
                activo AS Activo,
                creado_en AS CreadoEn,
                actualizado_en AS ActualizadoEn
            FROM inventario.proveedor
            WHERE id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Proveedor>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(Proveedor proveedor, CancellationToken cancellationToken)
    {
        var entity = new ProveedorWriteModel
        {
            RucDocumento = proveedor.RucDocumento,
            RazonSocial = proveedor.RazonSocial,
            Direccion = proveedor.Direccion,
            Telefono = proveedor.Telefono,
            Correo = proveedor.Correo,
            Contacto = proveedor.Contacto,
            Activo = proveedor.Activo
        };

        dbContext.Proveedores.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(Proveedor proveedor, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Proveedores.SingleOrDefaultAsync(x => x.Id == proveedor.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.RucDocumento = proveedor.RucDocumento;
        entity.RazonSocial = proveedor.RazonSocial;
        entity.Direccion = proveedor.Direccion;
        entity.Telefono = proveedor.Telefono;
        entity.Correo = proveedor.Correo;
        entity.Contacto = proveedor.Contacto;
        entity.ActualizadoEn = proveedor.ActualizadoEn;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetActiveAsync(long id, bool activo, DateTime updatedAt, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Proveedores.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activo = activo;
        entity.ActualizadoEn = updatedAt;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<Proveedor>> ListAsync(ProveedorFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                ruc_documento AS RucDocumento,
                razon_social AS RazonSocial,
                direccion AS Direccion,
                telefono AS Telefono,
                correo AS Correo,
                contacto AS Contacto,
                activo AS Activo,
                creado_en AS CreadoEn,
                actualizado_en AS ActualizadoEn
            FROM inventario.proveedor
            WHERE (
                    @Texto IS NULL OR
                    ruc_documento LIKE @TextoLike OR
                    razon_social LIKE @TextoLike OR
                    contacto LIKE @TextoLike
                )
              AND (@Activo IS NULL OR activo = @Activo)
            ORDER BY razon_social, ruc_documento;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Proveedor>(
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

    public async Task<IReadOnlyCollection<Proveedor>> ListActiveAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                ruc_documento AS RucDocumento,
                razon_social AS RazonSocial,
                direccion AS Direccion,
                telefono AS Telefono,
                correo AS Correo,
                contacto AS Contacto,
                activo AS Activo,
                creado_en AS CreadoEn,
                actualizado_en AS ActualizadoEn
            FROM inventario.proveedor
            WHERE activo = 1
            ORDER BY razon_social, ruc_documento;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Proveedor>(new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }
}
