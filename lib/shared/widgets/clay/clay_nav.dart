import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/widgets/clay/clay_surface.dart';
import 'package:flutter/material.dart';

class ClayNavRail extends StatelessWidget {
  const ClayNavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ClayNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: ClaySurface(
        radius: ClayTokens.radiusXl,
        depth: ClayDepth.floating,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) => _ClayNavTile(
            item: items[i],
            selected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
        ),
      ),
    );
  }
}

class ClayBottomNav extends StatelessWidget {
  const ClayBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ClayNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClaySurface(
        radius: ClayTokens.radiusXl,
        depth: ClayDepth.floating,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _ClayNavTile(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                  compact: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ClayNavItem {
  const ClayNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _ClayNavTile extends StatelessWidget {
  const _ClayNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final ClayNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 14,
            vertical: compact ? 10 : 12,
          ),
          decoration: selected
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ClayTokens.accent.withValues(alpha: 0.2),
                      ClayTokens.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
                  boxShadow: ClayDecorations.clayPressedShadows(),
                )
              : null,
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: selected ? ClayTokens.accent : ClayTokens.muted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? ClayTokens.accent : ClayTokens.muted,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: selected ? ClayTokens.accent : ClayTokens.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTypography.body(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? ClayTokens.accent : ClayTokens.muted,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
