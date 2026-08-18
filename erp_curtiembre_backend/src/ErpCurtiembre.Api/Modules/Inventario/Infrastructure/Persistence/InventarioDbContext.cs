using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Time;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence;

public sealed class InventarioDbContext(
    DbContextOptions<InventarioDbContext> options,
    IDateTimeProvider dateTimeProvider) : DbContext(options)
{
    public DbSet<InsumoWriteModel> Insumos => Set<InsumoWriteModel>();

    public DbSet<ProveedorWriteModel> Proveedores => Set<ProveedorWriteModel>();

    public DbSet<StockInsumoWriteModel> StocksInsumo => Set<StockInsumoWriteModel>();

    public DbSet<OrdenCompraWriteModel> OrdenesCompra => Set<OrdenCompraWriteModel>();

    public DbSet<OrdenCompraDetalleWriteModel> OrdenesCompraDetalle => Set<OrdenCompraDetalleWriteModel>();

    public DbSet<EntradaInventarioWriteModel> EntradasInventario => Set<EntradaInventarioWriteModel>();

    public DbSet<EntradaInventarioDetalleWriteModel> EntradasInventarioDetalle => Set<EntradaInventarioDetalleWriteModel>();

    public DbSet<SalidaInventarioWriteModel> SalidasInventario => Set<SalidaInventarioWriteModel>();

    public DbSet<SalidaInventarioDetalleWriteModel> SalidasInventarioDetalle => Set<SalidaInventarioDetalleWriteModel>();

    public DbSet<AjusteInventarioWriteModel> AjustesInventario => Set<AjusteInventarioWriteModel>();

    public DbSet<AjusteInventarioDetalleWriteModel> AjustesInventarioDetalle => Set<AjusteInventarioDetalleWriteModel>();

    public DbSet<InventarioFisicoWriteModel> InventariosFisicos => Set<InventarioFisicoWriteModel>();

    public DbSet<InventarioFisicoDetalleWriteModel> InventariosFisicosDetalle => Set<InventarioFisicoDetalleWriteModel>();

    public DbSet<KardexMovimientoWriteModel> KardexMovimientos => Set<KardexMovimientoWriteModel>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("inventario");

        modelBuilder.Entity<InsumoWriteModel>(entity =>
        {
            entity.ToTable("insumo");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.Nombre).HasColumnName("nombre").HasMaxLength(150);
            entity.Property(x => x.TipoBien).HasColumnName("tipo_bien").HasMaxLength(40);
            entity.Property(x => x.Presentacion).HasColumnName("presentacion").HasMaxLength(150);
            entity.Property(x => x.UnidadMedidaId).HasColumnName("unidad_medida_id");
            entity.Property(x => x.StockMinimo).HasColumnName("stock_minimo").HasPrecision(18, 4);
            entity.Property(x => x.CostoPromedioActual).HasColumnName("costo_promedio_actual").HasPrecision(18, 4);
            entity.Property(x => x.RequiereLote).HasColumnName("requiere_lote");
            entity.Property(x => x.Activo).HasColumnName("activo");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.CreadoPorUsuarioId).HasColumnName("creado_por_usuario_id");
            entity.Property(x => x.ActualizadoEn).HasColumnName("actualizado_en");
            entity.Property(x => x.ActualizadoPorUsuarioId).HasColumnName("actualizado_por_usuario_id");
        });

        modelBuilder.Entity<ProveedorWriteModel>(entity =>
        {
            entity.ToTable("proveedor");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.RucDocumento).HasColumnName("ruc_documento").HasMaxLength(20);
            entity.Property(x => x.RazonSocial).HasColumnName("razon_social").HasMaxLength(180);
            entity.Property(x => x.Direccion).HasColumnName("direccion").HasMaxLength(250);
            entity.Property(x => x.Telefono).HasColumnName("telefono").HasMaxLength(30);
            entity.Property(x => x.Correo).HasColumnName("correo").HasMaxLength(150);
            entity.Property(x => x.Contacto).HasColumnName("contacto").HasMaxLength(150);
            entity.Property(x => x.Activo).HasColumnName("activo");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.ActualizadoEn).HasColumnName("actualizado_en");
        });

        modelBuilder.Entity<StockInsumoWriteModel>(entity =>
        {
            entity.ToTable("stock_insumo");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.CantidadActual).HasColumnName("cantidad_actual").HasPrecision(18, 4);
            entity.Property(x => x.CostoPromedioActual).HasColumnName("costo_promedio_actual").HasPrecision(18, 4);
            entity.Property(x => x.ActualizadoEn).HasColumnName("actualizado_en");
        });

        modelBuilder.Entity<OrdenCompraWriteModel>(entity =>
        {
            entity.ToTable("orden_compra");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.ProveedorId).HasColumnName("proveedor_id");
            entity.Property(x => x.FechaEmision).HasColumnName("fecha_emision");
            entity.Property(x => x.FechaAprobacion).HasColumnName("fecha_aprobacion");
            entity.Property(x => x.AprobadoPorUsuarioId).HasColumnName("aprobado_por_usuario_id");
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(40);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
            entity.Property(x => x.MotivoAnulacion).HasColumnName("motivo_anulacion").HasMaxLength(500);
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.CreadoPorUsuarioId).HasColumnName("creado_por_usuario_id");
            entity.Property(x => x.ActualizadoEn).HasColumnName("actualizado_en");
            entity.Property(x => x.ActualizadoPorUsuarioId).HasColumnName("actualizado_por_usuario_id");
        });

        modelBuilder.Entity<OrdenCompraDetalleWriteModel>(entity =>
        {
            entity.ToTable("orden_compra_detalle");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenCompraId).HasColumnName("orden_compra_id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.CantidadSolicitada).HasColumnName("cantidad_solicitada").HasPrecision(18, 4);
            entity.Property(x => x.CantidadRecibida).HasColumnName("cantidad_recibida").HasPrecision(18, 4);
            entity.Property(x => x.CostoUnitarioEstimado).HasColumnName("costo_unitario_estimado").HasPrecision(18, 4);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(300);
        });

        modelBuilder.Entity<EntradaInventarioWriteModel>(entity =>
        {
            entity.ToTable("entrada_inventario");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.TipoEntrada).HasColumnName("tipo_entrada").HasMaxLength(40);
            entity.Property(x => x.OrdenCompraId).HasColumnName("orden_compra_id");
            entity.Property(x => x.FechaEntrada).HasColumnName("fecha_entrada");
            entity.Property(x => x.DocumentoSoporte).HasColumnName("documento_soporte").HasMaxLength(100);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.CreadoPorUsuarioId).HasColumnName("creado_por_usuario_id");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });

        modelBuilder.Entity<EntradaInventarioDetalleWriteModel>(entity =>
        {
            entity.ToTable("entrada_inventario_detalle");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.EntradaInventarioId).HasColumnName("entrada_inventario_id");
            entity.Property(x => x.OrdenCompraDetalleId).HasColumnName("orden_compra_detalle_id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.Cantidad).HasColumnName("cantidad").HasPrecision(18, 4);
            entity.Property(x => x.CostoUnitario).HasColumnName("costo_unitario").HasPrecision(18, 4);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(300);
        });

        modelBuilder.Entity<SalidaInventarioWriteModel>(entity =>
        {
            entity.ToTable("salida_inventario");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.TipoSalida).HasColumnName("tipo_salida").HasMaxLength(40);
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.OrdenProcesoId).HasColumnName("orden_proceso_id");
            entity.Property(x => x.FechaSalida).HasColumnName("fecha_salida");
            entity.Property(x => x.Motivo).HasColumnName("motivo").HasMaxLength(150);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.CreadoPorUsuarioId).HasColumnName("creado_por_usuario_id");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });

        modelBuilder.Entity<SalidaInventarioDetalleWriteModel>(entity =>
        {
            entity.ToTable("salida_inventario_detalle");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.SalidaInventarioId).HasColumnName("salida_inventario_id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.Cantidad).HasColumnName("cantidad").HasPrecision(18, 4);
            entity.Property(x => x.CostoUnitario).HasColumnName("costo_unitario").HasPrecision(18, 4);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(300);
        });

        modelBuilder.Entity<AjusteInventarioWriteModel>(entity =>
        {
            entity.ToTable("ajuste_inventario");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.TipoAjuste).HasColumnName("tipo_ajuste").HasMaxLength(30);
            entity.Property(x => x.FechaAjuste).HasColumnName("fecha_ajuste");
            entity.Property(x => x.Motivo).HasColumnName("motivo").HasMaxLength(200);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
            entity.Property(x => x.UsuarioResponsableId).HasColumnName("usuario_responsable_id");
        });

        modelBuilder.Entity<AjusteInventarioDetalleWriteModel>(entity =>
        {
            entity.ToTable("ajuste_inventario_detalle");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.AjusteInventarioId).HasColumnName("ajuste_inventario_id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.Cantidad).HasColumnName("cantidad").HasPrecision(18, 4);
            entity.Property(x => x.CostoUnitario).HasColumnName("costo_unitario").HasPrecision(18, 4);
        });

        modelBuilder.Entity<InventarioFisicoWriteModel>(entity =>
        {
            entity.ToTable("inventario_fisico");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.FechaInicio).HasColumnName("fecha_inicio");
            entity.Property(x => x.FechaCierre).HasColumnName("fecha_cierre");
            entity.Property(x => x.PeriodoAnio).HasColumnName("periodo_anio");
            entity.Property(x => x.PeriodoMes).HasColumnName("periodo_mes");
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.EjecutadoPorUsuarioId).HasColumnName("ejecutado_por_usuario_id");
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
        });

        modelBuilder.Entity<InventarioFisicoDetalleWriteModel>(entity =>
        {
            entity.ToTable("inventario_fisico_detalle");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.InventarioFisicoId).HasColumnName("inventario_fisico_id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.StockSistema).HasColumnName("stock_sistema").HasPrecision(18, 4);
            entity.Property(x => x.StockContado).HasColumnName("stock_contado").HasPrecision(18, 4);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(300);
        });

        modelBuilder.Entity<KardexMovimientoWriteModel>(entity =>
        {
            entity.ToTable("kardex_movimiento");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.FechaMovimiento).HasColumnName("fecha_movimiento");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.TipoMovimiento).HasColumnName("tipo_movimiento").HasMaxLength(40);
            entity.Property(x => x.DocumentoTipo).HasColumnName("documento_tipo").HasMaxLength(60);
            entity.Property(x => x.DocumentoId).HasColumnName("documento_id");
            entity.Property(x => x.Entrada).HasColumnName("entrada").HasPrecision(18, 4);
            entity.Property(x => x.Salida).HasColumnName("salida").HasPrecision(18, 4);
            entity.Property(x => x.StockActual).HasColumnName("stock_actual").HasPrecision(18, 4);
            entity.Property(x => x.EstadoStock).HasColumnName("estado_stock").HasMaxLength(30);
            entity.Property(x => x.CostoUnitario).HasColumnName("costo_unitario").HasPrecision(18, 4);
            entity.Property(x => x.CostoTotal).HasColumnName("costo_total").HasPrecision(18, 2);
            entity.Property(x => x.UsuarioResponsableId).HasColumnName("usuario_responsable_id");
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
        });

    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        StampDates();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void StampDates()
    {
        var now = dateTimeProvider.Now;

        foreach (var entry in ChangeTracker.Entries<InsumoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }

            if (entry.State == EntityState.Modified && entry.Entity.ActualizadoEn is null)
            {
                entry.Entity.ActualizadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<ProveedorWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<StockInsumoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.ActualizadoEn == default)
            {
                entry.Entity.ActualizadoEn = now;
            }

            if (entry.State == EntityState.Modified)
            {
                entry.Entity.ActualizadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<OrdenCompraWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<EntradaInventarioWriteModel>())
        {
            if (entry.State == EntityState.Added)
            {
                if (entry.Entity.FechaEntrada == default)
                {
                    entry.Entity.FechaEntrada = now;
                }

                if (entry.Entity.CreadoEn == default)
                {
                    entry.Entity.CreadoEn = now;
                }
            }
        }

        foreach (var entry in ChangeTracker.Entries<KardexMovimientoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.FechaMovimiento == default)
            {
                entry.Entity.FechaMovimiento = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<InventarioFisicoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.FechaInicio == default)
            {
                entry.Entity.FechaInicio = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<SalidaInventarioWriteModel>())
        {
            if (entry.State == EntityState.Added)
            {
                if (entry.Entity.FechaSalida == default)
                {
                    entry.Entity.FechaSalida = now;
                }

                if (entry.Entity.CreadoEn == default)
                {
                    entry.Entity.CreadoEn = now;
                }
            }
        }
    }
}
