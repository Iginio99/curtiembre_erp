import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton._({
    required this.isPrimary,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  factory AppButton.primary({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expand = true,
  }) {
    return AppButton._(
      isPrimary: true,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      expand: expand,
    );
  }

  factory AppButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool expand = false,
  }) {
    return AppButton._(
      isPrimary: false,
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      expand: expand,
    );
  }

  final bool isPrimary;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(
                    isPrimary
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(label),
            ],
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 10),
                  Text(label),
                ],
              )
            : Text(label);

    final button = isPrimary
        ? FilledButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          );

    if (!expand) {
      return button;
    }

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}
