using Dapper;
using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Repositories;

public sealed class SqlFormulaRepository(
    ISqlConnectionFactory connectionFactory,
    ConfiguracionDbContext dbContext) : IFormulaRepository
{
    public async Task<bool> ExistsFormulaByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.formula
                WHERE codigo = @Codigo
                  AND (@ExcludeId IS NULL OR id <> @ExcludeId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { Codigo = codigo, ExcludeId = excludeId }, cancellationToken: cancellationToken));
    }

    public async Task<Formula?> FindFormulaByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                f.id AS Id,
                f.codigo AS Codigo,
                f.nombre AS Nombre,
                f.proceso_productivo_id AS ProcesoProductivoId,
                pp.codigo AS ProcesoProductivoCodigo,
                pp.nombre AS ProcesoProductivoNombre,
                f.descripcion AS Descripcion,
                f.activo AS Activo,
                f.creado_en AS CreadoEn,
                f.creado_por_usuario_id AS CreadoPorUsuarioId,
                vv.id AS VersionVigenteId,
                vv.numero_version AS VersionVigenteNumero,
                vv.fecha_inicio_vigencia AS VersionVigenteFechaInicio,
                vv.fecha_fin_vigencia AS VersionVigenteFechaFin,
                vv.vigente AS VersionVigente
            FROM configuracion.formula f
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = f.proceso_productivo_id
            OUTER APPLY (
                SELECT TOP 1
                    fv.id,
                    fv.numero_version,
                    fv.fecha_inicio_vigencia,
                    fv.fecha_fin_vigencia,
                    fv.vigente
                FROM configuracion.formula_version fv
                WHERE fv.formula_id = f.id
                  AND fv.vigente = 1
                ORDER BY fv.fecha_inicio_vigencia DESC, fv.numero_version DESC, fv.id DESC
            ) vv
            WHERE f.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Formula>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<Formula>> ListFormulasAsync(FormulaFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                f.id AS Id,
                f.codigo AS Codigo,
                f.nombre AS Nombre,
                f.proceso_productivo_id AS ProcesoProductivoId,
                pp.codigo AS ProcesoProductivoCodigo,
                pp.nombre AS ProcesoProductivoNombre,
                f.descripcion AS Descripcion,
                f.activo AS Activo,
                f.creado_en AS CreadoEn,
                f.creado_por_usuario_id AS CreadoPorUsuarioId,
                vv.id AS VersionVigenteId,
                vv.numero_version AS VersionVigenteNumero,
                vv.fecha_inicio_vigencia AS VersionVigenteFechaInicio,
                vv.fecha_fin_vigencia AS VersionVigenteFechaFin,
                vv.vigente AS VersionVigente
            FROM configuracion.formula f
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = f.proceso_productivo_id
            OUTER APPLY (
                SELECT TOP 1
                    fv.id,
                    fv.numero_version,
                    fv.fecha_inicio_vigencia,
                    fv.fecha_fin_vigencia,
                    fv.vigente
                FROM configuracion.formula_version fv
                WHERE fv.formula_id = f.id
                  AND fv.vigente = 1
                ORDER BY fv.fecha_inicio_vigencia DESC, fv.numero_version DESC, fv.id DESC
            ) vv
            WHERE (
                    @Texto IS NULL OR
                    f.codigo LIKE @TextoLike OR
                    f.nombre LIKE @TextoLike OR
                    f.descripcion LIKE @TextoLike
                  )
              AND (@ProcesoProductivoId IS NULL OR f.proceso_productivo_id = @ProcesoProductivoId)
              AND (@Activo IS NULL OR f.activo = @Activo)
            ORDER BY pp.orden_secuencia, f.nombre, f.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Formula>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.ProcesoProductivoId,
                    filters.Activo
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<long> CreateFormulaAsync(Formula formula, long? createdByUsuarioId, CancellationToken cancellationToken)
    {
        var entity = new FormulaWriteModel
        {
            Codigo = formula.Codigo,
            Nombre = formula.Nombre,
            ProcesoProductivoId = formula.ProcesoProductivoId,
            Descripcion = formula.Descripcion,
            Activo = formula.Activo,
            CreadoPorUsuarioId = createdByUsuarioId
        };

        dbContext.Formulas.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateFormulaAsync(Formula formula, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Formulas.SingleOrDefaultAsync(x => x.Id == formula.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Codigo = formula.Codigo;
        entity.Nombre = formula.Nombre;
        entity.ProcesoProductivoId = formula.ProcesoProductivoId;
        entity.Descripcion = formula.Descripcion;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetFormulaActiveAsync(long id, bool activo, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Formulas.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activo = activo;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<bool> HasAnyVigenteVersionAsync(long formulaId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.formula_version
                WHERE formula_id = @FormulaId
                  AND vigente = 1
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { FormulaId = formulaId }, cancellationToken: cancellationToken));
    }

    public async Task<bool> IsProcesoProductivoActiveAsync(long procesoProductivoId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.proceso_productivo
                WHERE id = @ProcesoProductivoId
                  AND activo = 1
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { ProcesoProductivoId = procesoProductivoId }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<ProcesoProductivoCatalogItem>> ListActiveProcesosProductivosAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                orden_secuencia AS OrdenSecuencia
            FROM configuracion.proceso_productivo
            WHERE activo = 1
            ORDER BY orden_secuencia, nombre, codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ProcesoProductivoCatalogItem>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<FormulaVersion?> FindVersionByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                fv.id AS Id,
                fv.formula_id AS FormulaId,
                f.codigo AS FormulaCodigo,
                f.nombre AS FormulaNombre,
                fv.numero_version AS NumeroVersion,
                fv.fecha_inicio_vigencia AS FechaInicioVigencia,
                fv.fecha_fin_vigencia AS FechaFinVigencia,
                fv.vigente AS Vigente,
                fv.observacion AS Observacion,
                fv.creado_en AS CreadoEn,
                fv.creado_por_usuario_id AS CreadoPorUsuarioId
            FROM configuracion.formula_version fv
            INNER JOIN configuracion.formula f ON f.id = fv.formula_id
            WHERE fv.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<FormulaVersion>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<FormulaVersion>> ListVersionsAsync(long formulaId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                fv.id AS Id,
                fv.formula_id AS FormulaId,
                f.codigo AS FormulaCodigo,
                f.nombre AS FormulaNombre,
                fv.numero_version AS NumeroVersion,
                fv.fecha_inicio_vigencia AS FechaInicioVigencia,
                fv.fecha_fin_vigencia AS FechaFinVigencia,
                fv.vigente AS Vigente,
                fv.observacion AS Observacion,
                fv.creado_en AS CreadoEn,
                fv.creado_por_usuario_id AS CreadoPorUsuarioId
            FROM configuracion.formula_version fv
            INNER JOIN configuracion.formula f ON f.id = fv.formula_id
            WHERE fv.formula_id = @FormulaId
            ORDER BY fv.numero_version DESC, fv.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<FormulaVersion>(
            new CommandDefinition(sql, new { FormulaId = formulaId }, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<bool> ExistsVersionNumberAsync(long formulaId, int numeroVersion, long? excludeId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.formula_version
                WHERE formula_id = @FormulaId
                  AND numero_version = @NumeroVersion
                  AND (@ExcludeId IS NULL OR id <> @ExcludeId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(
                sql,
                new { FormulaId = formulaId, NumeroVersion = numeroVersion, ExcludeId = excludeId },
                cancellationToken: cancellationToken));
    }

    public async Task<bool> HasVersionDateOverlapAsync(
        long formulaId,
        DateTime fechaInicioVigencia,
        DateTime? fechaFinVigencia,
        long? excludeId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.formula_version
                WHERE formula_id = @FormulaId
                  AND (@ExcludeId IS NULL OR id <> @ExcludeId)
                  AND fecha_inicio_vigencia <= COALESCE(@FechaFinVigencia, CONVERT(date, '9999-12-31'))
                  AND COALESCE(fecha_fin_vigencia, CONVERT(date, '9999-12-31')) >= @FechaInicioVigencia
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(
                sql,
                new
                {
                    FormulaId = formulaId,
                    FechaInicioVigencia = fechaInicioVigencia.Date,
                    FechaFinVigencia = fechaFinVigencia?.Date,
                    ExcludeId = excludeId
                },
                cancellationToken: cancellationToken));
    }

    public async Task<long> CreateVersionAsync(FormulaVersion version, long? createdByUsuarioId, CancellationToken cancellationToken)
    {
        var entity = new FormulaVersionWriteModel
        {
            FormulaId = version.FormulaId,
            NumeroVersion = version.NumeroVersion,
            FechaInicioVigencia = version.FechaInicioVigencia.Date,
            FechaFinVigencia = version.FechaFinVigencia?.Date,
            Vigente = version.Vigente,
            Observacion = version.Observacion,
            CreadoPorUsuarioId = createdByUsuarioId
        };

        dbContext.FormulaVersions.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateVersionAsync(FormulaVersion version, CancellationToken cancellationToken)
    {
        var entity = await dbContext.FormulaVersions.SingleOrDefaultAsync(x => x.Id == version.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.FechaInicioVigencia = version.FechaInicioVigencia.Date;
        entity.FechaFinVigencia = version.FechaFinVigencia?.Date;
        entity.Observacion = version.Observacion;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetVersionVigenteAsync(long formulaId, long versionId, CancellationToken cancellationToken)
    {
        var versions = await dbContext.FormulaVersions
            .Where(x => x.FormulaId == formulaId)
            .ToListAsync(cancellationToken);

        foreach (var version in versions)
        {
            version.Vigente = version.Id == versionId;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<bool> VersionHasActiveDetailsAsync(long versionId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.formula_detalle
                WHERE formula_version_id = @VersionId
                  AND activo = 1
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { VersionId = versionId }, cancellationToken: cancellationToken));
    }

    public async Task<FormulaDetalle?> FindDetailByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                fd.id AS Id,
                fd.formula_version_id AS FormulaVersionId,
                fd.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                fd.porcentaje AS Porcentaje,
                fd.observacion AS Observacion,
                fd.activo AS Activo
            FROM configuracion.formula_detalle fd
            INNER JOIN inventario.insumo i ON i.id = fd.insumo_id
            WHERE fd.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<FormulaDetalle>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<FormulaDetalle>> ListDetailsByVersionIdAsync(long versionId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                fd.id AS Id,
                fd.formula_version_id AS FormulaVersionId,
                fd.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                fd.porcentaje AS Porcentaje,
                fd.observacion AS Observacion,
                fd.activo AS Activo
            FROM configuracion.formula_detalle fd
            INNER JOIN inventario.insumo i ON i.id = fd.insumo_id
            WHERE fd.formula_version_id = @VersionId
            ORDER BY CASE WHEN fd.activo = 1 THEN 0 ELSE 1 END, i.nombre, i.codigo, fd.id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<FormulaDetalle>(
            new CommandDefinition(sql, new { VersionId = versionId }, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<bool> ExistsActiveDetailInsumoAsync(long versionId, long insumoId, long? excludeId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.formula_detalle
                WHERE formula_version_id = @VersionId
                  AND insumo_id = @InsumoId
                  AND activo = 1
                  AND (@ExcludeId IS NULL OR id <> @ExcludeId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(
                sql,
                new { VersionId = versionId, InsumoId = insumoId, ExcludeId = excludeId },
                cancellationToken: cancellationToken));
    }

    public async Task<bool> IsInsumoActiveAsync(long insumoId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM inventario.insumo
                WHERE id = @InsumoId
                  AND activo = 1
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { InsumoId = insumoId }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateDetailAsync(FormulaDetalle detail, CancellationToken cancellationToken)
    {
        var entity = new FormulaDetalleWriteModel
        {
            FormulaVersionId = detail.FormulaVersionId,
            InsumoId = detail.InsumoId,
            Porcentaje = detail.Porcentaje,
            Observacion = detail.Observacion,
            Activo = detail.Activo
        };

        dbContext.FormulaDetalles.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateDetailAsync(FormulaDetalle detail, CancellationToken cancellationToken)
    {
        var entity = await dbContext.FormulaDetalles.SingleOrDefaultAsync(x => x.Id == detail.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.InsumoId = detail.InsumoId;
        entity.Porcentaje = detail.Porcentaje;
        entity.Observacion = detail.Observacion;
        entity.Activo = detail.Activo;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SoftDeleteDetailAsync(long id, CancellationToken cancellationToken)
    {
        var entity = await dbContext.FormulaDetalles.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activo = false;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task CloneActiveDetailsAsync(long sourceVersionId, long targetVersionId, CancellationToken cancellationToken)
    {
        var sourceItems = await dbContext.FormulaDetalles
            .Where(x => x.FormulaVersionId == sourceVersionId && x.Activo)
            .ToListAsync(cancellationToken);

        if (sourceItems.Count == 0)
        {
            return;
        }

        foreach (var item in sourceItems)
        {
            dbContext.FormulaDetalles.Add(new FormulaDetalleWriteModel
            {
                FormulaVersionId = targetVersionId,
                InsumoId = item.InsumoId,
                Porcentaje = item.Porcentaje,
                Observacion = item.Observacion,
                Activo = item.Activo
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
