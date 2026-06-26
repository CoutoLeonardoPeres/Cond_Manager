import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/widgets/rental_gantt_timeline.dart';
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
    this.dayWidth = 26,
    this.propertyColumnWidth = 200,
    this.rowHeight = 52,
  });

  final List<RentalProperty> properties;
  final List<RentalBooking> bookings;
  final List<RentalLease> leases;
  final RentalGanttRange range;
  final double dayWidth;
  final double propertyColumnWidth;
  final double rowHeight;

  @override
  State<RentalGanttChart> createState() => _RentalGanttChartState();
}

class _RentalGanttChartState extends State<RentalGanttChart> {
  static const _headerMonthHeight = 30.0;
  static const _headerDayHeight = 28.0;
  static final _borderColor = ClayTokens.textMuted.withValues(alpha: 0.35);

  final _headerHController = ScrollController();
  final _bodyHController = ScrollController();
  final _bodyVController = ScrollController();
  final _labelsVController = ScrollController();

  bool _syncingH = false;
  bool _syncingV = false;
  bool _didInitialScroll = false;

  double get _timelineWidth => widget.range.totalDays * widget.dayWidth;

  double get _headerHeight => _headerMonthHeight + _headerDayHeight;

  @override
  void initState() {
    super.initState();
    _headerHController.addListener(_syncHeaderToBody);
    _bodyHController.addListener(_syncBodyToHeader);
    _bodyVController.addListener(_syncBodyVToLabels);
    _labelsVController.addListener(_syncLabelsToBodyV);
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

  void _scrollToToday() {
    if (_didInitialScroll || !_bodyHController.hasClients) return;
    _didInitialScroll = true;
    final todayIndex = rentalGanttDayIndex(widget.range, DateTime.now());
    final viewport = _bodyHController.position.viewportDimension;
    final target = (todayIndex * widget.dayWidth) - (viewport / 2) + (widget.dayWidth / 2);
    final offset = target.clamp(0.0, _bodyHController.position.maxScrollExtent);
    _bodyHController.jumpTo(offset);
    _headerHController.jumpTo(offset);
  }

  @override
  Widget build(BuildContext context) {
    final properties = rentalGanttSortedProperties(widget.properties);
    final monthHeaders = rentalGanttMonthHeaders(widget.range);
    final todayIndex = rentalGanttDayIndex(widget.range, DateTime.now());
    final showToday = todayIndex >= 0 && todayIndex < widget.range.totalDays;
    final bodyHeight = properties.length * widget.rowHeight;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: [
              _CornerCell(
                width: widget.propertyColumnWidth,
                height: _headerHeight,
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    controller: _headerHController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    dragStartBehavior: DragStartBehavior.down,
                    child: _TimelineHeaderContent(
                      range: widget.range,
                      monthHeaders: monthHeaders,
                      dayWidth: widget.dayWidth,
                      monthHeight: _headerMonthHeight,
                      dayHeight: _headerDayHeight,
                      width: _timelineWidth,
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
                  thumbVisibility: true,
                  notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
                  child: Scrollbar(
                    controller: _bodyVController,
                    thumbVisibility: true,
                    notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          controller: _bodyHController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          dragStartBehavior: DragStartBehavior.down,
                          child: SizedBox(
                            width: _timelineWidth,
                            height: constraints.maxHeight,
                            child: SingleChildScrollView(
                              controller: _bodyVController,
                              physics: const ClampingScrollPhysics(),
                              child: SizedBox(
                                height: bodyHeight,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _DayGrid(
                                      range: widget.range,
                                      dayWidth: widget.dayWidth,
                                      rowHeight: widget.rowHeight,
                                      rowCount: properties.length,
                                      borderColor: _borderColor,
                                    ),
                                    if (showToday)
                                      Positioned(
                                        left: todayIndex * widget.dayWidth,
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
                                        width: _timelineWidth,
                                        height: widget.rowHeight,
                                        child: _PropertyTimelineRow(
                                          range: widget.range,
                                          segments: segments,
                                          dayWidth: widget.dayWidth,
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
  }
}

class _CornerCell extends StatelessWidget {
  const _CornerCell({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final border = ClayTokens.textMuted.withValues(alpha: 0.35);
    return Container(
      width: width,
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ClayTokens.surfaceRaised,
        border: Border(
          bottom: BorderSide(color: border),
          right: BorderSide(color: border),
        ),
      ),
      child: const Text(
        'Imóvel',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: ClayTokens.textSecondary,
        ),
      ),
    );
  }
}

class _TimelineHeaderContent extends StatelessWidget {
  const _TimelineHeaderContent({
    required this.range,
    required this.monthHeaders,
    required this.dayWidth,
    required this.monthHeight,
    required this.dayHeight,
    required this.width,
  });

  final RentalGanttRange range;
  final List<RentalGanttMonthHeader> monthHeaders;
  final double dayWidth;
  final double monthHeight;
  final double dayHeight;
  final double width;

  @override
  Widget build(BuildContext context) {
    final monthFmt = DateFormat('MMM yyyy', 'pt_BR');
    final dayFmt = DateFormat('d');
    final border = ClayTokens.textMuted.withValues(alpha: 0.35);

    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            height: monthHeight,
            child: Stack(
              children: [
                for (final header in monthHeaders)
                  Positioned(
                    left: header.startDayIndex * dayWidth,
                    width: header.dayCount * dayWidth,
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
                        _capitalize(monthFmt.format(DateTime(header.year, header.month))),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: dayHeight,
            child: Row(
              children: List.generate(range.totalDays, (i) {
                final day = range.start.add(Duration(days: i));
                final isWeekend =
                    day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                final isToday = rentalGanttDateOnly(day) == rentalGanttDateOnly(DateTime.now());
                return Container(
                  width: dayWidth,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? ClayTokens.primary.withValues(alpha: 0.12)
                        : isWeekend
                            ? ClayTokens.surfacePressed.withValues(alpha: 0.5)
                            : ClayTokens.surfaceRaised,
                    border: Border(
                      right: BorderSide(color: border),
                      bottom: BorderSide(color: border),
                    ),
                  ),
                  child: Text(
                    dayFmt.format(day),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isToday ? ClayTokens.primary : ClayTokens.textSecondary,
                    ),
                  ),
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

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.range,
    required this.dayWidth,
    required this.rowHeight,
    required this.rowCount,
    required this.borderColor,
  });

  final RentalGanttRange range;
  final double dayWidth;
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
            children: List.generate(range.totalDays, (i) {
              final day = range.start.add(Duration(days: i));
              final isWeekend =
                  day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
              return Container(
                width: dayWidth,
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
                    ? ColoredBox(color: ClayTokens.surfacePressed.withValues(alpha: 0.15))
                    : null,
              );
            }),
          ),
        );
      }),
    );
  }
}

class _PropertyTimelineRow extends StatelessWidget {
  const _PropertyTimelineRow({
    required this.range,
    required this.segments,
    required this.dayWidth,
    required this.rowHeight,
    required this.stripe,
  });

  final RentalGanttRange range;
  final List<RentalGanttSegment> segments;
  final double dayWidth;
  final double rowHeight;
  final bool stripe;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Stack(
      children: [
        if (stripe)
          Positioned.fill(
            child: ColoredBox(
              color: ClayTokens.surfacePressed.withValues(alpha: 0.08),
            ),
          ),
        for (final segment in segments)
          Positioned(
            left: rentalGanttDayIndex(range, segment.start) * dayWidth + 1,
            width: (segment.end.difference(segment.start).inDays * dayWidth - 2)
                .clamp(4.0, double.infinity),
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
}
