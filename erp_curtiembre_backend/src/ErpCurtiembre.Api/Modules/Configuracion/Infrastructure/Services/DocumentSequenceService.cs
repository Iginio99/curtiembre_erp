using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Services;

public sealed class DocumentSequenceService(ConfiguracionDbContext dbContext) : IDocumentSequenceService
{
    public async Task<string> GenerateNextAsync(string codigoDocumento, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(codigoDocumento))
        {
            throw new InvalidOperationException("El codigo del documento es obligatorio para generar la secuencia.");
        }

        var normalizedCode = codigoDocumento.Trim().ToUpperInvariant();

        await using var transaction = await dbContext.Database.BeginTransactionAsync(
            System.Data.IsolationLevel.Serializable,
            cancellationToken);

        var sequence = await dbContext.SecuenciasDocumento
            .SingleOrDefaultAsync(
                x => x.CodigoDocumento == normalizedCode && x.Activo,
                cancellationToken);

        if (sequence is null)
        {
            throw new InvalidOperationException(
                $"No existe una secuencia activa para el documento '{normalizedCode}'.");
        }

        sequence.UltimoNumero += 1;
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return $"{sequence.Prefijo}-{sequence.UltimoNumero.ToString().PadLeft(sequence.LongitudNumero, '0')}";
    }
}
