using System.Net.Http.Json;
using ErpCurtiembre.Api.IntegrationTests.Contracts;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Services;
using Microsoft.Data.SqlClient;

namespace ErpCurtiembre.Api.IntegrationTests.Infrastructure;

public sealed class SeguridadTestFixture : IAsyncLifetime
{
    private const string ConnectionString =
        "Server=(localdb)\\MSSQLLocalDB;Database=ERP_Curtiembre;Integrated Security=true;TrustServerCertificate=True;";
    private const string IntegrationUserPrefix = "itest.%";
    private readonly Pbkdf2PasswordHasher _passwordHasher = new();

    public const string AdminUserName = "itest.admin.seguridad";
    public const string AdminPassword = "ITestAdmin9A";
    public const long AdminRolId = 1;
    public const long AdminAreaId = 1;
    public const string AdminPermissionCode = "USUARIOS_ADMIN";

    public SeguridadApiFactory Factory { get; } = new();

    public async Task InitializeAsync()
    {
        await CleanupIntegrationUsersAsync();
        await EnsureAdminRolePermissionAsync();
        await SeedAdminUserAsync();
    }

    public async Task DisposeAsync()
    {
        await CleanupIntegrationUsersAsync();
        Factory.Dispose();
    }

    public HttpClient CreateClient() => Factory.CreateClient();

    internal Task<LoginResponse> LoginAsAdminAsync() => LoginAsync(AdminUserName, AdminPassword);

    internal async Task<LoginResponse> LoginAsync(string userName, string password)
    {
        using var client = CreateClient();
        using var response = await client.PostAsJsonAsync("/api/seguridad/auth/login", new
        {
            userName,
            password
        });

        response.EnsureSuccessStatusCode();
        var result = await response.Content.ReadFromJsonAsync<LoginResponse>();
        return result ?? throw new InvalidOperationException("No se pudo leer la respuesta de login.");
    }

    private async Task CleanupIntegrationUsersAsync()
    {
        const string sql = """
            ;WITH target_users AS (
                SELECT id
                FROM seguridad.usuario
                WHERE usuario LIKE @PrefixLike
            )
            DELETE FROM seguridad.auditoria_seguridad
            WHERE usuario_afectado_id IN (SELECT id FROM target_users)
               OR usuario_accion_id IN (SELECT id FROM target_users);

            ;WITH target_users AS (
                SELECT id
                FROM seguridad.usuario
                WHERE usuario LIKE @PrefixLike
            )
            DELETE FROM seguridad.sesion_usuario
            WHERE usuario_id IN (SELECT id FROM target_users);

            ;WITH target_users AS (
                SELECT id
                FROM seguridad.usuario
                WHERE usuario LIKE @PrefixLike
            )
            DELETE FROM seguridad.intento_login
            WHERE usuario_id IN (SELECT id FROM target_users)
               OR usuario_login LIKE @PrefixLike;

            DELETE FROM seguridad.usuario
            WHERE usuario LIKE @PrefixLike;
            """;

        await using var connection = await OpenConnectionAsync();
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@PrefixLike", IntegrationUserPrefix);
        await command.ExecuteNonQueryAsync();
    }

    private async Task EnsureAdminRolePermissionAsync()
    {
        const string sql = """
            INSERT INTO seguridad.rol_permiso (rol_id, permiso_id)
            SELECT @RolId, p.id
            FROM seguridad.permiso p
            WHERE p.codigo = @PermissionCode
              AND NOT EXISTS (
                  SELECT 1
                  FROM seguridad.rol_permiso rp
                  WHERE rp.rol_id = @RolId
                    AND rp.permiso_id = p.id
              );
            """;

        await using var connection = await OpenConnectionAsync();
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@RolId", AdminRolId);
        command.Parameters.AddWithValue("@PermissionCode", AdminPermissionCode);
        await command.ExecuteNonQueryAsync();
    }

    private async Task SeedAdminUserAsync()
    {
        const string sql = """
            INSERT INTO seguridad.usuario (
                rol_id,
                area_id,
                nombres,
                apellidos,
                dni,
                usuario,
                password_hash,
                debe_cambiar_password,
                intentos_fallidos,
                activo,
                creado_en
            )
            VALUES (
                @RolId,
                @AreaId,
                @Nombres,
                @Apellidos,
                @Dni,
                @Usuario,
                @PasswordHash,
                0,
                0,
                1,
                SYSUTCDATETIME()
            );
            """;

        await using var connection = await OpenConnectionAsync();
        await using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@RolId", AdminRolId);
        command.Parameters.AddWithValue("@AreaId", AdminAreaId);
        command.Parameters.AddWithValue("@Nombres", "Integration");
        command.Parameters.AddWithValue("@Apellidos", "Admin");
        command.Parameters.AddWithValue("@Dni", "99990001");
        command.Parameters.AddWithValue("@Usuario", AdminUserName);
        command.Parameters.AddWithValue("@PasswordHash", _passwordHasher.HashPassword(AdminPassword));
        await command.ExecuteNonQueryAsync();
    }

    private static async Task<SqlConnection> OpenConnectionAsync()
    {
        var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync();
        return connection;
    }
}
