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
        radius: ClayTokens.radiusLg,
        depth: ClayDepth.floating,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _ClayNavTile(
                item: items[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
              if (i < items.length - 1) const SizedBox(height: 6),
            ],
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
        borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 12,
            vertical: compact ? 8 : 10,
          ),
          decoration: selected
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ClayTokens.primary.withValues(alpha: 0.18),
                      ClayTokens.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                  boxShadow: ClayDecorations.insetShadows(depth: 0.6),
                )
              : null,
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: selected ? ClayTokens.primary : ClayTokens.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? ClayTokens.primary : ClayTokens.textMuted,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: selected ? ClayTokens.primary : ClayTokens.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? ClayTokens.primary : ClayTokens.textSecondary,
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
