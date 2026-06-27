import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_occupancy_view.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RentalGanttChart extends StatefulWidget {
  const RentalGanttChart({
    super.key,
    required this.properties,
    required this.bookings,
    required this.leases,
    required this.range,
    required this.viewMode,
    this.propertyColumnWidth = 200,
    this.rowHeight = 52,
  });

  final List<RentalProperty> properties;
  final List<RentalBooking> bookings;
  final List<RentalLease> leases;
  final RentalGanttRange range;
  final RentalOccupancyViewMode viewMode;
  final double propertyColumnWidth;
  final double rowHeight;

  @override
  State<RentalGanttChart> createState() => _RentalGanttChartState();
}

class _RentalGanttChartState extends State<RentalGanttChart> {
  static final _borderColor = ClayTokens.textMuted.withValues(alpha: 0.35);

  final _headerHController = ScrollController();
  final _bodyHController = ScrollController();
  final _bodyVController = ScrollController();
  final _labelsVController = ScrollController();

  bool _syncingH = false;
  bool _syncingV = false;
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _headerHController.addListener(_syncHeaderToBody);
    _bodyHController.addListener(_syncBodyToHeader);
    _bodyVController.addListener(_syncBodyVToLabels);
    _labelsVController.addListener(_syncLabelsToBodyV);
  }

  @override
  void didUpdateWidget(covariant RentalGanttChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode ||
        oldWidget.range.start != widget.range.start) {
      _didInitialScroll = false;
    }
  }

  @override
  void dispose() {
    _headerHController.dispose();
    _bodyHController.dispose();
    _bodyVController.dispose();
    _labelsVController.dispose();
    super.dispose();
  }

  void _syncHeaderToBody() {
    if (_syncingH) return;
    _syncingH = true;
    if (_bodyHController.hasClients && _bodyHController.offset != _headerHController.offset) {
      _bodyHController.jumpTo(_headerHController.offset);
    }
    _syncingH = false;
  }

  void _syncBodyToHeader() {
    if (_syncingH) return;
    _syncingH = true;
    if (_headerHController.hasClients && _headerHController.offset != _bodyHController.offset) {
      _headerHController.jumpTo(_bodyHController.offset);
    }
    _syncingH = false;
  }

  void _syncBodyVToLabels() {
    if (_syncingV) return;
    _syncingV = true;
    if (_labelsVController.hasClients && _labelsVController.offset != _bodyVController.offset) {
      _labelsVController.jumpTo(_bodyVController.offset);
    }
    _syncingV = false;
  }

  void _syncLabelsToBodyV() {
    if (_syncingV) return;
    _syncingV = true;
    if (_bodyVController.hasClients && _bodyVController.offset != _labelsVController.offset) {
      _bodyVController.jumpTo(_labelsVController.offset);
    }
    _syncingV = false;
  }

  void _scrollToToday(double colWidth, int colCount) {
    if (_didInitialScroll || !_bodyHController.hasClients) return;
    _didInitialScroll = true;

    final today = rentalGanttDateOnly(DateTime.now());
    double targetIndex;
    if (widget.viewMode == RentalOccupancyViewMode.year) {
      if (today.year != widget.range.start.year) return;
      targetIndex = (today.month - 1).toDouble();
    } else {
      final idx = rentalGanttDayIndex(widget.range, today);
      if (idx < 0 || idx >= colCount) return;
      targetIndex = idx.toDouble();
    }

    final viewport = _bodyHController.position.viewportDimension;
    final target = (targetIndex * colWidth) - (viewport / 2) + (colWidth / 2);
    final offset = target.clamp(0.0, _bodyHController.position.maxScrollExtent);
    _bodyHController.jumpTo(offset);
    _headerHController.jumpTo(offset);
  }

  double? _todayMarkerLeft(RentalOccupancyViewMode mode, double colWidth, int colCount) {
    final today = rentalGanttDateOnly(DateTime.now());
    if (mode == RentalOccupancyViewMode.year) {
      if (today.year != widget.range.start.year) return null;
      return (today.month - 1) * colWidth;
    }
    final idx = rentalGanttDayIndex(widget.range, today);
    if (idx < 0 || idx >= colCount) return null;
    return idx * colWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = rentalOccupancyColumnWidth(
          mode: widget.viewMode,
          viewportWidth: constraints.maxWidth,
          propertyColumnWidth: widget.propertyColumnWidth,
        );
        final colCount = rentalOccupancyColumnCount(widget.viewMode, widget.range);
        final timelineWidth = colCount * colWidth;
        final headerHeight = switch (widget.viewMode) {
          RentalOccupancyViewMode.day => 48.0,
          RentalOccupancyViewMode.week => 54.0,
          RentalOccupancyViewMode.month => 58.0,
          RentalOccupancyViewMode.year => 36.0,
        };

        final properties = rentalGanttSortedProperties(widget.properties);
        final bodyHeight = properties.length * widget.rowHeight;
        final todayLeft = _todayMarkerLeft(widget.viewMode, colWidth, colCount);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToToday(colWidth, colCount);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: headerHeight,
              child: Row(
                children: [
                  _CornerCell(
                    width: widget.propertyColumnWidth,
                    height: headerHeight,
                  ),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        controller: _headerHController,
                        scrollDirection: Axis.horizontal,
                        physics: widget.viewMode == RentalOccupancyViewMode.day
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                        child: _OccupancyHeader(
                          range: widget.range,
                          viewMode: widget.viewMode,
                          colWidth: colWidth,
                          colCount: colCount,
                          width: timelineWidth,
                          height: headerHeight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: widget.propertyColumnWidth,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: ListView.builder(
                        controller: _labelsVController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: properties.length,
                        itemExtent: widget.rowHeight,
                        itemBuilder: (_, i) => _PropertyLabel(
                          property: properties[i],
                          height: widget.rowHeight,
                          borderColor: _borderColor,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: _bodyHController,
                      thumbVisibility: widget.viewMode != RentalOccupancyViewMode.day,
                      notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
                      child: Scrollbar(
                        controller: _bodyVController,
                        thumbVisibility: true,
                        notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                        child: LayoutBuilder(
                          builder: (context, bodyConstraints) {
                            return SingleChildScrollView(
                              controller: _bodyHController,
                              scrollDirection: Axis.horizontal,
                              physics: widget.viewMode == RentalOccupancyViewMode.day
                                  ? const NeverScrollableScrollPhysics()
                                  : const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                              dragStartBehavior: DragStartBehavior.down,
                              child: SizedBox(
                                width: timelineWidth,
                                height: bodyConstraints.maxHeight,
                                child: SingleChildScrollView(
                                  controller: _bodyVController,
                                  physics: const ClampingScrollPhysics(),
                                  child: SizedBox(
                                    height: bodyHeight,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _OccupancyGrid(
                                          range: widget.range,
                                          viewMode: widget.viewMode,
                                          colWidth: colWidth,
                                          colCount: colCount,
                                          rowHeight: widget.rowHeight,
                                          rowCount: properties.length,
                                          borderColor: _borderColor,
                                        ),
                                        if (todayLeft != null)
                                          Positioned(
                                            left: todayLeft,
                                            top: 0,
                                            bottom: 0,
                                            child: IgnorePointer(
                                              child: Container(
                                                width: 2,
                                                color: ClayTokens.primary.withValues(alpha: 0.55),
                                              ),
                                            ),
                                          ),
                                        ...List.generate(properties.length, (row) {
                                          final property = properties[row];
                                          final segments = rentalGanttSegmentsForProperty(
                                            propertyId: property.id,
                                            bookings: widget.bookings,
                                            leases: widget.leases,
                                            range: widget.range,
                                          );
                                          return Positioned(
                                            top: row * widget.rowHeight,
                                            left: 0,
                                            width: timelineWidth,
                                            height: widget.rowHeight,
                                            child: _PropertyTimelineRow(
                                              range: widget.range,
                                              viewMode: widget.viewMode,
                                              segments: segments,
                                              colWidth: colWidth,
                                              colCount: colCount,
                                              rowHeight: widget.rowHeight,
                                              stripe: row.isOdd,
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CornerCell extends StatelessWidget {
  const _CornerCell({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ClayTokens.surfaceRaised,
        border: Border(
          bottom: BorderSide(color: ClayTokens.textMuted.withValues(alpha: 0.35)),
          right: BorderSide(color: ClayTokens.textMuted.withValues(alpha: 0.35)),
        ),
      ),
      child: const Text(
        'Imóvel',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ClayTokens.textSecondary),
      ),
    );
  }
}

class _OccupancyHeader extends StatelessWidget {
  const _OccupancyHeader({
    required this.range,
    required this.viewMode,
    required this.colWidth,
    required this.colCount,
    required this.width,
    required this.height,
  });

  final RentalGanttRange range;
  final RentalOccupancyViewMode viewMode;
  final double colWidth;
  final int colCount;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final border = ClayTokens.textMuted.withValues(alpha: 0.35);
    final today = rentalGanttDateOnly(DateTime.now());

    Widget cell({
      required String label,
      required String? sublabel,
      required bool highlight,
      required bool weekend,
    }) {
      return Container(
        width: colWidth,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: highlight
              ? ClayTokens.primary.withValues(alpha: 0.12)
              : weekend
                  ? ClayTokens.surfacePressed.withValues(alpha: 0.45)
                  : ClayTokens.surfaceRaised,
          border: Border(
            right: BorderSide(color: border),
            bottom: BorderSide(color: border),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (sublabel != null)
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: highlight ? ClayTokens.primary : ClayTokens.textMuted,
                ),
              ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: viewMode == RentalOccupancyViewMode.day ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: viewMode == RentalOccupancyViewMode.day ? 12 : 10,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? ClayTokens.primary : ClayTokens.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (viewMode == RentalOccupancyViewMode.year) {
      final monthFmt = DateFormat('MMM', 'pt_BR');
      return SizedBox(
        width: width,
        height: height,
        child: Row(
          children: List.generate(12, (i) {
            final monthDate = DateTime(range.start.year, i + 1);
            final isCurrentMonth =
                today.year == monthDate.year && today.month == monthDate.month;
            final label = monthFmt.format(monthDate);
            return cell(
              label: label[0].toUpperCase() + label.substring(1),
              sublabel: null,
              highlight: isCurrentMonth,
              weekend: false,
            );
          }),
        ),
      );
    }

    if (viewMode == RentalOccupancyViewMode.day) {
      final dayLabel = DateFormat('EEEE', 'pt_BR').format(range.start);
      final dateLabel = DateFormat('d MMMM yyyy', 'pt_BR').format(range.start);
      final isToday = range.start == today;
      return SizedBox(
        width: width,
        height: height,
        child: cell(
          label: '${dayLabel[0].toUpperCase()}${dayLabel.substring(1)}\n$dateLabel',
          sublabel: null,
          highlight: isToday,
          weekend: range.start.weekday == DateTime.saturday ||
              range.start.weekday == DateTime.sunday,
        ),
      );
    }

    if (viewMode == RentalOccupancyViewMode.week) {
      final weekdayFmt = DateFormat('EEE', 'pt_BR');
      final dayFmt = DateFormat('d');
      return SizedBox(
        width: width,
        height: height,
        child: Row(
          children: List.generate(colCount, (i) {
            final day = range.start.add(Duration(days: i));
            final isToday = rentalGanttDateOnly(day) == today;
            final wd = weekdayFmt.format(day);
            return cell(
              label: dayFmt.format(day),
              sublabel: wd[0].toUpperCase() + wd.substring(1),
              highlight: isToday,
              weekend: day.weekday == DateTime.saturday || day.weekday == DateTime.sunday,
            );
          }),
        ),
      );
    }

    // month
    final monthHeaders = rentalGanttMonthHeaders(range);
    final dayFmt = DateFormat('d');
    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Stack(
              children: [
                for (final header in monthHeaders)
                  Positioned(
                    left: header.startDayIndex * colWidth,
                    width: header.dayCount * colWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ClayTokens.surfaceRaised,
                        border: Border(
                          right: BorderSide(color: border),
                          bottom: BorderSide(color: border),
                        ),
                      ),
                      child: Text(
                        _capitalize(
                          DateFormat('MMM yyyy', 'pt_BR')
                              .format(DateTime(header.year, header.month)),
                        ),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 28,
            child: Row(
              children: List.generate(colCount, (i) {
                final day = range.start.add(Duration(days: i));
                final isToday = rentalGanttDateOnly(day) == today;
                return cell(
                  label: dayFmt.format(day),
                  sublabel: null,
                  highlight: isToday,
                  weekend:
                      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _OccupancyGrid extends StatelessWidget {
  const _OccupancyGrid({
    required this.range,
    required this.viewMode,
    required this.colWidth,
    required this.colCount,
    required this.rowHeight,
    required this.rowCount,
    required this.borderColor,
  });

  final RentalGanttRange range;
  final RentalOccupancyViewMode viewMode;
  final double colWidth;
  final int colCount;
  final double rowHeight;
  final int rowCount;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rowCount, (row) {
        return SizedBox(
          height: rowHeight,
          child: Row(
            children: List.generate(colCount, (i) {
              var isWeekend = false;
              if (viewMode != RentalOccupancyViewMode.year) {
                final day = range.start.add(Duration(days: i));
                isWeekend =
                    day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
              }
              return Container(
                width: colWidth,
                decoration: BoxDecoration(
                  color: row.isOdd
                      ? ClayTokens.surfacePressed.withValues(alpha: 0.25)
                      : Colors.transparent,
                  border: Border(
                    right: BorderSide(color: borderColor.withValues(alpha: 0.6)),
                    bottom: BorderSide(color: borderColor.withValues(alpha: 0.6)),
                  ),
                ),
                child: isWeekend
                    ? ColoredBox(color: ClayTokens.surfacePressed.withValues(alpha: 0.12))
                    : null,
              );
            }),
          ),
        );
      }),
    );
  }
}

class _PropertyLabel extends StatelessWidget {
  const _PropertyLabel({
    required this.property,
    required this.height,
    required this.borderColor,
  });

  final RentalProperty property;
  final double height;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: ClayTokens.surfaceRaised,
        border: Border(
          bottom: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          if (property.locationLabel.isNotEmpty)
            Text(
              property.locationLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: ClayTokens.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _PropertyTimelineRow extends StatelessWidget {
  const _PropertyTimelineRow({
    required this.range,
    required this.viewMode,
    required this.segments,
    required this.colWidth,
    required this.colCount,
    required this.rowHeight,
    required this.stripe,
  });

  final RentalGanttRange range;
  final RentalOccupancyViewMode viewMode;
  final List<RentalGanttSegment> segments;
  final double colWidth;
  final int colCount;
  final double rowHeight;
  final bool stripe;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Stack(
      children: [
        if (stripe)
          Positioned.fill(
            child: ColoredBox(color: ClayTokens.surfacePressed.withValues(alpha: 0.08)),
          ),
        for (final segment in segments)
          Positioned(
            left: _segmentLeft(segment) + 1,
            width: _segmentWidth(segment).clamp(4.0, double.infinity),
            top: 8,
            height: rowHeight - 16,
            child: Tooltip(
              message:
                  '${segment.label}\n${dateFmt.format(segment.start)} → ${dateFmt.format(segment.end.subtract(const Duration(days: 1)))}',
              child: Container(
                decoration: BoxDecoration(
                  gradient: segment.kind == RentalGanttSegmentKind.lease
                      ? const LinearGradient(
                          colors: [Color(0xFF34D399), ClayTokens.success],
                        )
                      : const LinearGradient(
                          colors: [ClayTokens.tertiary, ClayTokens.accent],
                        ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: (segment.kind == RentalGanttSegmentKind.lease
                              ? ClayTokens.success
                              : ClayTokens.tertiary)
                          .withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.centerLeft,
                child: Text(
                  segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _segmentLeft(RentalGanttSegment segment) {
    if (viewMode == RentalOccupancyViewMode.year) {
      final cols = rentalOccupancyYearSegmentColumns(
        range: range,
        segmentStart: segment.start,
        segmentEndExclusive: segment.end,
      );
      return cols.$1 * colWidth;
    }
    return rentalGanttDayIndex(range, segment.start) * colWidth;
  }

  double _segmentWidth(RentalGanttSegment segment) {
    if (viewMode == RentalOccupancyViewMode.year) {
      final cols = rentalOccupancyYearSegmentColumns(
        range: range,
        segmentStart: segment.start,
        segmentEndExclusive: segment.end,
      );
      return (cols.$2 - cols.$1) * colWidth - 2;
    }
    return segment.end.difference(segment.start).inDays * colWidth - 2;
  }
}
