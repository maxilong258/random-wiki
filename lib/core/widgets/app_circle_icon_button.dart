import 'package:flutter/material.dart';

class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(44),
        minimumSize: const Size.square(44),
        maximumSize: const Size.square(44),
        padding: EdgeInsets.zero,
        foregroundColor: colors.onSurface,
        disabledForegroundColor: colors.onSurface.withValues(alpha: 0.35),
        shape: CircleBorder(
          side: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
    );
  }
}
