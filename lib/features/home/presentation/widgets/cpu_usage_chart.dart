import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_section.dart';
import '../../../diagnostics/data/providers/full_device_info_provider.dart';
import '../../../diagnostics/data/services/device_info_service.dart';

/// Live CPU clock graph.
///
/// Android 8+ blocks /proc/stat for apps, so true utilisation is not
/// readable. This shows what *is* real: each core's current frequency as a
/// share of its maximum, sampled every 2 s while visible.
class CpuUsageChart extends ConsumerStatefulWidget {
  const CpuUsageChart({super.key});

  @override
  ConsumerState<CpuUsageChart> createState() => _CpuUsageChartState();
}

class _CpuUsageChartState extends ConsumerState<CpuUsageChart> {
  static const _historyLength = 24;
  final List<double> _history = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<AsyncValue<CpuClockSnapshot>>(liveCpuClockProvider, (_, next) {
      final load = next.valueOrNull?.averageLoad;
      if (load == null) return;
      setState(() {
        _history.add(load);
        if (_history.length > _historyLength) _history.removeAt(0);
      });
    });

    final snapshot = ref.watch(liveCpuClockProvider).valueOrNull;
    final load = snapshot?.averageLoad;
    final available = snapshot?.isAvailable ?? true;
    final color = load == null
        ? theme.colorScheme.onSurfaceVariant
        : load < 0.45
            ? theme.colorScheme.tertiary
            : load < 0.8
                ? theme.colorScheme.primary
                : theme.colorScheme.error;

    return GlassCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconTile(icon: Icons.memory_rounded, color: color, size: 32),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text('CPU clock',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            load == null ? (available ? '…' : 'Hidden') : '${(load * 100).round()}%',
            style:
                theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            !available
                ? 'Kernel hides cpufreq'
                : snapshot == null || snapshot.cores.isEmpty
                    ? 'Sampling…'
                    : '${snapshot.cores.length} cores · peak ${snapshot.peakMhz} MHz',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: List.of(_history),
                  color: color,
                  capacity: _historyLength,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color, required this.capacity});

  final List<double> values;
  final Color color;
  final int capacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final dx = size.width / (capacity - 1);
    final start = capacity - values.length;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (start + i) * dx;
      final y = size.height - values[i].clamp(0.0, 1.0) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo((start + values.length - 1) * dx, size.height)
      ..lineTo(start * dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.values.length != values.length ||
      !_same(oldDelegate.values, values);

  static bool _same(List<double> a, List<double> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
