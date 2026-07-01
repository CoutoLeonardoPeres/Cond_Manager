import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(isCompact ? 12 : 20, 8, isCompact ? 8 : 20, 0),
      child: Row(
        children: [
          if (leading != null) leading!,
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.heading(
                fontSize: isCompact ? 17 : 20,
                fontWeight: FontWeight.w700,
                color: ClayTokens.foreground,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
