class PersonalEmpresaOption {
  const PersonalEmpresaOption({
    required this.id,
    required this.nombre,
    required this.cargo,
  });

  final int id;
  final String nombre;
  final String cargo;

  String get label => '$nombre · $cargo';

  factory PersonalEmpresaOption.fromJson(Map<String, dynamic> json) =>
      PersonalEmpresaOption(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        cargo: json['cargo'] as String,
      );
}
