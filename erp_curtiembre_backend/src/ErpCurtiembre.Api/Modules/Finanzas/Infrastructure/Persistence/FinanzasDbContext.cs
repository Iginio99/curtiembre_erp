using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Time;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;

public sealed class FinanzasDbContext(
    DbContextOptions<FinanzasDbContext> options,
    IDateTimeProvider dateTimeProvider) : DbContext(options)
{
    public DbSet<PeriodoCostoWriteModel> PeriodosCosto => Set<PeriodoCostoWriteModel>();

    public DbSet<CostoIndirectoWriteModel> CostosIndirectos => Set<CostoIndirectoWriteModel>();

    public DbSet<ManoObraDirectaWriteModel> ManosObraDirecta => Set<ManoObraDirectaWriteModel>();

    public DbSet<ActivoDepreciableWriteModel> ActivosDepreciables => Set<ActivoDepreciableWriteModel>();

    public DbSet<DepreciacionPeriodoWriteModel> DepreciacionesPeriodo => Set<DepreciacionPeriodoWriteModel>();

    public DbSet<CostoProcesoWriteModel> CostosProceso => Set<CostoProcesoWriteModel>();

    public DbSet<CostoOrdenWriteModel> CostosOrden => Set<CostoOrdenWriteModel>();

    public DbSet<PrecioSugeridoWriteModel> PreciosSugeridos => Set<PrecioSugeridoWriteModel>();

    public DbSet<RentabilidadOrdenWriteModel> RentabilidadesOrden => Set<RentabilidadOrdenWriteModel>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("finanzas");

        modelBuilder.Entity<PeriodoCostoWriteModel>(entity =>
        {
            entity.ToTable("periodo_costo");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Anio).HasColumnName("anio");
            entity.Property(x => x.Mes).HasColumnName("mes");
            entity.Property(x => x.FechaInicio).HasColumnName("fecha_inicio");
            entity.Property(x => x.FechaFin).HasColumnName("fecha_fin");
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.CerradoEn).HasColumnName("cerrado_en");
            entity.Property(x => x.CerradoPorUsuarioId).HasColumnName("cerrado_por_usuario_id");
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
        });

        modelBuilder.Entity<CostoIndirectoWriteModel>(entity =>
        {
            entity.ToTable("costo_indirecto");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.PeriodoCostoId).HasColumnName("periodo_costo_id");
            entity.Property(x => x.TipoCosto).HasColumnName("tipo_costo").HasMaxLength(80);
            entity.Property(x => x.Descripcion).HasColumnName("descripcion").HasMaxLength(300);
            entity.Property(x => x.Monto).HasColumnName("monto").HasPrecision(18, 2);
            entity.Property(x => x.RegistradoEn).HasColumnName("registrado_en");
            entity.Property(x => x.RegistradoPorUsuarioId).HasColumnName("registrado_por_usuario_id");
        });

        modelBuilder.Entity<ManoObraDirectaWriteModel>(entity =>
        {
            entity.ToTable("mano_obra_directa");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.OrdenProcesoId).HasColumnName("orden_proceso_id");
            entity.Property(x => x.Monto).HasColumnName("monto").HasPrecision(18, 2);
            entity.Property(x => x.Descripcion).HasColumnName("descripcion").HasMaxLength(300);
            entity.Property(x => x.RegistradoEn).HasColumnName("registrado_en");
            entity.Property(x => x.RegistradoPorUsuarioId).HasColumnName("registrado_por_usuario_id");
        });

        modelBuilder.Entity<ActivoDepreciableWriteModel>(entity =>
        {
            entity.ToTable("activo_depreciable");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.Nombre).HasColumnName("nombre").HasMaxLength(150);
            entity.Property(x => x.ValorCompra).HasColumnName("valor_compra").HasPrecision(18, 2);
            entity.Property(x => x.FechaCompra).HasColumnName("fecha_compra");
            entity.Property(x => x.VidaUtilMeses).HasColumnName("vida_util_meses");
            entity.Property(x => x.ValorResidual).HasColumnName("valor_residual").HasPrecision(18, 2);
            entity.Property(x => x.Activo).HasColumnName("activo");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });

        modelBuilder.Entity<DepreciacionPeriodoWriteModel>(entity =>
        {
            entity.ToTable("depreciacion_periodo");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.PeriodoCostoId).HasColumnName("periodo_costo_id");
            entity.Property(x => x.ActivoDepreciableId).HasColumnName("activo_depreciable_id");
            entity.Property(x => x.MontoDepreciacion).HasColumnName("monto_depreciacion").HasPrecision(18, 2);
            entity.Property(x => x.CalculadoEn).HasColumnName("calculado_en");
        });

        modelBuilder.Entity<CostoProcesoWriteModel>(entity =>
        {
            entity.ToTable("costo_proceso");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.OrdenProcesoId).HasColumnName("orden_proceso_id");
            entity.Property(x => x.CostoInsumos).HasColumnName("costo_insumos").HasPrecision(18, 2);
            entity.Property(x => x.CostoManoObra).HasColumnName("costo_mano_obra").HasPrecision(18, 2);
            entity.Property(x => x.CalculadoEn).HasColumnName("calculado_en");
        });

        modelBuilder.Entity<CostoOrdenWriteModel>(entity =>
        {
            entity.ToTable("costo_orden");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.PeriodoCostoId).HasColumnName("periodo_costo_id");
            entity.Property(x => x.CostoPieles).HasColumnName("costo_pieles").HasPrecision(18, 2);
            entity.Property(x => x.CostoInsumos).HasColumnName("costo_insumos").HasPrecision(18, 2);
            entity.Property(x => x.CostoManoObra).HasColumnName("costo_mano_obra").HasPrecision(18, 2);
            entity.Property(x => x.CostoIndirectoAsignado).HasColumnName("costo_indirecto_asignado").HasPrecision(18, 2);
            entity.Property(x => x.CostoDepreciacionAsignado).HasColumnName("costo_depreciacion_asignado").HasPrecision(18, 2);
            entity.Property(x => x.PielesBuenasFinales).HasColumnName("pieles_buenas_finales").HasPrecision(18, 4);
            entity.Property(x => x.CostoPorPiel).HasColumnName("costo_por_piel").HasPrecision(18, 4);
            entity.Property(x => x.CostoEstimado).HasColumnName("costo_estimado").HasPrecision(18, 2);
            entity.Property(x => x.CostoReal).HasColumnName("costo_real").HasPrecision(18, 2);
            entity.Property(x => x.Estado).HasColumnName("estado").HasMaxLength(30);
            entity.Property(x => x.CalculadoEn).HasColumnName("calculado_en");
            entity.Property(x => x.CalculadoPorUsuarioId).HasColumnName("calculado_por_usuario_id");
        });

        modelBuilder.Entity<PrecioSugeridoWriteModel>(entity =>
        {
            entity.ToTable("precio_sugerido");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.CostoBaseSinIgv).HasColumnName("costo_base_sin_igv").HasPrecision(18, 2);
            entity.Property(x => x.MargenPorcentaje).HasColumnName("margen_porcentaje").HasPrecision(9, 4);
            entity.Property(x => x.IgvPorcentaje).HasColumnName("igv_porcentaje").HasPrecision(9, 4);
            entity.Property(x => x.CalculadoEn).HasColumnName("calculado_en");
        });

        modelBuilder.Entity<RentabilidadOrdenWriteModel>(entity =>
        {
            entity.ToTable("rentabilidad_orden");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.OrdenProduccionId).HasColumnName("orden_produccion_id");
            entity.Property(x => x.PrecioVenta).HasColumnName("precio_venta").HasPrecision(18, 2);
            entity.Property(x => x.CostoTotal).HasColumnName("costo_total").HasPrecision(18, 2);
            entity.Property(x => x.MargenPorcentaje).HasColumnName("margen_porcentaje").HasPrecision(9, 4);
            entity.Property(x => x.CalculadoEn).HasColumnName("calculado_en");
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

        foreach (var entry in ChangeTracker.Entries<CostoIndirectoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.RegistradoEn == default)
            {
                entry.Entity.RegistradoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<ManoObraDirectaWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.RegistradoEn == default)
            {
                entry.Entity.RegistradoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<ActivoDepreciableWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<DepreciacionPeriodoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CalculadoEn == default)
            {
                entry.Entity.CalculadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<CostoProcesoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CalculadoEn == default)
            {
                entry.Entity.CalculadoEn = now;
            }

            if (entry.State == EntityState.Modified)
            {
                entry.Entity.CalculadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<CostoOrdenWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CalculadoEn == default)
            {
                entry.Entity.CalculadoEn = now;
            }

            if (entry.State == EntityState.Modified)
            {
                entry.Entity.CalculadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<PrecioSugeridoWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CalculadoEn == default)
            {
                entry.Entity.CalculadoEn = now;
            }

            if (entry.State == EntityState.Modified)
            {
                entry.Entity.CalculadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<RentabilidadOrdenWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CalculadoEn == default)
            {
                entry.Entity.CalculadoEn = now;
            }

            if (entry.State == EntityState.Modified)
            {
                entry.Entity.CalculadoEn = now;
            }
        }
    }
}
