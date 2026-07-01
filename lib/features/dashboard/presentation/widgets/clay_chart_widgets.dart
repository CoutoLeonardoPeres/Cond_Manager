import 'dart:math' as math;

import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';

class ClayBarChart extends StatelessWidget {
  const ClayBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.barColor,
    this.secondaryValues,
    this.secondaryColor,
    this.height = 180,
    this.valueFormatter,
  });

  final List<String> labels;
  final List<double> values;
  final Color barColor;
  final List<double>? secondaryValues;
  final Color? secondaryColor;
  final double height;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    assert(labels.length == values.length);
  final secondary = secondaryValues;
    final allValues = [
      ...values,
      if (secondary != null) ...secondary,
    ];
    final maxVal = allValues.isEmpty ? 1.0 : allValues.reduce(math.max).clamp(1.0, double.infinity);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(labels.length, (i) {
          final primaryH = (values[i] / maxVal) * (height - 28);
          final secondaryH = secondary != null
              ? (secondary[i] / maxVal) * (height - 28)
              : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (secondary != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _Bar(
                            height: primaryH,
                            color: barColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: _Bar(
                            height: secondaryH,
                            color: secondaryColor ?? ClayTokens.textMuted,
                          ),
                        ),
                      ],
                    )
                  else
                    _Bar(height: primaryH, color: barColor),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: height < 100 ? 8 : 10,
                      color: ClayTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: height.clamp(2, double.infinity),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    );
  }
}

class ClayLineChart extends StatelessWidget {
  const ClayLineChart({
    super.key,
    required this.labels,
    required this.values,
    required this.lineColor,
    this.fillColor,
    this.height = 160,
  });

  final List<String> labels;
  final List<double> values;
  final Color lineColor;
  final Color? fillColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LineChartPainter(
          values: values,
          lineColor: lineColor,
          fillColor: fillColor ?? lineColor.withValues(alpha: 0.12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: List.generate(labels.length, (i) {
              return Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: ClayTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chartBottom = size.height - 22;
    final maxVal = values.reduce(math.max).clamp(1.0, double.infinity);
    final stepX = values.length <= 1 ? 0.0 : size.width / (values.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length <= 1 ? size.width / 2 : i * stepX;
      final y = chartBottom - (values[i] / maxVal) * (chartBottom - 12);
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, chartBottom);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, chartBottom);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotPaint);
      canvas.drawCircle(p, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.lineColor != lineColor;
}

class ClayHorizontalBarChart extends StatelessWidget {
  const ClayHorizontalBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.barColor,
    this.maxItems = 6,
    this.compact = false,
  });

  final List<String> labels;
  final List<double> values;
  final Color barColor;
  final int maxItems;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final count = math.min(labels.length, maxItems);
    if (count == 0) {
      return const Text(
        'Sem dados no período.',
        style: TextStyle(color: ClayTokens.textMuted, fontSize: 13),
      );
    }

    final sliceLabels = labels.take(count).toList();
    final sliceValues = values.take(count).toList();
    final maxVal = sliceValues.reduce(math.max).clamp(1.0, double.infinity);

    return Column(
      children: List.generate(count, (i) {
        final fraction = sliceValues[i] / maxVal;
        return Padding(
          padding: EdgeInsets.only(bottom: compact ? 4 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sliceLabels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${sliceValues[i].toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: compact ? 8 : 11,
                      color: ClayTokens.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 2 : 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(ClayTokens.radiusXs),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: compact ? 4 : 8,
                  backgroundColor: ClayTokens.accentSurface,
                  color: barColor,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ClayDonutChart extends StatelessWidget {
  const ClayDonutChart({
    super.key,
    required this.segments,
    this.size = 120,
    this.centerLabel,
    this.centerValue,
  });

  final List<({String label, double value, Color color})> segments;
  final double size;
  final String? centerLabel;
  final String? centerValue;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold(0.0, (s, e) => s + e.value);
    if (total <= 0) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Text('Sem dados', style: TextStyle(color: ClayTokens.textMuted, fontSize: 12)),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(segments: segments, total: total),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerValue != null)
                Text(
                  centerValue!,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: size < 80 ? 9 : 16,
                  ),
                ),
              if (centerLabel != null)
                Text(
                  centerLabel!,
                  style: TextStyle(
                    fontSize: size < 80 ? 7 : 10,
                    color: ClayTokens.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.total});

  final List<({String label, double value, Color color})> segments;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    var start = -math.pi / 2;
    final stroke = size.width * 0.18;

    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.total != total;
}

class ClayChartCard extends StatelessWidget {
  const ClayChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.legend,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? legend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: compact ? const EdgeInsets.all(8) : const EdgeInsets.all(22),
      radius: compact ? ClayTokens.radiusSm : ClayTokens.radiusCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 10 : 14,
              fontWeight: FontWeight.w800,
              color: ClayTokens.foreground,
            ),
          ),
          if (!compact && subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: ClayTokens.textSecondary)),
          ],
          SizedBox(height: compact ? 6 : 16),
          child,
          if (legend != null) ...[
            SizedBox(height: compact ? 4 : 12),
            legend!,
          ],
        ],
      ),
    );
  }
}

class ClayChartLegend extends StatelessWidget {
  const ClayChartLegend({super.key, required this.items});

  final List<({Color color, String label})> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(item.label, style: const TextStyle(fontSize: 11, color: ClayTokens.textSecondary)),
              ],
            ),
          )
          .toList(),
    );
  }
}

const kMonthLabelsShort = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
