namespace ErpCurtiembre.Modules.Inventario.Domain.Services;

public sealed class InboundStockCalculator
{
    public InboundStockProjection Calculate(
        decimal stockActual,
        decimal costoPromedioActual,
        decimal stockMinimo,
        decimal cantidadEntrada,
        decimal costoUnitarioEntrada)
    {
        if (stockActual < 0)
        {
            throw new InvalidOperationException("El stock actual no puede ser negativo.");
        }

        if (costoPromedioActual < 0)
        {
            throw new InvalidOperationException("El costo promedio actual no puede ser negativo.");
        }

        if (stockMinimo < 0)
        {
            throw new InvalidOperationException("El stock minimo no puede ser negativo.");
        }

        if (cantidadEntrada <= 0)
        {
            throw new InvalidOperationException("La cantidad de entrada debe ser mayor que 0.");
        }

        if (costoUnitarioEntrada < 0)
        {
            throw new InvalidOperationException("El costo unitario de entrada no puede ser negativo.");
        }

        var nuevoStock = decimal.Round(stockActual + cantidadEntrada, 4);
        var nuevoCostoPromedio = nuevoStock == 0
            ? 0
            : decimal.Round(
                ((stockActual * costoPromedioActual) + (cantidadEntrada * costoUnitarioEntrada)) / nuevoStock,
                4);

        if (nuevoStock < 0)
        {
            throw new InvalidOperationException("La operacion generaria un stock negativo.");
        }

        if (nuevoCostoPromedio < 0)
        {
            throw new InvalidOperationException("La operacion generaria un costo promedio invalido.");
        }

        return new InboundStockProjection(
            nuevoStock,
            nuevoCostoPromedio,
            decimal.Round(cantidadEntrada * costoUnitarioEntrada, 2),
            nuevoStock <= stockMinimo ? "BAJO_STOCK" : "STOCK_OK");
    }
}

public sealed record InboundStockProjection(
    decimal NuevoStock,
    decimal NuevoCostoPromedio,
    decimal CostoTotal,
    string EstadoStock);
