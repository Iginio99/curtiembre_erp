namespace ErpCurtiembre.Modules.Configuracion.Application.DTOs;

public sealed record ParametroConfiguracionDto(
    long Id,
    string Clave,
    string Valor,
    string? Descripcion,
    string TipoDato,
    bool Editable,
    DateTime? ActualizadoEn);
