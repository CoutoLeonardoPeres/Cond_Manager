import 'dart:math' as math;

import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

/// Pale mint gradient canvas with subtle teal accents.
class ClayBackground extends StatefulWidget {
  const ClayBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  final Widget child;
  final bool showOrbs;

  @override
  State<ClayBackground> createState() => _ClayBackgroundState();
}

class _ClayBackgroundState extends State<ClayBackground>
    with TickerProviderStateMixin {
  late final AnimationController _blob1;
  late final AnimationController _blob2;

  @override
  void initState() {
    super.initState();
    _blob1 = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat(reverse: true);
    _blob2 = AnimationController(vsync: this, duration: const Duration(seconds: 16))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blob1.dispose();
    _blob2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ClayTokens.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.showOrbs) ...[
            _AnimatedBlob(
              controller: _blob1,
              color: ClayTokens.accent,
              top: -0.08,
              right: -0.05,
              sizeFactor: 0.45,
              rotateSign: 1,
              enabled: !reduceMotion,
            ),
            _AnimatedBlob(
              controller: _blob2,
              color: ClayTokens.accentAlt,
              bottom: -0.1,
              left: -0.08,
              sizeFactor: 0.4,
              rotateSign: -1,
              delay: 0.4,
              enabled: !reduceMotion,
            ),
          ],
          widget.child,
        ],
      ),
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  const _AnimatedBlob({
    required this.controller,
    required this.color,
    required this.sizeFactor,
    required this.rotateSign,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.delay = 0,
    this.enabled = true,
  });

  final AnimationController controller;
  final Color color;
  final double sizeFactor;
  final int rotateSign;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double delay;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final blobSize = size.shortestSide * sizeFactor;

    return Positioned(
      top: top != null ? size.height * top! : null,
      left: left != null ? size.width * left! : null,
      right: right != null ? size.width * right! : null,
      bottom: bottom != null ? size.height * bottom! : null,
      child: enabled
          ? AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final t = (controller.value + delay) % 1.0;
                final y = math.sin(t * math.pi) * -12;
                return Transform.translate(offset: Offset(0, y), child: child);
              },
              child: _blob(blobSize, color),
            )
          : _blob(blobSize, color),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.06),
      ),
    );
  }
}
