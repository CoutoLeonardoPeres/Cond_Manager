import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/core/theme/clay_decorations.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

class ClayNavRail extends StatelessWidget {
  const ClayNavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.slim = true,
  });

  final List<ClayNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool slim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: slim ? 72 : 240,
      color: ClayTokens.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: ClayTokens.primaryGradient,
              borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
            ),
            child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ClayNavTile(
                item: items[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
                slim: slim,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: ClayTokens.sidebar,
        boxShadow: ClayDecorations.softShadows(blur: 16, offsetY: -2, opacity: 0.1),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
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
    this.slim = false,
  });

  final ClayNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final bool slim;

  @override
  Widget build(BuildContext context) {
    if (slim || compact) {
      return _buildIconTile();
    }
    return _buildLabeledTile();
  }

  Widget _buildIconTile() {
    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: selected
                    ? BoxDecoration(
                        color: ClayTokens.sidebarActive,
                        shape: BoxShape.circle,
                        boxShadow: ClayDecorations.softShadows(blur: 12, opacity: 0.15),
                      )
                    : null,
                child: Icon(
                  item.icon,
                  size: 22,
                  color: selected ? ClayTokens.accent : ClayTokens.sidebarMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: selected
              ? BoxDecoration(
                  color: ClayTokens.accentSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                  border: Border.all(color: ClayTokens.accent.withValues(alpha: 0.4), width: 1.5),
                )
              : null,
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 22,
                color: selected ? ClayTokens.accent : ClayTokens.sidebarMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? ClayTokens.sidebarActive : ClayTokens.textOnSidebar,
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
