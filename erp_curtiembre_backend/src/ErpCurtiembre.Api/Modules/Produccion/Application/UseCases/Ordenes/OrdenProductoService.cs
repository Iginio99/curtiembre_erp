using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Ordenes;

public sealed class OrdenProductoService(ISqlConnectionFactory connectionFactory)
{
    private static readonly HashSet<string> ProductProcesses = new(StringComparer.OrdinalIgnoreCase)
    {
        "RECURTIDO", "ACABADO"
    };

    public async Task<IReadOnlyCollection<FormulaProduccionOptionDto>> ListFormulaOptionsAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT f.id AS FormulaId, f.codigo AS FormulaCodigo, f.nombre AS FormulaNombre,
                   f.tipo_producto AS TipoProducto, f.color AS Color,
                   pp.id AS ProcesoProductivoId, pp.codigo AS ProcesoCodigo, pp.nombre AS ProcesoNombre,
                   fv.id AS FormulaVersionId, fv.numero_version AS NumeroVersion
            FROM configuracion.formula f
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = f.proceso_productivo_id
            INNER JOIN configuracion.formula_version fv ON fv.formula_id = f.id
            WHERE f.activo = 1 AND fv.vigente = 1 AND pp.codigo IN ('REMOJO_PELAMBRE', 'CURTIDO', 'RECURTIDO', 'ACABADO')
              AND fv.fecha_inicio_vigencia <= SYSDATETIME()
              AND (fv.fecha_fin_vigencia IS NULL OR fv.fecha_fin_vigencia >= CAST(SYSDATETIME() AS date))
            ORDER BY pp.orden_secuencia, f.nombre, fv.numero_version DESC;
            """;
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = (await connection.QueryAsync<FormulaOptionRow>(
            new CommandDefinition(sql, cancellationToken: cancellationToken))).ToArray();
        const string detailsSql = """
            SELECT fd.formula_version_id AS FormulaVersionId, fd.insumo_id AS InsumoId, i.codigo AS InsumoCodigo,
                   i.nombre AS InsumoNombre, fd.porcentaje AS Porcentaje, fd.observacion AS Observacion
            FROM configuracion.formula_detalle fd INNER JOIN inventario.insumo i ON i.id=fd.insumo_id
            WHERE fd.activo=1 AND fd.formula_version_id IN @Ids ORDER BY fd.id;
            """;
        var details = (await connection.QueryAsync<FormulaDetailRow>(new CommandDefinition(detailsSql, new { Ids=items.Select(x=>x.FormulaVersionId).ToArray() }, cancellationToken:cancellationToken))).ToArray();
        return items.Select(x => new FormulaProduccionOptionDto(x.FormulaId,x.FormulaCodigo,x.FormulaNombre,x.TipoProducto,x.Color,x.ProcesoProductivoId,x.ProcesoCodigo,x.ProcesoNombre,x.FormulaVersionId,x.NumeroVersion,details.Where(d=>d.FormulaVersionId==x.FormulaVersionId).Select(d=>new FormulaInsumoDto(d.InsumoId,d.InsumoCodigo,d.InsumoNombre,d.Porcentaje,d.Observacion)).ToArray())).ToArray();
    }

    public async Task<IReadOnlyCollection<OrdenProductoDto>> ListAsync(long orderId, CancellationToken cancellationToken)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await LoadAsync(connection, orderId, cancellationToken);
    }

    public async Task<IReadOnlyCollection<ConsumoPlanificadoItemDto>> ListPlannedAsync(long orderId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT ocp.id AS Id, ocp.orden_produccion_id AS OrdenProduccionId, ocp.orden_proceso_id AS OrdenProcesoId,
                   pp.id AS ProcesoProductivoId, pp.codigo AS ProcesoCodigo, pp.nombre AS ProcesoNombre,
                   ocp.formula_version_id AS FormulaVersionId, i.id AS InsumoId, i.codigo AS InsumoCodigo,
                   CONCAT(p.nombre, ' - ', i.nombre) AS InsumoNombre, ocp.porcentaje AS Porcentaje,
                   ocp.cantidad_planificada AS CantidadPlanificada, ocp.creado_en AS CreadoEn
            FROM produccion.orden_consumo_planificado ocp
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id=ocp.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id=opp.proceso_productivo_id
            INNER JOIN inventario.insumo i ON i.id=ocp.insumo_id
            LEFT JOIN produccion.orden_producto p ON p.id=ocp.orden_producto_id
            WHERE ocp.orden_produccion_id=@OrderId
            ORDER BY pp.orden_secuencia,p.nombre,i.nombre;
            """;
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<ConsumoPlanificadoItemDto>(new CommandDefinition(sql, new { OrderId = orderId }, cancellationToken: cancellationToken));
        return rows.ToArray();
    }

    public async Task<UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>> GeneratePlannedAsync(long orderId, CancellationToken cancellationToken)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var allocation = await connection.QuerySingleOrDefaultAsync<(decimal OrderSkins, decimal ProductSkins, int ProductCount, int FormulaCount)>(new CommandDefinition("""
            SELECT op.cantidad_pieles AS OrderSkins,
                   ISNULL(SUM(CASE WHEN p.activo=1 THEN p.cantidad_pieles ELSE 0 END),0) AS ProductSkins,
                   COUNT(DISTINCT CASE WHEN p.activo=1 THEN p.id END) AS ProductCount,
                   COUNT(DISTINCT CASE WHEN p.activo=1 THEN opf.id END) AS FormulaCount
            FROM produccion.orden_produccion op
            LEFT JOIN produccion.orden_producto p ON p.orden_produccion_id=op.id
            LEFT JOIN produccion.orden_producto_formula opf ON opf.orden_producto_id=p.id
            WHERE op.id=@OrderId GROUP BY op.cantidad_pieles;
            """, new { OrderId = orderId }, cancellationToken: cancellationToken));
        if (allocation.ProductCount == 0) return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Fail(ProduccionErrorCodes.Validation, "Primero divide la orden en productos.");
        if (allocation.ProductSkins != allocation.OrderSkins) return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Fail(ProduccionErrorCodes.Validation, "Debes distribuir todas las pieles de la orden entre los productos.");
        if (allocation.FormulaCount != allocation.ProductCount * 2) return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Fail(ProduccionErrorCodes.Validation, "Cada producto debe tener formula de Recurtido y de Acabado.");
        using var transaction = connection.BeginTransaction();
        await connection.ExecuteAsync(new CommandDefinition("DELETE FROM produccion.orden_consumo_planificado WHERE orden_produccion_id=@OrderId AND orden_producto_id IS NOT NULL", new { OrderId = orderId }, transaction, cancellationToken: cancellationToken));
        const string insert = """
            INSERT INTO produccion.orden_consumo_planificado
                (orden_produccion_id,orden_proceso_id,orden_producto_id,formula_version_id,insumo_id,porcentaje,cantidad_planificada)
            SELECT p.orden_produccion_id,opp.id,p.id,opf.formula_version_id,fd.insumo_id,fd.porcentaje,
                   ROUND(opf.kilos_base * fd.porcentaje / 100.0,4)
            FROM produccion.orden_producto p
            INNER JOIN produccion.orden_producto_formula opf ON opf.orden_producto_id=p.id
            INNER JOIN configuracion.formula_detalle fd ON fd.formula_version_id=opf.formula_version_id AND fd.activo=1
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.orden_produccion_id=p.orden_produccion_id AND opp.proceso_productivo_id=opf.proceso_productivo_id
            WHERE p.orden_produccion_id=@OrderId AND p.activo=1;
            """;
        await connection.ExecuteAsync(new CommandDefinition(insert, new { OrderId = orderId }, transaction, cancellationToken: cancellationToken));
        transaction.Commit();
        return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Ok(await ListPlannedAsync(orderId, cancellationToken), "Consumo por producto calculado correctamente.");
    }

    public async Task<UseCaseResult<OrdenProductoDto>> CreateAsync(
        long orderId, UpsertOrdenProductoRequestDto request, long actorId, CancellationToken cancellationToken)
    {
        var validation = await ValidateAsync(orderId, null, request, cancellationToken);
        if (validation is not null) return UseCaseResult<OrdenProductoDto>.Fail(ProduccionErrorCodes.Validation, validation);

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        using var transaction = connection.BeginTransaction();
        const string insert = """
            INSERT INTO produccion.orden_producto
                (orden_produccion_id, codigo, nombre, color, cantidad_pieles, cantidad_lados,
                 kilos_recurtido, kilos_acabado, observacion, creado_por_usuario_id)
            OUTPUT INSERTED.id
            VALUES (@OrderId, @Codigo, @Nombre, @Color, @CantidadPieles, @CantidadLados,
                    @KilosRecurtido, @KilosAcabado, @Observacion, @ActorId);
            """;
        var id = await connection.ExecuteScalarAsync<long>(new CommandDefinition(insert, new
        {
            OrderId = orderId,
            Codigo = request.Codigo.Trim(),
            Nombre = request.Nombre.Trim(),
            Color = Normalize(request.Color),
            CantidadPieles = decimal.Round(request.CantidadPieles, 2),
            CantidadLados = decimal.Round(request.CantidadLados, 2),
            KilosRecurtido = decimal.Round(request.KilosRecurtido, 3),
            KilosAcabado = decimal.Round(request.KilosAcabado, 3),
            Observacion = Normalize(request.Observacion), ActorId = actorId
        }, transaction, cancellationToken: cancellationToken));
        await ReplaceFormulasAsync(connection, transaction, id, request.Formulas, actorId, cancellationToken);
        transaction.Commit();
        var created = (await LoadAsync(connection, orderId, cancellationToken)).Single(x => x.Id == id);
        return UseCaseResult<OrdenProductoDto>.Ok(created, "Producto de la orden creado correctamente.");
    }

    public async Task<UseCaseResult<OrdenProductoDto>> UpdateAsync(
        long orderId, long id, UpsertOrdenProductoRequestDto request, long actorId, CancellationToken cancellationToken)
    {
        var validation = await ValidateAsync(orderId, id, request, cancellationToken);
        if (validation is not null) return UseCaseResult<OrdenProductoDto>.Fail(ProduccionErrorCodes.Validation, validation);
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        using var transaction = connection.BeginTransaction();
        const string update = """
            UPDATE produccion.orden_producto SET codigo=@Codigo, nombre=@Nombre, color=@Color,
                cantidad_pieles=@CantidadPieles, cantidad_lados=@CantidadLados,
                kilos_recurtido=@KilosRecurtido, kilos_acabado=@KilosAcabado, observacion=@Observacion
            WHERE id=@Id AND orden_produccion_id=@OrderId AND activo=1;
            """;
        await connection.ExecuteAsync(new CommandDefinition(update, new
        {
            Id = id, OrderId = orderId, Codigo = request.Codigo.Trim(), Nombre = request.Nombre.Trim(),
            Color = Normalize(request.Color), CantidadPieles = decimal.Round(request.CantidadPieles, 2),
            CantidadLados = decimal.Round(request.CantidadLados, 2), KilosRecurtido = decimal.Round(request.KilosRecurtido, 3),
            KilosAcabado = decimal.Round(request.KilosAcabado, 3), Observacion = Normalize(request.Observacion)
        }, transaction, cancellationToken: cancellationToken));
        await ReplaceFormulasAsync(connection, transaction, id, request.Formulas, actorId, cancellationToken);
        transaction.Commit();
        var updated = (await LoadAsync(connection, orderId, cancellationToken)).Single(x => x.Id == id);
        return UseCaseResult<OrdenProductoDto>.Ok(updated, "Producto de la orden actualizado correctamente.");
    }

    public async Task<UseCaseResult<bool>> DeactivateAsync(long orderId, long id, CancellationToken cancellationToken)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var affected = await connection.ExecuteAsync(new CommandDefinition(
            "UPDATE produccion.orden_producto SET activo=0 WHERE id=@Id AND orden_produccion_id=@OrderId AND activo=1",
            new { Id = id, OrderId = orderId }, cancellationToken: cancellationToken));
        return affected == 0
            ? UseCaseResult<bool>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el producto activo.")
            : UseCaseResult<bool>.Ok(true, "Producto retirado de la orden.");
    }

    private async Task<string?> ValidateAsync(long orderId, long? productId, UpsertOrdenProductoRequestDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo) || string.IsNullOrWhiteSpace(request.Nombre)) return "Codigo y nombre son obligatorios.";
        if (request.CantidadPieles <= 0 || request.CantidadLados <= 0) return "Las cantidades de pieles y lados deben ser mayores que cero.";
        if (request.Formulas.GroupBy(x => x.ProcesoProductivoId).Any(x => x.Count() > 1)) return "Solo se permite una formula por proceso y producto.";
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        const string totals = """
            SELECT op.cantidad_pieles AS OrderSkins,
              ISNULL(SUM(CASE WHEN p.activo=1 AND (@ProductId IS NULL OR p.id<>@ProductId) THEN p.cantidad_pieles ELSE 0 END),0) AS UsedSkins,
              ISNULL(SUM(CASE WHEN p.activo=1 AND (@ProductId IS NULL OR p.id<>@ProductId) THEN p.cantidad_lados ELSE 0 END),0) AS UsedSides
            FROM produccion.orden_produccion op LEFT JOIN produccion.orden_producto p ON p.orden_produccion_id=op.id
            WHERE op.id=@OrderId GROUP BY op.cantidad_pieles;
            """;
        var allocation = await connection.QuerySingleOrDefaultAsync<(decimal OrderSkins, decimal UsedSkins, decimal UsedSides)>(
            new CommandDefinition(totals, new { OrderId = orderId, ProductId = productId }, cancellationToken: cancellationToken));
        if (allocation.OrderSkins <= 0) return "No se encontro la orden de produccion.";
        if (allocation.UsedSkins + request.CantidadPieles > allocation.OrderSkins) return "La suma de pieles de los productos supera las pieles de la orden.";
        if (allocation.UsedSides + request.CantidadLados > allocation.OrderSkins * 2) return "La suma de lados supera los lados disponibles de la orden.";
        const string formulasSql = """
            SELECT pp.codigo FROM configuracion.formula_version fv
            INNER JOIN configuracion.formula f ON f.id=fv.formula_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id=f.proceso_productivo_id
            WHERE fv.id IN @Ids AND fv.vigente=1 AND f.activo=1 AND f.proceso_productivo_id IN @ProcessIds;
            """;
        if (request.Formulas.Count > 0)
        {
            var codes = (await connection.QueryAsync<string>(new CommandDefinition(formulasSql, new
            {
                Ids = request.Formulas.Select(x => x.FormulaVersionId).ToArray(),
                ProcessIds = request.Formulas.Select(x => x.ProcesoProductivoId).ToArray()
            }, cancellationToken: cancellationToken))).ToArray();
            if (codes.Length != request.Formulas.Count || codes.Any(x => !ProductProcesses.Contains(x))) return "Las formulas deben estar vigentes y pertenecer a Recurtido o Acabado.";
        }
        return null;
    }

    private static async Task ReplaceFormulasAsync(System.Data.IDbConnection connection, System.Data.IDbTransaction transaction,
        long productId, IReadOnlyCollection<OrdenProductoFormulaRequestDto> formulas, long actorId, CancellationToken cancellationToken)
    {
        await connection.ExecuteAsync(new CommandDefinition("DELETE FROM produccion.orden_producto_formula WHERE orden_producto_id=@ProductId", new { ProductId = productId }, transaction, cancellationToken: cancellationToken));
        const string insert = """
            INSERT INTO produccion.orden_producto_formula
                (orden_producto_id, proceso_productivo_id, formula_version_id, kilos_base, creado_por_usuario_id)
            VALUES (@ProductId, @ProcesoProductivoId, @FormulaVersionId, @KilosBase, @ActorId);
            """;
        foreach (var formula in formulas)
            await connection.ExecuteAsync(new CommandDefinition(insert, new { ProductId = productId, formula.ProcesoProductivoId, formula.FormulaVersionId, KilosBase = decimal.Round(formula.KilosBase, 3), ActorId = actorId }, transaction, cancellationToken: cancellationToken));
    }

    private static async Task<IReadOnlyCollection<OrdenProductoDto>> LoadAsync(System.Data.IDbConnection connection, long orderId, CancellationToken cancellationToken)
    {
        const string productsSql = """
            SELECT id AS Id, orden_produccion_id AS OrdenProduccionId, codigo AS Codigo, nombre AS Nombre,
                   color AS Color, cantidad_pieles AS CantidadPieles, cantidad_lados AS CantidadLados,
                   kilos_recurtido AS KilosRecurtido, kilos_acabado AS KilosAcabado,
                   observacion AS Observacion, activo AS Activo, creado_en AS CreadoEn
            FROM produccion.orden_producto WHERE orden_produccion_id=@OrderId AND activo=1 ORDER BY id;
            """;
        const string formulasSql = """
            SELECT opf.id AS Id, opf.orden_producto_id AS ProductId, pp.id AS ProcesoProductivoId,
                   pp.codigo AS ProcesoCodigo, pp.nombre AS ProcesoNombre, fv.id AS FormulaVersionId,
                   f.id AS FormulaId, f.codigo AS FormulaCodigo, f.nombre AS FormulaNombre,
                   fv.numero_version AS NumeroVersion, opf.kilos_base AS KilosBase,
                   CAST(ISNULL(SUM((fd.porcentaje / 100.0) * opf.kilos_base * ISNULL(cost.costo_unitario,0)),0) AS decimal(18,4)) AS CostoEstimado
            FROM produccion.orden_producto_formula opf
            INNER JOIN produccion.orden_producto p ON p.id=opf.orden_producto_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id=opf.proceso_productivo_id
            INNER JOIN configuracion.formula_version fv ON fv.id=opf.formula_version_id
            INNER JOIN configuracion.formula f ON f.id=fv.formula_id
            LEFT JOIN configuracion.formula_detalle fd ON fd.formula_version_id=fv.id AND fd.activo=1
            OUTER APPLY (SELECT TOP 1 k.costo_unitario FROM inventario.kardex_movimiento k WHERE k.insumo_id=fd.insumo_id ORDER BY k.fecha_movimiento DESC,k.id DESC) cost
            WHERE p.orden_produccion_id=@OrderId AND p.activo=1
            GROUP BY opf.id,opf.orden_producto_id,pp.id,pp.codigo,pp.nombre,pp.orden_secuencia,fv.id,f.id,f.codigo,f.nombre,fv.numero_version,opf.kilos_base
            ORDER BY opf.orden_producto_id,pp.orden_secuencia;
            """;
        var products = (await connection.QueryAsync<ProductRow>(new CommandDefinition(productsSql, new { OrderId = orderId }, cancellationToken: cancellationToken))).ToArray();
        var formulas = (await connection.QueryAsync<FormulaRow>(new CommandDefinition(formulasSql, new { OrderId = orderId }, cancellationToken: cancellationToken))).ToArray();
        return products.Select(p =>
        {
            var productFormulas = formulas.Where(x => x.ProductId == p.Id).Select(x => new OrdenProductoFormulaDto(x.Id, x.ProcesoProductivoId, x.ProcesoCodigo, x.ProcesoNombre, x.FormulaVersionId, x.FormulaId, x.FormulaCodigo, x.FormulaNombre, x.NumeroVersion, x.KilosBase, x.CostoEstimado)).ToArray();
            var cost = productFormulas.Sum(x => x.CostoEstimado);
            return new OrdenProductoDto(p.Id,p.OrdenProduccionId,p.Codigo,p.Nombre,p.Color,p.CantidadPieles,p.CantidadLados,p.KilosRecurtido,p.KilosAcabado,p.Observacion,p.Activo,p.CreadoEn,cost,p.CantidadLados > 0 ? decimal.Round(cost/p.CantidadLados,4) : 0,productFormulas);
        }).ToArray();
    }

    private static string? Normalize(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    private sealed class ProductRow { public long Id { get; init; } public long OrdenProduccionId { get; init; } public string Codigo { get; init; }=""; public string Nombre { get; init; }=""; public string? Color { get; init; } public decimal CantidadPieles { get; init; } public decimal CantidadLados { get; init; } public decimal KilosRecurtido { get; init; } public decimal KilosAcabado { get; init; } public string? Observacion { get; init; } public bool Activo { get; init; } public DateTime CreadoEn { get; init; } }
    private sealed class FormulaRow { public long Id { get; init; } public long ProductId { get; init; } public long ProcesoProductivoId { get; init; } public string ProcesoCodigo { get; init; }=""; public string ProcesoNombre { get; init; }=""; public long FormulaVersionId { get; init; } public long FormulaId { get; init; } public string FormulaCodigo { get; init; }=""; public string FormulaNombre { get; init; }=""; public int NumeroVersion { get; init; } public decimal KilosBase { get; init; } public decimal CostoEstimado { get; init; } }
    private sealed class FormulaOptionRow { public long FormulaId { get; init; } public string FormulaCodigo { get; init; }=""; public string FormulaNombre { get; init; }=""; public string? TipoProducto { get; init; } public string? Color { get; init; } public long ProcesoProductivoId { get; init; } public string ProcesoCodigo { get; init; }=""; public string ProcesoNombre { get; init; }=""; public long FormulaVersionId { get; init; } public int NumeroVersion { get; init; } }
    private sealed class FormulaDetailRow { public long FormulaVersionId { get; init; } public long InsumoId { get; init; } public string InsumoCodigo { get; init; }=""; public string InsumoNombre { get; init; }=""; public decimal Porcentaje { get; init; } public string? Observacion { get; init; } }
}
