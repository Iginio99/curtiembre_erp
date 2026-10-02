import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // =========================================================
  // CONTROLADORES Y ESTADO
  // =========================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _userNameController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  late final Future<String> _appVersionFuture;

  // =========================================================
  // PALETA DE COLORES
  // =========================================================

  static const Color _primary = Color(0xFFE8590C);
  static const Color _copper = Color(0xFFC47740);

  static const Color _background = Color(0xFF17191C);
  static const Color _cardBackground = Color(0xF21C1F23);
  static const Color _fieldBackground = Color(0xFF24272C);

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _muted = Color(0xFFAEB0B7);

  static const Color _softOrange = Color(0xFFFFA36A);

  // =========================================================
  // CICLO DE VIDA
  // =========================================================

  @override
  void initState() {
    super.initState();
    _appVersionFuture = _loadAppVersion();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // VERSION DEL SISTEMA
  // =========================================================

  Future<String> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      return 'Versión ${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {
      return 'Versión no disponible';
    }
  }

  // =========================================================
  // AUTENTICACION
  // =========================================================

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authCubit = context.read<AuthCubit>();

    if (authCubit.state.status == AuthStatus.authenticating) {
      return;
    }

    authCubit.signIn(
      userName: _userNameController.text.trim(),
      password: _passwordController.text,
    );
  }

  // =========================================================
  // VISTA PRINCIPAL
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.noticeMessage != current.noticeMessage &&
          current.noticeMessage != null,
      listener: (context, state) {
        final noticeMessage = state.noticeMessage;

        if (noticeMessage == null) {
          return;
        }

        final messenger = ScaffoldMessenger.of(context);

        messenger.hideCurrentSnackBar();

        messenger.showSnackBar(
          SnackBar(
            content: Text(noticeMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.read<AuthCubit>().clearNotice();
      },
      builder: (context, state) {
        final isSubmitting = state.status == AuthStatus.authenticating;

        return Scaffold(
          backgroundColor: _background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // =============================================
              // IMAGEN INDUSTRIAL DE FONDO
              // =============================================
              Positioned.fill(
                child: Image.asset(
                  'assets/images/curtiembre_login_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    // Fondo alternativo mientras se añade
                    // la fotografía a los assets.
                    return const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3C281C),
                            Color(0xFF26211F),
                            Color(0xFF17191C),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // =============================================
              // DEGRADADO OSCURO SOBRE LA FOTOGRAFIA
              // =============================================
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.0, 0.42, 0.72, 1.0],
                      colors: [
                        Color(0xA6110E0C),
                        Color(0xA61A1613),
                        Color(0xD9181A1D),
                        Color(0xF2181A1D),
                      ],
                    ),
                  ),
                ),
              ),

              // =============================================
              // CONTENIDO RESPONSIVE
              // =============================================
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 1050;

                    if (isDesktop) {
                      return _buildDesktop(
                        state: state,
                        isSubmitting: isSubmitting,
                      );
                    }

                    return _buildCompact(
                      state: state,
                      isSubmitting: isSubmitting,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // DISTRIBUCION PARA ESCRITORIO
  // =========================================================

  Widget _buildDesktop({required AuthState state, required bool isSubmitting}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 65, vertical: 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo superior.
          _buildBrandHeader(),

          // Contenido central.
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // =========================================
                // PANEL IZQUIERDO
                // =========================================
                Expanded(flex: 11, child: _buildHeroSection()),

                const SizedBox(width: 55),

                // =========================================
                // PANEL DERECHO - FORMULARIO
                // =========================================
                Expanded(
                  flex: 9,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 505),
                      child: SingleChildScrollView(
                        child: _buildLoginCard(
                          state: state,
                          isSubmitting: isSubmitting,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pie de página.
          _buildFooter(),
        ],
      ),
    );
  }

  // =========================================================
  // DISTRIBUCION TABLET Y MOVIL
  // =========================================================

  Widget _buildCompact({required AuthState state, required bool isSubmitting}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 27),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBrandHeader(compact: true),

              const SizedBox(height: 45),

              const Text(
                'Gestión inteligente\npara tu curtiembre.',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Producción, inventario, calidad y trazabilidad '
                'en un solo sistema.',
                style: TextStyle(
                  color: Color(0xFFD0CBC7),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 32),

              _buildLoginCard(state: state, isSubmitting: isSubmitting),

              const SizedBox(height: 38),

              _buildFooter(compact: true),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOGO / IDENTIDAD DEL ERP
  // =========================================================

  Widget _buildBrandHeader({bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: compact ? 43 : 55,
          width: compact ? 43 : 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _copper.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.workspace_premium_outlined,
            color: _softOrange,
            size: compact ? 26 : 33,
          ),
        ),

        const SizedBox(width: 15),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CITEccal Trujillo ERP',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: compact ? 19 : 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'GESTIÓN DE CURTIEMBRE',
              style: TextStyle(
                color: const Color(0xFFD9AA87),
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.1,
              ),
            ),
          ],
        ),

        if (!compact) ...[
          const SizedBox(width: 26),

          Container(
            height: 42,
            width: 1,
            color: Colors.white.withValues(alpha: 0.35),
          ),

          const SizedBox(width: 24),

          const Text(
            'PRODUCCIÓN · INVENTARIO\n'
            'CALIDAD · TRAZABILIDAD',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFDDD3CA),
              letterSpacing: 1.7,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================
  // PANEL IZQUIERDO: PRESENTACION
  // =========================================================

  Widget _buildHeroSection() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controla tu curtiembre',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: Colors.white,
                fontSize: 48,
                height: 1.14,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.2,
              ),
            ),

            const Text(
              'con visión de futuro',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: _softOrange,
                fontSize: 48,
                height: 1.17,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.2,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Una entrada segura al sistema para gestionar '
              'todas las operaciones de tu curtiembre.',
              style: TextStyle(
                color: Color(0xFFE0DBD6),
                fontSize: 18,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),

            _buildFeatureItem(
              icon: Icons.shield_outlined,
              title: 'Acceso seguro',
              description: 'Autenticación protegida para todo el personal.',
            ),

            const SizedBox(height: 24),

            _buildFeatureItem(
              icon: Icons.receipt_long_outlined,
              title: 'Auditoría completa',
              description:
                  'Registro detallado de transacciones y modificaciones.',
            ),

            const SizedBox(height: 24),

            _buildFeatureItem(
              icon: Icons.groups_2_outlined,
              title: 'Roles y permisos',
              description:
                  'Control de acceso basado en responsabilidades operativas.',
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ELEMENTOS INFORMATIVOS
  // =========================================================

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 48,
          width: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.19),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _copper.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: _softOrange, size: 24),
        ),

        const SizedBox(width: 17),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFFC8C2BD),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TARJETA PRINCIPAL DE LOGIN
  // =========================================================

  Widget _buildLoginCard({
    required AuthState state,
    required bool isSubmitting,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 37),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 38,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // =========================================
              // ENCABEZADO DEL LOGIN
              // =========================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            color: _white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10),

                        Text(
                          'Accede al sistema de gestión de curtiembre.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.workspace_premium_outlined,
                    color: Color(0x665C371F),
                    size: 42,
                  ),
                ],
              ),

              // =========================================
              // MENSAJE DE ERROR
              // =========================================
              if (state.errorMessage != null) ...[
                const SizedBox(height: 23),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF592B2B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF9F4B4B)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFFFB4AB),
                        size: 20,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFFFD4CE),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // =========================================
              // USUARIO
              // =========================================
              _buildInput(
                controller: _userNameController,
                hint: 'Usuario',
                icon: Icons.person_outline_rounded,
                action: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Ingresa tu usuario para continuar.';
                  }

                  if (text.length < 3) {
                    return 'Ingresa un usuario válido.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 17),

              // =========================================
              // CONTRASEÑA
              // =========================================
              _buildInput(
                controller: _passwordController,
                hint: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                action: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                suffix: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                    color: _muted,
                  ),
                ),
                validator: (value) {
                  final text = value ?? '';

                  if (text.isEmpty) {
                    return 'Ingresa tu contraseña.';
                  }

                  if (text.length < 8) {
                    return 'La contraseña debe tener al menos 8 caracteres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 9),

              // =========================================
              // INDICACION DE CONTRASEÑA
              // =========================================
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: _muted),

                  SizedBox(width: 6),

                  Text(
                    'Mínimo 8 caracteres',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),

              const SizedBox(height: 31),

              // =========================================
              // BOTON INGRESAR
              // =========================================
              SizedBox(
                width: double.infinity,
                height: 49,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFE78A43), Color(0xFFB85D28)],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submit,
                    icon: isSubmitting
                        ? const SizedBox(
                            height: 17,
                            width: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded, size: 19),
                    label: Text(
                      isSubmitting
                          ? 'Validando credenciales...'
                          : 'Ingresar al sistema',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Divider(height: 1, color: Colors.white.withValues(alpha: 0.13)),

              const SizedBox(height: 20),

              // =========================================
              // TEXTO DE SOPORTE
              // =========================================
              const SizedBox(
                width: double.infinity,
                child: Text(
                  'Si no recuerdas tus datos de acceso, '
                  'solicita apoyo al administrador del sistema.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: _muted, height: 1.5),
                ),
              ),

              const SizedBox(height: 29),

              Divider(height: 1, color: Colors.white.withValues(alpha: 0.13)),

              const SizedBox(height: 19),

              // =========================================
              // VERSION DEL ERP
              // =========================================
              FutureBuilder<String>(
                future: _appVersionFuture,
                builder: (context, snapshot) {
                  final version = snapshot.data ?? 'Cargando versión...';

                  return Center(
                    child: Text(
                      version,
                      style: const TextStyle(
                        color: Color(0xFF93969C),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CAMPO PERSONALIZADO
  // =========================================================

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputAction? action,
    Iterable<String>? autofillHints,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      cursorColor: _softOrange,
      style: const TextStyle(color: _white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF93969F), fontSize: 12),
        prefixIcon: Icon(icon, color: _muted, size: 19),
        suffixIcon: suffix,
        filled: true,
        fillColor: _fieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 17,
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFA69C), fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF41454B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF41454B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFD96C62)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFD96C62), width: 1.4),
        ),
      ),
    );
  }

  // =========================================================
  // PIE DE PAGINA
  // =========================================================

  Widget _buildFooter({bool compact = false}) {
    if (compact) {
      return const Center(
        child: Text(
          'MATERIA PRIMA  ·  PROCESOS  ·  CALIDAD\n'
          'CITEccal TRUJILLO ERP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            height: 2,
            color: Color(0xFFCEB4A0),
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(width: 43, height: 1.5, color: _copper),

        const SizedBox(width: 16),

        const Text(
          'MATERIA PRIMA   |   PROCESOS   |   '
          'CALIDAD   |   PRODUCTO FINAL',
          style: TextStyle(
            color: Color(0xFFCEBDB0),
            fontSize: 9,
            letterSpacing: 1.8,
          ),
        ),

        const SizedBox(width: 25),

        Expanded(
          child: Container(height: 1, color: _copper.withValues(alpha: 0.55)),
        ),

        const SizedBox(width: 23),

        const Text(
          'TRADICIÓN QUE PRODUCE VALOR',
          style: TextStyle(
            color: _softOrange,
            fontSize: 9,
            letterSpacing: 2.1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
