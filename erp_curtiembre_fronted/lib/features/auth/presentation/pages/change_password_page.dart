import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/change_password_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/change_password_state.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/buttons/app_button.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/feedback/app_message_card.dart';
import 'package:erp_curtiembre_fronted/shared/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<ChangePasswordCubit>().submit(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ChangePasswordStatus.success &&
          current.result != null,
      listener: (context, state) {
        final result = state.result;
        if (result == null) {
          return;
        }

        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.read<AuthCubit>().replaceSession(result.session);
      },
      builder: (context, state) {
        final isSubmitting = state.status == ChangePasswordStatus.submitting;

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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      children: [
                        const _ChangePasswordPanel(),
                        const Gap(AppSpacing.xl),
                        _ChangePasswordFormCard(
                          formKey: _formKey,
                          currentPasswordController: _currentPasswordController,
                          newPasswordController: _newPasswordController,
                          confirmPasswordController: _confirmPasswordController,
                          obscureCurrentPassword: _obscureCurrentPassword,
                          obscureNewPassword: _obscureNewPassword,
                          obscureConfirmPassword: _obscureConfirmPassword,
                          errorMessage: state.errorMessage,
                          isSubmitting: isSubmitting,
                          onToggleCurrentPassword: () => setState(
                            () => _obscureCurrentPassword =
                                !_obscureCurrentPassword,
                          ),
                          onToggleNewPassword: () => setState(
                            () => _obscureNewPassword = !_obscureNewPassword,
                          ),
                          onToggleConfirmPassword: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          onSubmit: _submit,
                        ),
                        const Gap(AppSpacing.lg),
                        Text(
                          '© CITEccal Trujillo · Sistema de Gestión de Curtiembre',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChangePasswordPanel extends StatelessWidget {
  const _ChangePasswordPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.factory_outlined,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const Gap(AppSpacing.md),
        Text('ERP Curtiembre', style: theme.textTheme.titleLarge),
        const Gap(AppSpacing.xs),
        Text(
          'Industrial Premium Cálido',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChangePasswordFormCard extends StatelessWidget {
  const _ChangePasswordFormCard({
    required this.formKey,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureCurrentPassword,
    required this.obscureNewPassword,
    required this.obscureConfirmPassword,
    required this.errorMessage,
    required this.isSubmitting,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureCurrentPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final String? errorMessage;
  final bool isSubmitting;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;
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
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cambiar contrasena',
                  style: theme.textTheme.headlineSmall,
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Antes de ingresar, define una nueva contrasena segura para tu cuenta.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.xl),
                const AppMessageCard.warning(
                  title: 'Accion requerida',
                  message:
                      'Debes actualizar tu contrasena antes de continuar con el sistema.',
                ),
                if (errorMessage != null) ...[
                  const Gap(AppSpacing.lg),
                  AppMessageCard.error(
                    title: 'No pudimos actualizar la contrasena',
                    message: errorMessage!,
                  ),
                ],
                const Gap(AppSpacing.xl),
                AppTextField(
                  controller: currentPasswordController,
                  label: 'Contrasena actual',
                  hintText: 'Ingresa tu contrasena actual',
                  prefixIcon: Icons.lock_outline,
                  obscureText: obscureCurrentPassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  suffixIcon: IconButton(
                    tooltip: obscureCurrentPassword
                        ? 'Mostrar contrasena'
                        : 'Ocultar contrasena',
                    onPressed: onToggleCurrentPassword,
                    icon: Icon(
                      obscureCurrentPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return 'Ingresa tu contrasena actual.';
                    }

                    return null;
                  },
                ),
                const Gap(AppSpacing.lg),
                AppTextField(
                  controller: newPasswordController,
                  label: 'Nueva contrasena',
                  hintText: 'Minimo 8 caracteres',
                  prefixIcon: Icons.password_outlined,
                  obscureText: obscureNewPassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  suffixIcon: IconButton(
                    tooltip: obscureNewPassword
                        ? 'Mostrar contrasena'
                        : 'Ocultar contrasena',
                    onPressed: onToggleNewPassword,
                    icon: Icon(
                      obscureNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) {
                      return 'Ingresa una nueva contrasena.';
                    }

                    if (text.length < 8) {
                      return 'La contrasena debe tener al menos 8 caracteres.';
                    }

                    return null;
                  },
                ),
                const Gap(AppSpacing.xs),
                Text(
                  'Mínimo 8 caracteres.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(AppSpacing.lg),
                AppTextField(
                  controller: confirmPasswordController,
                  label: 'Confirmar nueva contrasena',
                  hintText: 'Repite tu nueva contrasena',
                  prefixIcon: Icons.verified_user_outlined,
                  obscureText: obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => onSubmit(),
                  suffixIcon: IconButton(
                    tooltip: obscureConfirmPassword
                        ? 'Mostrar contrasena'
                        : 'Ocultar contrasena',
                    onPressed: onToggleConfirmPassword,
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) {
                      return 'Confirma la nueva contrasena.';
                    }

                    if (text != newPasswordController.text) {
                      return 'Las contrasenas no coinciden.';
                    }

                    return null;
                  },
                ),
                const Gap(AppSpacing.xl),
                AppButton.primary(
                  label: 'Actualizar contrasena',
                  icon: Icons.lock_reset_outlined,
                  isLoading: isSubmitting,
                  onPressed: onSubmit,
                ),
                const Gap(AppSpacing.md),
                Text(
                  'Usa una contrasena que solo tu conozcas y evita compartirla con otros usuarios.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
                      'Actualizando contrasena...',
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
