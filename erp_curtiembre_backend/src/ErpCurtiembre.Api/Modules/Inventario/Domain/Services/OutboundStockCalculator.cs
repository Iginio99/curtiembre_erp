namespace ErpCurtiembre.Modules.Inventario.Domain.Services;

public sealed class OutboundStockCalculator
{
    public OutboundStockProjection Calculate(
        decimal stockActual,
        decimal costoPromedioActual,
        decimal stockMinimo,
        decimal cantidadSalida)
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

        if (cantidadSalida <= 0)
        {
            throw new InvalidOperationException("La cantidad de salida debe ser mayor que 0.");
        }

        if (cantidadSalida > stockActual)
        {
            throw new InvalidOperationException("La salida solicitada supera el stock disponible.");
        }

        var nuevoStock = decimal.Round(stockActual - cantidadSalida, 4);

        return new OutboundStockProjection(
            nuevoStock,
            decimal.Round(costoPromedioActual, 4),
            decimal.Round(costoPromedioActual * cantidadSalida, 2),
            nuevoStock <= stockMinimo ? "BAJO_STOCK" : "STOCK_OK");
    }
}

public sealed record OutboundStockProjection(
    decimal NuevoStock,
    decimal CostoUnitario,
    decimal CostoTotal,
    string EstadoStock);
