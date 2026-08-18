using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.Ports;

public interface IFormulaRepository
{
    Task<bool> ExistsFormulaByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken);

    Task<Formula?> FindFormulaByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Formula>> ListFormulasAsync(FormulaFiltersDto filters, CancellationToken cancellationToken);

    Task<long> CreateFormulaAsync(Formula formula, long? createdByUsuarioId, CancellationToken cancellationToken);

    Task UpdateFormulaAsync(Formula formula, CancellationToken cancellationToken);

    Task SetFormulaActiveAsync(long id, bool activo, CancellationToken cancellationToken);

    Task<bool> HasAnyVigenteVersionAsync(long formulaId, CancellationToken cancellationToken);

    Task<bool> IsProcesoProductivoActiveAsync(long procesoProductivoId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ProcesoProductivoCatalogItem>> ListActiveProcesosProductivosAsync(CancellationToken cancellationToken);

    Task<FormulaVersion?> FindVersionByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<FormulaVersion>> ListVersionsAsync(long formulaId, CancellationToken cancellationToken);

    Task<bool> ExistsVersionNumberAsync(long formulaId, int numeroVersion, long? excludeId, CancellationToken cancellationToken);

    Task<bool> HasVersionDateOverlapAsync(
        long formulaId,
        DateTime fechaInicioVigencia,
        DateTime? fechaFinVigencia,
        long? excludeId,
        CancellationToken cancellationToken);

    Task<long> CreateVersionAsync(FormulaVersion version, long? createdByUsuarioId, CancellationToken cancellationToken);

    Task UpdateVersionAsync(FormulaVersion version, CancellationToken cancellationToken);

    Task SetVersionVigenteAsync(long formulaId, long versionId, CancellationToken cancellationToken);

    Task<bool> VersionHasActiveDetailsAsync(long versionId, CancellationToken cancellationToken);

    Task<FormulaDetalle?> FindDetailByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<FormulaDetalle>> ListDetailsByVersionIdAsync(long versionId, CancellationToken cancellationToken);

    Task<bool> ExistsActiveDetailInsumoAsync(long versionId, long insumoId, long? excludeId, CancellationToken cancellationToken);

    Task<bool> IsInsumoActiveAsync(long insumoId, CancellationToken cancellationToken);

    Task<long> CreateDetailAsync(FormulaDetalle detail, CancellationToken cancellationToken);

    Task UpdateDetailAsync(FormulaDetalle detail, CancellationToken cancellationToken);

    Task SoftDeleteDetailAsync(long id, CancellationToken cancellationToken);

    Task CloneActiveDetailsAsync(long sourceVersionId, long targetVersionId, CancellationToken cancellationToken);
}
