namespace ErpCurtiembre.Modules.Configuracion.Application.Ports;

public interface IDocumentSequenceService
{
    Task<string> GenerateNextAsync(string codigoDocumento, CancellationToken cancellationToken);
}
