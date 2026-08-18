using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;

namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface IUsuarioRepository
{
    Task<bool> HasAnyUserAsync(CancellationToken cancellationToken);

    Task<Usuario?> FindByUserNameAsync(string userName, CancellationToken cancellationToken);

    Task<Usuario?> FindByIdAsync(long usuarioId, CancellationToken cancellationToken);

    Task<bool> ExistsByUserNameAsync(string userName, long? excludeUserId, CancellationToken cancellationToken);

    Task<bool> ExistsByDniAsync(string dni, long? excludeUserId, CancellationToken cancellationToken);

    Task<long> CreateAsync(Usuario usuario, CancellationToken cancellationToken);

    Task UpdateAsync(Usuario usuario, CancellationToken cancellationToken);

    Task UpdatePasswordAsync(
        long usuarioId,
        string passwordHash,
        bool debeCambiarPassword,
        long? actorId,
        DateTime updatedAt,
        CancellationToken cancellationToken);

    Task<int> IncrementFailedAttemptsAsync(long usuarioId, CancellationToken cancellationToken);

    Task ResetFailedAttemptsAsync(long usuarioId, CancellationToken cancellationToken);

    Task BlockUntilAsync(long usuarioId, DateTime blockedUntil, CancellationToken cancellationToken);

    Task UpdateLoginSuccessAsync(long usuarioId, DateTime loggedAt, CancellationToken cancellationToken);

    Task DeactivateAsync(long usuarioId, long actorId, DateTime updatedAt, CancellationToken cancellationToken);

    Task ReactivateAsync(long usuarioId, long actorId, DateTime updatedAt, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Usuario>> ListAsync(UserFiltersDto filters, CancellationToken cancellationToken);
}
