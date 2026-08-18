using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Time;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence;

public sealed class SeguridadDbContext(
    DbContextOptions<SeguridadDbContext> options,
    IDateTimeProvider dateTimeProvider) : DbContext(options)
{
    public DbSet<UsuarioWriteModel> Usuarios => Set<UsuarioWriteModel>();

    public DbSet<SesionUsuarioWriteModel> SesionesUsuario => Set<SesionUsuarioWriteModel>();

    public DbSet<IntentoLoginWriteModel> IntentosLogin => Set<IntentoLoginWriteModel>();

    public DbSet<AuditoriaSeguridadWriteModel> AuditoriasSeguridad => Set<AuditoriaSeguridadWriteModel>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("seguridad");

        modelBuilder.Entity<UsuarioWriteModel>(entity =>
        {
            entity.ToTable("usuario");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.RolId).HasColumnName("rol_id");
            entity.Property(x => x.AreaId).HasColumnName("area_id");
            entity.Property(x => x.Nombres).HasColumnName("nombres").HasMaxLength(120);
            entity.Property(x => x.Apellidos).HasColumnName("apellidos").HasMaxLength(120);
            entity.Property(x => x.Dni).HasColumnName("dni").HasMaxLength(20);
            entity.Property(x => x.Usuario).HasColumnName("usuario").HasMaxLength(60);
            entity.Property(x => x.PasswordHash).HasColumnName("password_hash").HasMaxLength(255);
            entity.Property(x => x.DebeCambiarPassword).HasColumnName("debe_cambiar_password");
            entity.Property(x => x.IntentosFallidos).HasColumnName("intentos_fallidos");
            entity.Property(x => x.BloqueadoHasta).HasColumnName("bloqueado_hasta");
            entity.Property(x => x.UltimoLoginEn).HasColumnName("ultimo_login_en");
            entity.Property(x => x.Activo).HasColumnName("activo");
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
            entity.Property(x => x.CreadoPorUsuarioId).HasColumnName("creado_por_usuario_id");
            entity.Property(x => x.ActualizadoEn).HasColumnName("actualizado_en");
            entity.Property(x => x.ActualizadoPorUsuarioId).HasColumnName("actualizado_por_usuario_id");
        });

        modelBuilder.Entity<SesionUsuarioWriteModel>(entity =>
        {
            entity.ToTable("sesion_usuario");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.UsuarioId).HasColumnName("usuario_id");
            entity.Property(x => x.TokenHash).HasColumnName("token_hash").HasMaxLength(255);
            entity.Property(x => x.IpOrigen).HasColumnName("ip_origen").HasMaxLength(50);
            entity.Property(x => x.UserAgent).HasColumnName("user_agent").HasMaxLength(500);
            entity.Property(x => x.InicioEn).HasColumnName("inicio_en");
            entity.Property(x => x.ExpiraEn).HasColumnName("expira_en");
            entity.Property(x => x.CerradoEn).HasColumnName("cerrado_en");
            entity.Property(x => x.MotivoCierre).HasColumnName("motivo_cierre").HasMaxLength(100);
            entity.Property(x => x.Activa).HasColumnName("activa");
        });

        modelBuilder.Entity<IntentoLoginWriteModel>(entity =>
        {
            entity.ToTable("intento_login");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.UsuarioLogin).HasColumnName("usuario_login").HasMaxLength(60);
            entity.Property(x => x.UsuarioId).HasColumnName("usuario_id");
            entity.Property(x => x.FueExitoso).HasColumnName("fue_exitoso");
            entity.Property(x => x.IpOrigen).HasColumnName("ip_origen").HasMaxLength(50);
            entity.Property(x => x.Mensaje).HasColumnName("mensaje").HasMaxLength(250);
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });

        modelBuilder.Entity<AuditoriaSeguridadWriteModel>(entity =>
        {
            entity.ToTable("auditoria_seguridad");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id");
            entity.Property(x => x.UsuarioAfectadoId).HasColumnName("usuario_afectado_id");
            entity.Property(x => x.UsuarioAccionId).HasColumnName("usuario_accion_id");
            entity.Property(x => x.Evento).HasColumnName("evento").HasMaxLength(80);
            entity.Property(x => x.Descripcion).HasColumnName("descripcion").HasMaxLength(500);
            entity.Property(x => x.IpOrigen).HasColumnName("ip_origen").HasMaxLength(50);
            entity.Property(x => x.CreadoEn).HasColumnName("creado_en");
        });
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        StampSecurityDates();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void StampSecurityDates()
    {
        var now = dateTimeProvider.Now;

        foreach (var entry in ChangeTracker.Entries<UsuarioWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<IntentoLoginWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }

        foreach (var entry in ChangeTracker.Entries<AuditoriaSeguridadWriteModel>())
        {
            if (entry.State == EntityState.Added && entry.Entity.CreadoEn == default)
            {
                entry.Entity.CreadoEn = now;
            }
        }
    }
}
