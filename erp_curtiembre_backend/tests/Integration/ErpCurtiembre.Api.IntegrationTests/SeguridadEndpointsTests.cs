using System.Net;
using System.Net.Http.Json;
using ErpCurtiembre.Api.IntegrationTests.Contracts;
using ErpCurtiembre.Api.IntegrationTests.Infrastructure;
using FluentAssertions;

namespace ErpCurtiembre.Api.IntegrationTests;

public sealed class SeguridadEndpointsTests(SeguridadTestFixture fixture) : IClassFixture<SeguridadTestFixture>
{
    private static int _userSequence;
    private readonly SeguridadTestFixture _fixture = fixture;

    [Fact]
    public async Task Login_deberia_retornar_token_y_contexto_del_usuario()
    {
        var response = await _fixture.LoginAsAdminAsync();

        response.UserName.Should().Be(SeguridadTestFixture.AdminUserName);
        response.RolCodigo.Should().Be("ADMIN");
        response.SessionToken.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public async Task Me_deberia_retornar_la_sesion_activa()
    {
        var session = await _fixture.LoginAsAdminAsync();
        using var client = _fixture.CreateClient();
        using var request = CreateAuthorizedRequest(HttpMethod.Get, "/api/seguridad/auth/me", session.SessionToken);

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await ReadRequiredAsync<SessionInfoResponse>(response);
        body.UsuarioId.Should().Be(session.UsuarioId);
        body.UserName.Should().Be(SeguridadTestFixture.AdminUserName);
    }

    [Fact]
    public async Task Logout_deberia_invalidar_el_token()
    {
        var session = await _fixture.LoginAsAdminAsync();
        using var client = _fixture.CreateClient();

        using var logoutRequest = CreateAuthorizedRequest(HttpMethod.Post, "/api/seguridad/auth/logout", session.SessionToken);
        using var logoutResponse = await client.SendAsync(logoutRequest);

        logoutResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var logoutBody = await ReadRequiredAsync<LogoutResponse>(logoutResponse);
        logoutBody.Message.Should().Be("Sesion cerrada correctamente.");

        using var meRequest = CreateAuthorizedRequest(HttpMethod.Get, "/api/seguridad/auth/me", session.SessionToken);
        using var meResponse = await client.SendAsync(meRequest);

        meResponse.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task ChangePassword_deberia_actualizar_la_contrasena_del_usuario()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        var draft = NewUserDraft("TempPass9A");
        var createdUser = await CreateUserAsync(adminSession.SessionToken, draft);
        var userSession = await _fixture.LoginAsync(draft.UserName, draft.PasswordTemporal);

        using var client = _fixture.CreateClient();
        using var request = CreateAuthorizedJsonRequest(
            HttpMethod.Post,
            "/api/seguridad/auth/change-password",
            userSession.SessionToken,
            new
            {
                currentPassword = draft.PasswordTemporal,
                newPassword = "ChangedPass9A",
                confirmPassword = "ChangedPass9A"
            });

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await ReadRequiredAsync<LogoutResponse>(response);
        body.Message.Should().Be("Contrasena actualizada correctamente.");

        var relogin = await _fixture.LoginAsync(draft.UserName, "ChangedPass9A");
        relogin.UsuarioId.Should().Be(createdUser.Usuario.UsuarioId);
        relogin.DebeCambiarPassword.Should().BeFalse();
    }

    [Fact]
    public async Task Roles_y_permisos_deberian_devolver_catalogos_activos()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        using var client = _fixture.CreateClient();

        using var rolesRequest = CreateAuthorizedRequest(HttpMethod.Get, "/api/seguridad/roles", adminSession.SessionToken);
        using var rolesResponse = await client.SendAsync(rolesRequest);
        rolesResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var roles = await ReadRequiredAsync<RoleResponse[]>(rolesResponse);
        roles.Should().Contain(role => role.Codigo == "ADMIN" && role.Activo);

        using var permissionsRequest = CreateAuthorizedRequest(HttpMethod.Get, "/api/seguridad/permisos", adminSession.SessionToken);
        using var permissionsResponse = await client.SendAsync(permissionsRequest);
        permissionsResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var permissions = await ReadRequiredAsync<PermissionResponse[]>(permissionsResponse);
        permissions.Should().Contain(permission => permission.Codigo == SeguridadTestFixture.AdminPermissionCode && permission.Activo);
    }

    [Fact]
    public async Task CheckPermission_deberia_confirmar_el_permiso_admin()
    {
        var session = await _fixture.LoginAsAdminAsync();
        using var client = _fixture.CreateClient();
        using var request = CreateAuthorizedJsonRequest(
            HttpMethod.Post,
            "/api/seguridad/check-permission",
            session.SessionToken,
            new
            {
                usuarioId = session.UsuarioId,
                permissionCode = SeguridadTestFixture.AdminPermissionCode
            });

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await ReadRequiredAsync<CheckPermissionResponse>(response);
        body.Allowed.Should().BeTrue();
        body.PermissionCode.Should().Be(SeguridadTestFixture.AdminPermissionCode);
    }

    [Fact]
    public async Task Crear_usuario_y_consultar_su_detalle_deberia_funcionar()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        var draft = NewUserDraft("CreatePass9A");
        var created = await CreateUserAsync(adminSession.SessionToken, draft);

        created.PasswordTemporal.Should().Be(draft.PasswordTemporal);
        created.Usuario.UserName.Should().Be(draft.UserName);

        using var client = _fixture.CreateClient();
        using var detailRequest = CreateAuthorizedRequest(
            HttpMethod.Get,
            $"/api/seguridad/usuarios/{created.Usuario.UsuarioId}",
            adminSession.SessionToken);

        using var detailResponse = await client.SendAsync(detailRequest);

        detailResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var detail = await ReadRequiredAsync<UserDetailResponse>(detailResponse);
        detail.UsuarioId.Should().Be(created.Usuario.UsuarioId);
        detail.Dni.Should().Be(draft.Dni);
    }

    [Fact]
    public async Task Actualizar_usuario_deberia_persistir_los_cambios()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        var draft = NewUserDraft("UpdatePass9A");
        var created = await CreateUserAsync(adminSession.SessionToken, draft);
        var updatedDraft = draft with
        {
            Dni = NextDni(),
            Nombres = "Usuario",
            Apellidos = "Actualizado",
            UserName = $"{draft.UserName}.upd",
            RolId = 4,
            AreaId = 4
        };

        using var client = _fixture.CreateClient();
        using var request = CreateAuthorizedJsonRequest(
            HttpMethod.Put,
            $"/api/seguridad/usuarios/{created.Usuario.UsuarioId}",
            adminSession.SessionToken,
            new
            {
                dni = updatedDraft.Dni,
                nombres = updatedDraft.Nombres,
                apellidos = updatedDraft.Apellidos,
                userName = updatedDraft.UserName,
                rolId = updatedDraft.RolId,
                areaId = updatedDraft.AreaId
            });

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await ReadRequiredAsync<UserMutationResponse>(response);
        body.Usuario.UserName.Should().Be(updatedDraft.UserName);
        body.Usuario.RolCodigo.Should().Be("FINANZAS");
        body.Usuario.AreaNombre.Should().Be("Finanzas");

        using var auditRequest = CreateAuthorizedRequest(
            HttpMethod.Get,
            $"/api/seguridad/auditoria?usuarioAfectadoId={created.Usuario.UsuarioId}&evento=ROL_CAMBIADO",
            adminSession.SessionToken);

        using var auditResponse = await client.SendAsync(auditRequest);

        auditResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var auditItems = await ReadRequiredAsync<AuditItemResponse[]>(auditResponse);
        auditItems.Should().Contain(item => item.Evento == "ROL_CAMBIADO");
    }

    [Fact]
    public async Task Listar_usuarios_deberia_permitir_filtrar_por_texto()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        var draft = NewUserDraft("ListPass9A");
        var created = await CreateUserAsync(adminSession.SessionToken, draft);
        using var client = _fixture.CreateClient();
        var url = $"/api/seguridad/usuarios?texto={Uri.EscapeDataString(draft.UserName)}";
        using var request = CreateAuthorizedRequest(HttpMethod.Get, url, adminSession.SessionToken);

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var users = await ReadRequiredAsync<UserListItemResponse[]>(response);
        users.Should().Contain(user => user.UsuarioId == created.Usuario.UsuarioId && user.UserName == draft.UserName);
    }

    [Fact]
    public async Task Listar_usuarios_deberia_ocultar_inactivos_por_defecto()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        var draft = NewUserDraft("HiddenPass9A");
        var created = await CreateUserAsync(adminSession.SessionToken, draft);
        using var client = _fixture.CreateClient();

        using var deactivateRequest = CreateAuthorizedJsonRequest(
            HttpMethod.Post,
            $"/api/seguridad/usuarios/{created.Usuario.UsuarioId}/deactivate",
            adminSession.SessionToken,
            new { motivo = "Ocultar en lista operativa" });

        using var deactivateResponse = await client.SendAsync(deactivateRequest);
        deactivateResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        using var request = CreateAuthorizedRequest(
            HttpMethod.Get,
            $"/api/seguridad/usuarios?texto={Uri.EscapeDataString(draft.UserName)}",
            adminSession.SessionToken);

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var users = await ReadRequiredAsync<UserListItemResponse[]>(response);
        users.Should().NotContain(user => user.UsuarioId == created.Usuario.UsuarioId);
    }

    [Fact]
    public async Task Obtener_permisos_de_usuario_deberia_incluir_usuarios_admin()
    {
        var session = await _fixture.LoginAsAdminAsync();
        using var client = _fixture.CreateClient();
        using var request = CreateAuthorizedRequest(
            HttpMethod.Get,
            $"/api/seguridad/usuarios/{session.UsuarioId}/permisos",
            session.SessionToken);

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await ReadRequiredAsync<UserPermissionsResponse>(response);
        body.UsuarioId.Should().Be(session.UsuarioId);
        body.PermissionCodes.Should().Contain(SeguridadTestFixture.AdminPermissionCode);
    }

    [Fact]
    public async Task ResetPassword_deberia_permitir_login_con_la_password_temporal_nueva()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        var draft = NewUserDraft("BeforeReset9A");
        var created = await CreateUserAsync(adminSession.SessionToken, draft);

        using var client = _fixture.CreateClient();
        using var request = CreateAuthorizedJsonRequest(
            HttpMethod.Post,
            $"/api/seguridad/usuarios/{created.Usuario.UsuarioId}/reset-password",
            adminSession.SessionToken,
            new
            {
                passwordTemporal = "ResetPass9A"
            });

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await ReadRequiredAsync<LogoutResponse>(response);
        body.Message.Should().Contain("ResetPass9A");

        var relogin = await _fixture.LoginAsync(draft.UserName, "ResetPass9A");
        relogin.UsuarioId.Should().Be(created.Usuario.UsuarioId);
        relogin.DebeCambiarPassword.Should().BeTrue();
    }

    [Fact]
    public async Task Desactivar_y_reactivar_usuario_deberia_controlar_su_acceso()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        var draft = NewUserDraft("TogglePass9A");
        var created = await CreateUserAsync(adminSession.SessionToken, draft);

        using var client = _fixture.CreateClient();
        using var deactivateRequest = CreateAuthorizedJsonRequest(
            HttpMethod.Post,
            $"/api/seguridad/usuarios/{created.Usuario.UsuarioId}/deactivate",
            adminSession.SessionToken,
            new
            {
                motivo = "Desactivacion de prueba"
            });

        using var deactivateResponse = await client.SendAsync(deactivateRequest);

        deactivateResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        using var failedLoginResponse = await client.PostAsJsonAsync("/api/seguridad/auth/login", new
        {
            userName = draft.UserName,
            password = draft.PasswordTemporal
        });

        failedLoginResponse.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        var failedLoginBody = await ReadRequiredAsync<ErrorResponse>(failedLoginResponse);
        failedLoginBody.Error.Should().Be("invalid_credentials");
        failedLoginBody.Message.Should().Be("Usuario o contrasena incorrectos.");

        using var reactivateRequest = CreateAuthorizedJsonRequest(
            HttpMethod.Post,
            $"/api/seguridad/usuarios/{created.Usuario.UsuarioId}/reactivate",
            adminSession.SessionToken,
            new
            {
                motivo = "Reactivacion de prueba"
            });

        using var reactivateResponse = await client.SendAsync(reactivateRequest);

        reactivateResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var relogin = await _fixture.LoginAsync(draft.UserName, draft.PasswordTemporal);
        relogin.UsuarioId.Should().Be(created.Usuario.UsuarioId);
    }

    [Fact]
    public async Task Login_deberia_bloquear_usuario_tras_cinco_intentos_fallidos_y_responder_mensaje_generico()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        var draft = NewUserDraft("BlockPass9A");
        var created = await CreateUserAsync(adminSession.SessionToken, draft);
        using var client = _fixture.CreateClient();

        for (var intento = 1; intento <= 5; intento++)
        {
            using var failedResponse = await client.PostAsJsonAsync("/api/seguridad/auth/login", new
            {
                userName = draft.UserName,
                password = "WrongPass9A"
            });

            failedResponse.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
            var failedBody = await ReadRequiredAsync<ErrorResponse>(failedResponse);
            failedBody.Error.Should().Be("invalid_credentials");
            failedBody.Message.Should().Be("Usuario o contrasena incorrectos.");
        }

        using var blockedResponse = await client.PostAsJsonAsync("/api/seguridad/auth/login", new
        {
            userName = draft.UserName,
            password = draft.PasswordTemporal
        });

        blockedResponse.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        var blockedBody = await ReadRequiredAsync<ErrorResponse>(blockedResponse);
        blockedBody.Error.Should().Be("invalid_credentials");
        blockedBody.Message.Should().Be("Usuario o contrasena incorrectos.");

        using var auditRequest = CreateAuthorizedRequest(
            HttpMethod.Get,
            $"/api/seguridad/auditoria?usuarioAfectadoId={created.Usuario.UsuarioId}&evento=USUARIO_BLOQUEADO",
            adminSession.SessionToken);

        using var auditResponse = await client.SendAsync(auditRequest);

        auditResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var auditItems = await ReadRequiredAsync<AuditItemResponse[]>(auditResponse);
        auditItems.Should().Contain(item => item.Evento == "USUARIO_BLOQUEADO");
    }

    [Fact]
    public async Task Auditoria_deberia_reflejar_eventos_recientes()
    {
        var adminSession = await _fixture.LoginAsAdminAsync();
        var draft = NewUserDraft("AuditPass9A");
        var created = await CreateUserAsync(adminSession.SessionToken, draft);
        using var client = _fixture.CreateClient();
        using var request = CreateAuthorizedRequest(
            HttpMethod.Get,
            $"/api/seguridad/auditoria?usuarioAfectadoId={created.Usuario.UsuarioId}",
            adminSession.SessionToken);

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var items = await ReadRequiredAsync<AuditItemResponse[]>(response);
        items.Should().Contain(item =>
            item.UsuarioAfectadoId == created.Usuario.UsuarioId &&
            item.Evento == "USUARIO_CREADO");
    }

    private async Task<UserMutationResponse> CreateUserAsync(string adminToken, TestUserDraft draft)
    {
        using var client = _fixture.CreateClient();
        using var request = CreateAuthorizedJsonRequest(
            HttpMethod.Post,
            "/api/seguridad/usuarios",
            adminToken,
            new
            {
                dni = draft.Dni,
                nombres = draft.Nombres,
                apellidos = draft.Apellidos,
                userName = draft.UserName,
                rolId = draft.RolId,
                areaId = draft.AreaId,
                passwordTemporal = draft.PasswordTemporal
            });

        using var response = await client.SendAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        return await ReadRequiredAsync<UserMutationResponse>(response);
    }

    private static HttpRequestMessage CreateAuthorizedRequest(HttpMethod method, string uri, string token)
    {
        var request = new HttpRequestMessage(method, uri);
        request.Headers.Add("X-Session-Token", token);
        return request;
    }

    private static HttpRequestMessage CreateAuthorizedJsonRequest(HttpMethod method, string uri, string token, object body)
    {
        var request = CreateAuthorizedRequest(method, uri, token);
        request.Content = JsonContent.Create(body);
        return request;
    }

    private static async Task<T> ReadRequiredAsync<T>(HttpResponseMessage response)
    {
        var payload = await response.Content.ReadFromJsonAsync<T>();
        return payload ?? throw new InvalidOperationException($"No se pudo deserializar {typeof(T).Name}.");
    }

    private static TestUserDraft NewUserDraft(string passwordTemporal)
    {
        var sequence = Interlocked.Increment(ref _userSequence);
        return new TestUserDraft(
            NextDni(),
            $"ITest{sequence}",
            "Seguridad",
            $"itest.user.{sequence}",
            2,
            2,
            passwordTemporal);
    }

    private static string NextDni()
    {
        var sequence = Interlocked.Increment(ref _userSequence);
        return (90_000_000 + sequence).ToString();
    }

    private sealed record TestUserDraft(
        string Dni,
        string Nombres,
        string Apellidos,
        string UserName,
        long RolId,
        long AreaId,
        string PasswordTemporal);
}
