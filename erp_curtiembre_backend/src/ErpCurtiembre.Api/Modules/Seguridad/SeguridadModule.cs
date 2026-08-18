using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Users;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Repositories;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Services;
using ErpCurtiembre.Modules.Seguridad.Presentation.Endpoints;
using ErpCurtiembre.Shared.Abstractions;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace ErpCurtiembre.Modules.Seguridad;

public sealed class SeguridadModule : IErpModule
{
    public string Name => "Seguridad";

    public void RegisterServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();
        services.AddSingleton<IPasswordHasher, Pbkdf2PasswordHasher>();
        services.AddSingleton<ISessionTokenService, SessionTokenService>();
        services.AddSingleton<ILoginPolicyProvider, LoginPolicyProvider>();

        services.AddDbContext<SeguridadDbContext>((serviceProvider, options) =>
        {
            var databaseOptions = serviceProvider.GetRequiredService<IOptions<DatabaseOptions>>().Value;
            options.UseSqlServer(databaseOptions.DefaultConnection);
        });

        services.AddScoped<IUsuarioRepository, SqlUsuarioRepository>();
        services.AddScoped<IRolRepository, SqlRolRepository>();
        services.AddScoped<IPermisoRepository, SqlPermisoRepository>();
        services.AddScoped<ISesionRepository, SqlSesionRepository>();
        services.AddScoped<IAuditoriaSeguridadRepository, SqlAuditoriaSeguridadRepository>();
        services.AddScoped<ILoginAttemptRepository, SqlLoginAttemptRepository>();
        services.AddScoped<IAreaLookupRepository, SqlAreaLookupRepository>();

        services.AddScoped<LoginUseCase>();
        services.AddScoped<ValidateSessionUseCase>();
        services.AddScoped<LogoutUseCase>();
        services.AddScoped<ChangePasswordUseCase>();
        services.AddScoped<ListUsersUseCase>();
        services.AddScoped<GetUserDetailUseCase>();
        services.AddScoped<CreateUserUseCase>();
        services.AddScoped<UpdateUserUseCase>();
        services.AddScoped<DeactivateUserUseCase>();
        services.AddScoped<ReactivateUserUseCase>();
        services.AddScoped<ResetPasswordUseCase>();
        services.AddScoped<ListRolesUseCase>();
        services.AddScoped<ListPermissionsUseCase>();
        services.AddScoped<GetPermissionsByUserUseCase>();
        services.AddScoped<CheckPermissionUseCase>();
        services.AddScoped<ListAuditSecurityUseCase>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app) => app.MapSeguridadEndpoints();
}
