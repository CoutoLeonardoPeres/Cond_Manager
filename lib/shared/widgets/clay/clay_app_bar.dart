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
        radius: ClayTokens.radiusLg,
        depth: ClayDepth.floating,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            if (leading != null) leading!,
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: ClayTokens.primaryGradient,
                borderRadius: BorderRadius.circular(ClayTokens.radiusXs),
                boxShadow: ClayDecorations.raisedShadows(depth: 0.5),
              ),
              child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
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
