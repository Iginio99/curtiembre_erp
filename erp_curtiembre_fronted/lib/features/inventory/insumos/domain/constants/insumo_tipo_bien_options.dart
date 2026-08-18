class InsumoTipoBienOption {
  const InsumoTipoBienOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

const inventoryInsumoTipoBienOptions = [
  InsumoTipoBienOption(
    value: 'INSUMO_QUIMICO',
    label: 'Insumo quimico',
  ),
  InsumoTipoBienOption(
    value: 'MATERIA_PRIMA',
    label: 'Materia prima',
  ),
  InsumoTipoBienOption(
    value: 'PRODUCTO_TERMINADO',
    label: 'Producto terminado',
  ),
];
