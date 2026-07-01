import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

/// Carrossel horizontal de filtros no mobile, com indicador de páginas.
class FilterCarouselLayout extends StatefulWidget {
  const FilterCarouselLayout({
    super.key,
    required this.items,
    this.itemHeight = 84,
    this.viewportFraction = 0.86,
    this.trailing,
    this.pagePadding = const EdgeInsets.only(right: 10),
  });

  final List<Widget> items;
  final double itemHeight;
  final double viewportFraction;
  final Widget? trailing;
  final EdgeInsets pagePadding;

  static const mobileBreakpoint = 640.0;

  @override
  State<FilterCarouselLayout> createState() => _FilterCarouselLayoutState();
}

class _FilterCarouselLayoutState extends State<FilterCarouselLayout> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void didUpdateWidget(FilterCarouselLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.items.length && widget.items.isNotEmpty) {
      _page = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    if (widget.items.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.items.first,
          if (widget.trailing != null) ...[
            const SizedBox(height: 8),
            widget.trailing!,
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CarouselHintRow(
          pageCount: widget.items.length,
          currentPage: _page,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: widget.itemHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            padEnds: false,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: widget.pagePadding,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: widget.items[index],
                ),
              );
            },
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(height: 8),
          widget.trailing!,
        ],
      ],
    );
  }
}

class _CarouselHintRow extends StatelessWidget {
  const _CarouselHintRow({
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.swipe_rounded,
          size: 18,
          color: ClayTokens.primary.withValues(alpha: 0.75),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Deslize para ver filtros · ${currentPage + 1}/$pageCount',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ClayTokens.textSecondary,
            ),
          ),
        ),
        _PageDots(count: pageCount, index: currentPage),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(left: 4),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
            color: active
                ? ClayTokens.primary
                : ClayTokens.primary.withValues(alpha: 0.22),
          ),
        );
      }),
    );
  }
}
