namespace ErpCurtiembre.Modules.Reportes.Application.DTOs;

public sealed record ComprasProveedorReporteFiltersDto(
    long? ProveedorId = null,
    string? Estado = null,
    DateTime? FechaDesde = null,
    DateTime? FechaHasta = null);

public sealed record ComprasProveedorReporteDto(
    long ProveedorId,
    string RucDocumento,
    string Proveedor,
    int TotalOrdenes,
    decimal CantidadSolicitadaTotal,
    decimal CantidadRecibidaTotal,
    decimal MontoEstimadoTotal,
    decimal MontoRecibidoTotal,
    DateTime? PrimeraCompra,
    DateTime? UltimaCompra);
