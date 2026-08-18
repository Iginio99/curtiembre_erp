namespace ErpCurtiembre.Modules.Configuracion.Domain.Entities;

public sealed record ParametroSistema(
    long Id,
    string Clave,
    string Valor,
    string? Descripcion,
    string TipoDato,
    bool Editable,
    DateTime? ActualizadoEn);
