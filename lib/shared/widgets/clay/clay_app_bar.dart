import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/widgets/clay/clay_surface.dart';
import 'package:flutter/material.dart';

class ClayAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ClayAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClaySurface(
        radius: ClayTokens.radiusXl,
        depth: ClayDepth.floating,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (leading != null) leading!,
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: ClayTokens.primaryGradient,
                borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
                boxShadow: ClayDecorations.clayButtonShadows(),
              ),
              child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTypography.heading(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ClayTokens.foreground,
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
