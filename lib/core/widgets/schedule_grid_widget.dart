import 'package:flutter/material.dart';

import '../../features/overlay/domain/overlay_math.dart';
import '../../features/schedule/domain/weekly_bitmask.dart';

const _kDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _kHourLabels = [
  '8', '9', '10', '11', '12', '13', '14',
  '15', '16', '17', '18', '19',
];

/// A 7-day × 12-slot weekly schedule grid (08:00-20:00).
///
/// In edit mode ([readOnly] = false), tapping a cell fires [onTap].
/// In overlay mode ([overlay] is non-null), cell colours reflect
/// [OverlayResult] (everyone free, mixed availability, you busy, etc.).
class ScheduleGridWidget extends StatelessWidget {
  final WeeklyBitmask bitmask;
  final OverlayResult? overlay;
  final bool readOnly;
  final void Function(int dayIndex, int slotIndex)? onTap;

  const ScheduleGridWidget({
    super.key,
    required this.bitmask,
    this.overlay,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const timeLabelWidth = 30.0;
    const cellHeight = 36.0;
    const headerHeight = 28.0;
    const gap = 2.0;
    final cs = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day header row
        Row(
          children: [
            const SizedBox(width: timeLabelWidth + gap),
            for (int d = 0; d < 7; d++) ...[
              if (d > 0) const SizedBox(width: gap),
              Expanded(
                child: SizedBox(
                  height: headerHeight,
                  child: Center(
                    child: Text(
                      _kDayLabels[d],
                      style: labelStyle?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: gap),
        // Slot rows
        for (int slot = 0; slot < 12; slot++) ...[
          if (slot > 0) const SizedBox(height: gap),
          Row(
            children: [
              // Time label
              SizedBox(
                width: timeLabelWidth,
                height: cellHeight,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(_kHourLabels[slot], style: labelStyle),
                  ),
                ),
              ),
              const SizedBox(width: gap),
              // Day cells
              for (int day = 0; day < 7; day++) ...[
                if (day > 0) const SizedBox(width: gap),
                Expanded(
                  child: _GridCell(
                    dayIndex: day,
                    slotIndex: slot,
                    bitmask: bitmask,
                    overlay: overlay,
                    readOnly: readOnly,
                    onTap: onTap,
                    height: cellHeight,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  final int dayIndex;
  final int slotIndex;
  final WeeklyBitmask bitmask;
  final OverlayResult? overlay;
  final bool readOnly;
  final void Function(int day, int slot)? onTap;
  final double height;

  const _GridCell({
    required this.dayIndex,
    required this.slotIndex,
    required this.bitmask,
    required this.overlay,
    required this.readOnly,
    required this.onTap,
    required this.height,
  });

  /// Overlay cell category (drives both fill colour and name text colour).
  _OverlayCellVisual _overlayVisual(ColorScheme cs) {
    final ov = overlay!;
    final everyoneFree =
        ov.isCommonFree(dayIndex: dayIndex, slotIndex: slotIndex);
    if (everyoneFree) {
      return _OverlayCellVisual(
        background: const Color(0xFF43A047),
        nameColor: Colors.transparent,
        userBusyAccent: false,
      );
    }

    final userBusy = ov.isUserBusy(dayIndex: dayIndex, slotIndex: slotIndex);
    final freeNames = ov.freeNamesAt(dayIndex: dayIndex, slotIndex: slotIndex);
    final freeCount = freeNames.length;
    final totalFriends = ov.totalPersons - 1;

    if (userBusy && freeCount > 0) {
      return _OverlayCellVisual(
        background: cs.error,
        nameColor: Colors.white,
        userBusyAccent: true,
      );
    }
    if (!userBusy && totalFriends > 0 && freeCount < totalFriends) {
      // User free, mixed friends — tinted surface (not pale errorContainer)
      return _OverlayCellVisual(
        background: Color.alphaBlend(
          cs.error.withValues(alpha: 0.28),
          cs.surfaceContainerHigh,
        ),
        nameColor: cs.onSurface,
        userBusyAccent: false,
      );
    }
    if (!userBusy && totalFriends > 0 && freeCount == 0) {
      return _OverlayCellVisual(
        background: cs.error,
        nameColor: Colors.white,
        userBusyAccent: false,
      );
    }
    if (userBusy && freeCount == 0) {
      return _OverlayCellVisual(
        background: cs.error,
        nameColor: Colors.white,
        userBusyAccent: true,
      );
    }
    return _OverlayCellVisual(
      background: cs.surfaceContainerHighest,
      nameColor: cs.onSurfaceVariant,
      userBusyAccent: false,
    );
  }

  /// Returns the names of friends who are free in this slot, or null when
  /// there's nothing useful to display (everyone free or nobody free).
  String? _overlayFreeLabel(OverlayResult ov) {
    if (ov.isCommonFree(dayIndex: dayIndex, slotIndex: slotIndex)) return null;
    final names = ov.freeNamesAt(dayIndex: dayIndex, slotIndex: slotIndex);
    if (names.isEmpty) return null;
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ov = overlay;

    late final Color bg;
    late final Color nameColor;
    late final bool userBusyAccent;

    if (ov != null) {
      final visual = _overlayVisual(cs);
      bg = visual.background;
      nameColor = visual.nameColor;
      userBusyAccent = visual.userBusyAccent;
    } else {
      bg = bitmask.isBusy(dayIndex: dayIndex, slotIndex: slotIndex)
          ? cs.primary
          : cs.surfaceContainerHighest;
      nameColor = cs.onSurface;
      userBusyAccent = false;
    }

    final freeLabel = ov != null ? _overlayFreeLabel(ov) : null;

    // Rounded clip keeps overlays clean in all themes.
    final cell = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (userBusyAccent)
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Center(
              child: freeLabel != null
                  ? Text(
                      freeLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
                        color: nameColor,
                        shadows: nameColor.a < 0.05 ||
                                nameColor.computeLuminance() < 0.55
                            ? null
                            : const [
                                Shadow(
                                  offset: Offset(0, 0.5),
                                  blurRadius: 1.5,
                                  color: Color(0x66000000),
                                ),
                              ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );

    if (readOnly || onTap == null) return cell;

    return GestureDetector(
      onTap: () => onTap!(dayIndex, slotIndex),
      child: cell,
    );
  }
}

/// Visual bundle for one overlay cell (background + name legibility).
class _OverlayCellVisual {
  final Color background;
  final Color nameColor;
  final bool userBusyAccent;

  const _OverlayCellVisual({
    required this.background,
    required this.nameColor,
    required this.userBusyAccent,
  });
}

