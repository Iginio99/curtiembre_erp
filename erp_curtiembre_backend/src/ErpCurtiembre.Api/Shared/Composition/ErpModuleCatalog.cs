using ErpCurtiembre.Modules.Alertas;
using ErpCurtiembre.Modules.Auditoria;
using ErpCurtiembre.Modules.Configuracion;
using ErpCurtiembre.Modules.Finanzas;
using ErpCurtiembre.Modules.Inventario;
using ErpCurtiembre.Modules.Produccion;
using ErpCurtiembre.Modules.Reportes;
using ErpCurtiembre.Modules.Seguridad;
using ErpCurtiembre.Shared.Abstractions;

namespace ErpCurtiembre.Shared.Composition;

public static class ErpModuleCatalog
{
    public static readonly IReadOnlyList<IErpModule> Modules =
    [
        new SeguridadModule(),
        new ConfiguracionModule(),
        new InventarioModule(),
        new ProduccionModule(),
        new FinanzasModule(),
        new AlertasModule(),
        new ReportesModule(),
        new AuditoriaModule()
    ];

    public static IReadOnlyList<string> ModuleNames => Modules.Select(module => module.Name).ToArray();
}
