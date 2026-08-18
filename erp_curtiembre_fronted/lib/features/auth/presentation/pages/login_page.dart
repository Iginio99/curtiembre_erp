import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final Future<String> _appVersionFuture;

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

  Future<String> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return 'Version ${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {
      return 'Version no disponible';
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthCubit>().signIn(
      userName: _userNameController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surfaceContainerLowest,
                  theme.scaffoldBackgroundColor,
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide =
                      constraints.maxWidth >= AppBreakpoints.mobileLarge;
                  final isDesktop =
                      constraints.maxWidth >= AppBreakpoints.tablet;

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(
                          flex: 5,
                          child: _LoginBrandPanel(fullBleed: true),
                        ),
                        Expanded(
                          flex: 7,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLowest,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: _LoginFormCard(
                                  formKey: _formKey,
                                  userNameController: _userNameController,
                                  passwordController: _passwordController,
                                  obscurePassword: _obscurePassword,
                                  errorMessage: state.errorMessage,
                                  isSubmitting: isSubmitting,
                                  appVersionFuture: _appVersionFuture,
                                  onTogglePassword: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  onSubmit: _submit,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? AppSpacing.xl : AppSpacing.lg,
                          vertical: AppSpacing.lg,
                        ),
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: const _LoginBrandPanel(),
                                  ),
                                  const Gap(AppSpacing.xl),
                                  Expanded(
                                    flex: 12,
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 420,
                                        ),
                                        child: _LoginFormCard(
                                          formKey: _formKey,
                                          userNameController:
                                              _userNameController,
                                          passwordController:
                                              _passwordController,
                                          obscurePassword: _obscurePassword,
                                          errorMessage: state.errorMessage,
                                          isSubmitting: isSubmitting,
                                          appVersionFuture: _appVersionFuture,
                                          onTogglePassword: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          onSubmit: _submit,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const _CompactHeader(),
                                    const Gap(AppSpacing.xl),
                                    _LoginFormCard(
                                      formKey: _formKey,
                                      userNameController: _userNameController,
                                      passwordController: _passwordController,
                                      obscurePassword: _obscurePassword,
                                      errorMessage: state.errorMessage,
                                      isSubmitting: isSubmitting,
                                      appVersionFuture: _appVersionFuture,
                                      onTogglePassword: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      onSubmit: _submit,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel({this.fullBleed = false});

  final bool fullBleed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: fullBleed ? null : const BoxConstraints(minHeight: 560),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(fullBleed ? 0 : 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'ERP Curtiembre · Seguridad',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
          const Gap(AppSpacing.xxl),
          Text(
            'Controla el acceso con una entrada clara, segura y lista para operar.',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const Gap(AppSpacing.lg),
          Text(
            'Ingresa con tu usuario autorizado para continuar con las operaciones del sistema.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.5,
            ),
          ),
          const Gap(AppSpacing.xl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _InsightChip(
                label: 'Acceso seguro',
                description: 'Autenticación encriptada para todo el personal.',
                icon: Icons.fingerprint_rounded,
              ),
              Gap(AppSpacing.lg),
              _InsightChip(
                label: 'Auditoría completa',
                description:
                    'Registro detallado de transacciones y modificaciones.',
                icon: Icons.history_edu_outlined,
              ),
              Gap(AppSpacing.lg),
              _InsightChip(
                label: 'Roles estrictos',
                description:
                    'Control de acceso basado en responsabilidades operativas.',
                icon: Icons.admin_panel_settings_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.factory_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            'ERP Curtiembre',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            'CITEccal Trujillo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            'Acceso seguro para operar el sistema.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.userNameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.errorMessage,
    required this.isSubmitting,
    required this.appVersionFuture,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController userNameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? errorMessage;
  final bool isSubmitting;
  final Future<String> appVersionFuture;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Iniciar sesion', style: theme.textTheme.headlineSmall),
                  const Gap(AppSpacing.sm),
                  Text(
                    'Ingresa tus credenciales para acceder al sistema.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const Gap(AppSpacing.xl),
                    AppMessageCard.error(
                      title: 'No pudimos acceder',
                      message: errorMessage!,
                    ),
                  ],
                  const Gap(AppSpacing.xl),
                  AppTextField(
                    controller: userNameController,
                    label: 'Usuario',
                    hintText: 'Ej. admin.seguridad',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Ingresa tu usuario para continuar.';
                      }

                      if (text.length < 3) {
                        return 'Ingresa un usuario valido.';
                      }

                      return null;
                    },
                  ),
                  const Gap(AppSpacing.lg),
                  AppTextField(
                    controller: passwordController,
                    label: 'Contrasena',
                    hintText: 'Minimo 8 caracteres',
                    prefixIcon: Icons.lock_outline,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => onSubmit(),
                    suffixIcon: IconButton(
                      tooltip: obscurePassword
                          ? 'Mostrar contrasena'
                          : 'Ocultar contrasena',
                      onPressed: onTogglePassword,
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) {
                        return 'Ingresa tu contrasena para continuar.';
                      }

                      if (text.length < 8) {
                        return 'La contrasena debe tener al menos 8 caracteres.';
                      }

                      return null;
                    },
                  ),
                  const Gap(AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Mínimo 8 caracteres',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.xl),
                  AppButton.primary(
                    label: 'Ingresar al sistema',
                    isLoading: isSubmitting,
                    onPressed: onSubmit,
                    icon: Icons.login_rounded,
                  ),
                  const Gap(AppSpacing.md),
                  Text(
                    'Si no recuerdas tus datos de acceso, solicita apoyo al administrador del sistema.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                  FutureBuilder<String>(
                    future: appVersionFuture,
                    builder: (context, snapshot) {
                      final versionText =
                          snapshot.data ?? 'Cargando version...';
                      return Align(
                        alignment: Alignment.center,
                        child: Text(
                          versionText,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isSubmitting)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Text(
                      'Validando credenciales...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
