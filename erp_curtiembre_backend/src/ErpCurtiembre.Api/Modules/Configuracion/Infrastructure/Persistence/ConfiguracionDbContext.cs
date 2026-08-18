using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Time;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;

public sealed class ConfiguracionDbContext(
    DbContextOptions<ConfiguracionDbContext> options,
    IDateTimeProvider dateTimeProvider) : DbContext(options)
{
    public DbSet<AreaWriteModel> Areas => Set<AreaWriteModel>();

    public DbSet<UnidadMedidaWriteModel> UnidadesMedida => Set<UnidadMedidaWriteModel>();

    public DbSet<TipoPielWriteModel> TiposPiel => Set<TipoPielWriteModel>();

    public DbSet<SecuenciaDocumentoWriteModel> SecuenciasDocumento => Set<SecuenciaDocumentoWriteModel>();

    public DbSet<FormulaWriteModel> Formulas => Set<FormulaWriteModel>();

    public DbSet<FormulaVersionWriteModel> FormulaVersions => Set<FormulaVersionWriteModel>();

    public DbSet<FormulaDetalleWriteModel> FormulaDetalles => Set<FormulaDetalleWriteModel>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("configuracion");

        modelBuilder.Entity<AreaWriteModel>(entity =>
        {
            entity.ToTable("area");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.Nombre).HasColumnName("nombre").HasMaxLength(100);
            entity.Property(x => x.Descripcion).HasColumnName("descripcion").HasMaxLength(250);
            entity.Property(x => x.Activo).HasColumnName("activo");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.ActualizadoEn).HasColumnName("actualizado_en");
        });

        modelBuilder.Entity<UnidadMedidaWriteModel>(entity =>
        {
            entity.ToTable("unidad_medida");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(20);
            entity.Property(x => x.Nombre).HasColumnName("nombre").HasMaxLength(80);
            entity.Property(x => x.PermiteDecimales).HasColumnName("permite_decimales");
            entity.Property(x => x.Activo).HasColumnName("activo");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });

        modelBuilder.Entity<TipoPielWriteModel>(entity =>
        {
            entity.ToTable("tipo_piel");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.Nombre).HasColumnName("nombre").HasMaxLength(120);
            entity.Property(x => x.Descripcion).HasColumnName("descripcion").HasMaxLength(250);
            entity.Property(x => x.Activo).HasColumnName("activo");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });

        modelBuilder.Entity<SecuenciaDocumentoWriteModel>(entity =>
        {
            entity.ToTable("secuencia_documento");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.CodigoDocumento).HasColumnName("codigo_documento").HasMaxLength(20);
            entity.Property(x => x.NombreDocumento).HasColumnName("nombre_documento").HasMaxLength(120);
            entity.Property(x => x.Prefijo).HasColumnName("prefijo").HasMaxLength(20);
            entity.Property(x => x.UltimoNumero).HasColumnName("ultimo_numero");
            entity.Property(x => x.LongitudNumero).HasColumnName("longitud_numero");
            entity.Property(x => x.Activo).HasColumnName("activo");
        });

        modelBuilder.Entity<FormulaWriteModel>(entity =>
        {
            entity.ToTable("formula");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.Codigo).HasColumnName("codigo").HasMaxLength(50);
            entity.Property(x => x.Nombre).HasColumnName("nombre").HasMaxLength(150);
            entity.Property(x => x.ProcesoProductivoId).HasColumnName("proceso_productivo_id");
            entity.Property(x => x.Descripcion).HasColumnName("descripcion").HasMaxLength(500);
            entity.Property(x => x.Activo).HasColumnName("activo");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.CreadoPorUsuarioId).HasColumnName("creado_por_usuario_id");
        });

        modelBuilder.Entity<FormulaVersionWriteModel>(entity =>
        {
            entity.ToTable("formula_version");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.FormulaId).HasColumnName("formula_id");
            entity.Property(x => x.NumeroVersion).HasColumnName("numero_version");
            entity.Property(x => x.FechaInicioVigencia).HasColumnName("fecha_inicio_vigencia");
            entity.Property(x => x.FechaFinVigencia).HasColumnName("fecha_fin_vigencia");
            entity.Property(x => x.Vigente).HasColumnName("vigente");
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(500);
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.CreadoPorUsuarioId).HasColumnName("creado_por_usuario_id");
        });

        modelBuilder.Entity<FormulaDetalleWriteModel>(entity =>
        {
            entity.ToTable("formula_detalle");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.FormulaVersionId).HasColumnName("formula_version_id");
            entity.Property(x => x.InsumoId).HasColumnName("insumo_id");
            entity.Property(x => x.Porcentaje).HasColumnName("porcentaje").HasPrecision(9, 4);
            entity.Property(x => x.Observacion).HasColumnName("observacion").HasMaxLength(300);
            entity.Property(x => x.Activo).HasColumnName("activo");
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

        foreach (var entry in ChangeTracker.Entries<AreaWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<UnidadMedidaWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<TipoPielWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<FormulaWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<FormulaVersionWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }
    }
}
