using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Time;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence;

public sealed class ProduccionDbContext(
    DbContextOptions<ProduccionDbContext> options,
    IDateTimeProvider dateTimeProvider) : DbContext(options)
{
    public DbSet<ClienteWriteModel> Clientes => Set<ClienteWriteModel>();

    public DbSet<LoteWriteModel> Lotes => Set<LoteWriteModel>();

    public DbSet<OrdenProduccionWriteModel> OrdenesProduccion => Set<OrdenProduccionWriteModel>();

    public DbSet<OrdenProduccionProcesoWriteModel> OrdenesProduccionProceso => Set<OrdenProduccionProcesoWriteModel>();

    public DbSet<OrdenConsumoPlanificadoWriteModel> OrdenesConsumoPlanificado => Set<OrdenConsumoPlanificadoWriteModel>();

    public DbSet<OrdenConsumoRealWriteModel> OrdenesConsumoReal => Set<OrdenConsumoRealWriteModel>();

    public DbSet<DesviacionConsumoWriteModel> DesviacionesConsumo => Set<DesviacionConsumoWriteModel>();

    public DbSet<MermaProcesoWriteModel> MermasProceso => Set<MermaProcesoWriteModel>();

    public DbSet<ControlCalidadWriteModel> ControlesCalidad => Set<ControlCalidadWriteModel>();

    public DbSet<ProductoTerminadoWriteModel> ProductosTerminados => Set<ProductoTerminadoWriteModel>();

    public DbSet<SolicitudInsumoWriteModel> SolicitudesInsumo => Set<SolicitudInsumoWriteModel>();

    public DbSet<SolicitudInsumoDetalleWriteModel> SolicitudesInsumoDetalle => Set<SolicitudInsumoDetalleWriteModel>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("produccion");

        modelBuilder.Entity<ClienteWriteModel>(entity =>
        {
            entity.ToTable("cliente");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.RucDocumento).HasColumnName("ruc_documento").HasMaxLength(20);
            entity.Property(x => x.RazonSocial).HasColumnName("razon_social").HasMaxLength(180);
            entity.Property(x => x.Direccion).HasColumnName("direccion").HasMaxLength(250);
            entity.Property(x => x.Celular).HasColumnName("celular").HasMaxLength(30);
            entity.Property(x => x.Correo).HasColumnName("correo").HasMaxLength(150);
            entity.Property(x => x.Contacto).HasColumnName("contacto").HasMaxLength(150);
            entity.Property(x => x.Activo).HasColumnName("activo");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.ActualizadoEn).HasColumnName("actualizado_en");
        });

        modelBuilder.Entity<LoteWriteModel>(entity =>
        {
            entity.ToTable("lote");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.ClienteId).HasColumnName("cliente_id");
            entity.Property(x => x.TipoPielId).HasColumnName("tipo_piel_id");
            entity.Property(x => x.FechaIngreso).HasColumnName("fecha_ingreso");
            entity.Property(x => x.CantidadPielesInicial).HasColumnName("cantidad_pieles_inicial").HasPrecision(18, 4);
            entity.Property(x => x.CantidadPielesDisponible).HasColumnName("cantidad_pieles_disponible").HasPrecision(18, 4);
            entity.Property(x => x.ClienteTraeLote).HasColumnName("cliente_trae_lote");
            entity.Property(x => x.CostoPielesTotal).HasColumnName("costo_pieles_total").HasPrecision(18, 2);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.CreadoPorUsuarioId).HasColumnName("creado_por_usuario_id");
        });

        modelBuilder.Entity<OrdenProduccionWriteModel>(entity =>
        {
            entity.ToTable("orden_produccion");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.LoteId).HasColumnName("lote_id");
            entity.Property(x => x.ClienteId).HasColumnName("cliente_id");
            entity.Property(x => x.CantidadPieles).HasColumnName("cantidad_pieles").HasPrecision(18, 4);
            entity.Property(x => x.FechaInicioPlanificada).HasColumnName("fecha_inicio_planificada");
            entity.Property(x => x.FechaInicioReal).HasColumnName("fecha_inicio_real");
            entity.Property(x => x.FechaFinEstimada).HasColumnName("fecha_fin_estimada");
            entity.Property(x => x.FechaFinReal).HasColumnName("fecha_fin_real");
            entity.Property(x => x.ResponsableUsuarioId).HasColumnName("responsable_usuario_id");
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.MotivoAnulacion).HasColumnName("motivo_anulacion").HasMaxLength(500);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.CreadoPorUsuarioId).HasColumnName("creado_por_usuario_id");
            entity.Property(x => x.ActualizadoEn).HasColumnName("actualizado_en");
            entity.Property(x => x.ActualizadoPorUsuarioId).HasColumnName("actualizado_por_usuario_id");
        });

        modelBuilder.Entity<OrdenProduccionProcesoWriteModel>(entity =>
        {
            entity.ToTable("orden_produccion_proceso");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.ProcesoProductivoId).HasColumnName("proceso_productivo_id");
            entity.Property(x => x.Secuencia).HasColumnName("secuencia");
            entity.Property(x => x.ResponsableUsuarioId).HasColumnName("responsable_usuario_id");
            entity.Property(x => x.PesoBaseKg).HasColumnName("peso_base_kg").HasPrecision(18, 2);
            entity.Property(x => x.FechaFinEstimada).HasColumnName("fecha_fin_estimada");
            entity.Property(x => x.FechaInicio).HasColumnName("fecha_inicio");
            entity.Property(x => x.FechaFin).HasColumnName("fecha_fin");
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(800);
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });

        modelBuilder.Entity<OrdenConsumoPlanificadoWriteModel>(entity =>
        {
            entity.ToTable("orden_consumo_planificado");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.OrdenProcesoId).HasColumnName("orden_proceso_id");
            entity.Property(x => x.FormulaVersionId).HasColumnName("formula_version_id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.Porcentaje).HasColumnName("porcentaje").HasPrecision(9, 4);
            entity.Property(x => x.CantidadPlanificada).HasColumnName("cantidad_planificada").HasPrecision(18, 4);
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });

        modelBuilder.Entity<OrdenConsumoRealWriteModel>(entity =>
        {
            entity.ToTable("orden_consumo_real");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.OrdenProcesoId).HasColumnName("orden_proceso_id");
            entity.Property(x => x.SalidaInventarioDetalleId).HasColumnName("salida_inventario_detalle_id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.CantidadConsumida).HasColumnName("cantidad_consumida").HasPrecision(18, 4);
            entity.Property(x => x.CostoUnitario).HasColumnName("costo_unitario").HasPrecision(18, 4);
            entity.Property(x => x.EsExtra).HasColumnName("es_extra");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });

        modelBuilder.Entity<DesviacionConsumoWriteModel>(entity =>
        {
            entity.ToTable("desviacion_consumo");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenConsumoPlanificadoId).HasColumnName("orden_consumo_planificado_id");
            entity.Property(x => x.OrdenConsumoRealId).HasColumnName("orden_consumo_real_id");
            entity.Property(x => x.CantidadPlanificada).HasColumnName("cantidad_planificada").HasPrecision(18, 4);
            entity.Property(x => x.CantidadReal).HasColumnName("cantidad_real").HasPrecision(18, 4);
            entity.Property(x => x.Motivo).HasColumnName("motivo").HasMaxLength(300);
            entity.Property(x => x.RegistradoEn).HasColumnName("registrado_en");
        });

        modelBuilder.Entity<MermaProcesoWriteModel>(entity =>
        {
            entity.ToTable("merma_proceso");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.OrdenProcesoId).HasColumnName("orden_proceso_id");
            entity.Property(x => x.CantidadPerdida).HasColumnName("cantidad_perdida").HasPrecision(18, 4);
            entity.Property(x => x.Motivo).HasColumnName("motivo").HasMaxLength(300);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
            entity.Property(x => x.RegistradoEn).HasColumnName("registrado_en");
            entity.Property(x => x.RegistradoPorUsuarioId).HasColumnName("registrado_por_usuario_id");
        });

        modelBuilder.Entity<ControlCalidadWriteModel>(entity =>
        {
            entity.ToTable("control_calidad");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.ProductoTerminadoId).HasColumnName("producto_terminado_id");
            entity.Property(x => x.CalidadProductoId).HasColumnName("calidad_producto_id");
            entity.Property(x => x.Resultado).HasColumnName("resultado").HasMaxLength(30);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(800);
            entity.Property(x => x.EvaluadoEn).HasColumnName("evaluado_en");
            entity.Property(x => x.EvaluadoPorUsuarioId).HasColumnName("evaluado_por_usuario_id");
        });

        modelBuilder.Entity<ProductoTerminadoWriteModel>(entity =>
        {
            entity.ToTable("producto_terminado");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.CalidadProductoId).HasColumnName("calidad_producto_id");
            entity.Property(x => x.FechaIngreso).HasColumnName("fecha_ingreso");
            entity.Property(x => x.CantidadPielesBuenas).HasColumnName("cantidad_pieles_buenas").HasPrecision(18, 4);
            entity.Property(x => x.CantidadLados).HasColumnName("cantidad_lados").HasPrecision(18, 2);
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
        });

        modelBuilder.Entity<SolicitudInsumoWriteModel>(entity =>
        {
            entity.ToTable("solicitud_insumo");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.OrdenProcesoId).HasColumnName("orden_proceso_id");
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
            entity.Property(x => x.SolicitadoEn).HasColumnName("solicitado_en");
            entity.Property(x => x.SolicitadoPorUsuarioId).HasColumnName("solicitado_por_usuario_id");
        });

        modelBuilder.Entity<SolicitudInsumoDetalleWriteModel>(entity =>
        {
            entity.ToTable("solicitud_insumo_detalle");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.SolicitudInsumoId).HasColumnName("solicitud_insumo_id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.CantidadSolicitada).HasColumnName("cantidad_solicitada").HasPrecision(18, 2);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(300);
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

        foreach (var entry in ChangeTracker.Entries<ClienteWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }

            if (entry.State == EntityState.Modified)
            {
                entry.Entity.ActualizadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<LoteWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<OrdenProduccionWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }

            if (entry.State == EntityState.Modified)
            {
                entry.Entity.ActualizadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<OrdenProduccionProcesoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<OrdenConsumoPlanificadoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<OrdenConsumoRealWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<DesviacionConsumoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.RegistradoEn == default)
            {
                entry.Entity.RegistradoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<MermaProcesoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.RegistradoEn == default)
            {
                entry.Entity.RegistradoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<ControlCalidadWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.EvaluadoEn == default)
            {
                entry.Entity.EvaluadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<ProductoTerminadoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.FechaIngreso == default)
            {
                entry.Entity.FechaIngreso = now;
            }
        }
    }
}
