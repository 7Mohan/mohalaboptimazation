import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../domain/tweak.dart';
import '../../domain/tweak_catalog.dart';
import '../../../games/presentation/providers/game_library_provider.dart';
import '../../domain/device_advisor.dart';
import '../providers/device_advice_provider.dart';
import '../providers/long_task_provider.dart';

/// Bottom sheet for the long ART tasks (Compile All Apps / System Dexopt).
///
/// Shows options first, then live progress with a smoothly animated ring,
/// the app currently compiling, counts and an ETA. The task keeps running if
/// the sheet is hidden; reopening it picks the progress back up.
class LongTaskSheet extends ConsumerStatefulWidget {
  const LongTaskSheet({super.key, required this.action});

  final TweakAction action;

  static Future<void> show(BuildContext context, TweakAction action) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => LongTaskSheet(action: action),
    );
  }

  @override
  ConsumerState<LongTaskSheet> createState() => _LongTaskSheetState();
}

/// Which apps "Compile All Apps" covers.
enum CompileScope {
  games('Games'),
  installed('Installed'),
  all('All');

  const CompileScope(this.label);
  final String label;
}

class _LongTaskSheetState extends ConsumerState<LongTaskSheet> {
  bool _maxSpeed = true;
  CompileScope _scope = CompileScope.games;
  bool _adviceApplied = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-render once a second so elapsed time / ETA stay live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && (ref.read(longTaskProvider)?.running ?? false)) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _isCompile => widget.action.id == TweakCatalog.compileApps.id;

  List<String> get _gamePackages =>
      (ref.read(gameLibraryControllerProvider).valueOrNull ?? const [])
          .map((g) => g.packageName)
          .toList();

  void _useAdvice(CompileAdvice advice) {
    _maxSpeed = advice.maxSpeed;
    _scope = advice.gamesOnly ? CompileScope.games : CompileScope.installed;
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    final c = ref.read(longTaskProvider.notifier);
    if (!_isCompile) {
      c.dismiss();
      await c.systemDexopt();
      HapticFeedback.heavyImpact();
      return;
    }
    final games = _gamePackages;
    if (_scope == CompileScope.games && games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No games detected yet — open the Games tab to scan.')),
      );
      return;
    }
    c.dismiss();
    await c.compileApps(
      maxSpeed: _maxSpeed,
      includeSystem: _scope == CompileScope.all,
      packages: _scope == CompileScope.games ? games : null,
    );
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(longTaskProvider);
    final mine = task != null && task.task == widget.action.id;
    final otherRunning = task != null && task.running && !mine;
    final advice = _isCompile ? ref.watch(deviceAdviceProvider).valueOrNull?.compile : null;
    final gameCount =
        _isCompile ? (ref.watch(gameLibraryControllerProvider).valueOrNull?.length ?? 0) : 0;
    if (advice != null && !_adviceApplied) {
      _adviceApplied = true;
      _useAdvice(advice);
    }

    return GlassSheetSurface(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: otherRunning
                      ? _Busy(key: const ValueKey('busy'), onClose: () => Navigator.pop(context))
                      : mine
                          ? _Progress(
                              key: const ValueKey('progress'),
                              action: widget.action,
                              task: task,
                              onStop: () => ref.read(longTaskProvider.notifier).cancel(),
                              onHide: () => Navigator.pop(context),
                              onDone: () {
                                ref.read(longTaskProvider.notifier).dismiss();
                                Navigator.pop(context);
                              },
                            )
                          : _Options(
                              key: const ValueKey('options'),
                              action: widget.action,
                              isCompile: _isCompile,
                              maxSpeed: _maxSpeed,
                              scope: _scope,
                              gameCount: gameCount,
                              advice: advice,
                              onMaxSpeed: (v) => setState(() => _maxSpeed = v),
                              onScope: (v) => setState(() => _scope = v),
                              onUseAdvice: () => setState(() => _useAdvice(advice!)),
                              onStart: _start,
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

class _Options extends StatelessWidget {
  const _Options({
    super.key,
    required this.action,
    required this.isCompile,
    required this.maxSpeed,
    required this.scope,
    required this.gameCount,
    required this.advice,
    required this.onMaxSpeed,
    required this.onScope,
    required this.onUseAdvice,
    required this.onStart,
  });

  final TweakAction action;
  final bool isCompile;
  final bool maxSpeed;
  final CompileScope scope;
  final int gameCount;
  final CompileAdvice? advice;
  final ValueChanged<bool> onMaxSpeed;
  final ValueChanged<CompileScope> onScope;
  final VoidCallback onUseAdvice;
  final VoidCallback onStart;

  bool get _matchesAdvice =>
      advice != null &&
      advice!.maxSpeed == maxSpeed &&
      (advice!.gamesOnly ? scope == CompileScope.games : scope == CompileScope.installed);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final a = advice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _GradientIcon(icon: action.icon),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(action.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isCompile
              ? 'Compiles apps ahead of time with Android\'s ART compiler, one at a time, so you see real progress. '
                  'Apps launch faster and stutter less, especially after updates.'
              : 'Starts Android\'s built-in background dexopt job right now instead of waiting until the phone is idle '
                  'and charging. Android decides which apps need work, so there is no per-app progress.',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.45),
        ),
        if (isCompile) ...[
          if (a != null) ...[
            const SizedBox(height: AppSpacing.md),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: scheme.tertiary.withOpacity(_matchesAdvice ? 0.14 : 0.07),
                border: Border.all(color: scheme.tertiary.withOpacity(_matchesAdvice ? 0.5 : 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sports_esports_rounded, color: scheme.tertiary, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommended for gaming: ${a.gamesOnly ? 'Games' : 'Installed apps'} · ${a.modeLabel}',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800, color: scheme.tertiary),
                        ),
                        const SizedBox(height: 2),
                        Text(a.reason,
                            style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35)),
                        if (!_matchesAdvice)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                                onPressed: onUseAdvice, child: const Text('Use recommended')),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('Apps to compile',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<CompileScope>(
            segments: [
              ButtonSegment(
                value: CompileScope.games,
                label: Text(gameCount > 0 ? 'Games ($gameCount)' : 'Games'),
                icon: const Icon(Icons.sports_esports_rounded, size: 18),
              ),
              const ButtonSegment(value: CompileScope.installed, label: Text('Installed')),
              const ButtonSegment(value: CompileScope.all, label: Text('All')),
            ],
            selected: {scope},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onScope(s.first),
          ),
          const SizedBox(height: 6),
          Text(
            switch (scope) {
              CompileScope.games => 'Only detected games — the quickest win for smoother gaming.',
              CompileScope.installed => 'Every app you installed. Good after big updates.',
              CompileScope.all => 'Includes system apps. Takes much longer.',
            },
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Compiler mode',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                  value: false,
                  label: Text('Smart'),
                  icon: Icon(Icons.auto_awesome_rounded, size: 18)),
              ButtonSegment(
                  value: true, label: Text('Maximum'), icon: Icon(Icons.speed_rounded, size: 18)),
            ],
            selected: {maxSpeed},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onMaxSpeed(s.first),
          ),
          const SizedBox(height: 6),
          Text(
            maxSpeed
                ? 'speed: compiles every method. Fastest code, no JIT warm-up, more storage.'
                : 'speed-profile: compiles the code each app actually uses. Smaller, great for everyday apps.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Keep the phone charging. You can hide this sheet and keep using the app.',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _GradientButton(label: 'Start', icon: Icons.play_arrow_rounded, onPressed: onStart),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    super.key,
    required this.action,
    required this.task,
    required this.onStop,
    required this.onHide,
    required this.onDone,
  });

  final TweakAction action;
  final LongTaskState task;
  final VoidCallback onStop;
  final VoidCallback onHide;
  final VoidCallback onDone;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '${m}m ${s.toString().padLeft(2, '0')}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final result = task.result;
    final finished = !task.running;
    final success = finished && (result?.success ?? false);

    final String headline;
    if (!finished) {
      headline = task.stopping ? 'Stopping…' : '${action.title}…';
    } else {
      headline = success ? 'Done' : 'Stopped';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          headline,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: SizedBox(
            width: 176,
            height: 176,
            child: _ProgressRing(
              progress: finished ? 1.0 : task.progress,
              finished: finished,
              success: success,
              center: finished
                  ? null
                  : task.progress == null
                      ? _fmt(task.elapsed)
                      : '${(task.progress! * 100).round()}%',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(finished ? 'result' : task.packageName ?? 'wait'),
            children: [
              Text(
                finished
                    ? (result?.message ?? '')
                    : task.label ??
                        (task.total == 0 ? 'Android is optimizing apps…' : 'Preparing…'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (!finished && task.packageName != null && task.packageName != task.label)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    task.packageName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (task.total > 0)
          Row(
            children: [
              _Stat(label: 'Compiled', value: '${task.ok}', color: AppColors.success),
              _Stat(label: 'Skipped', value: '${task.failed}', color: AppColors.warning),
              _Stat(
                  label: 'Left',
                  value: '${math.max(0, task.total - task.done)}',
                  color: theme.colorScheme.primary),
            ],
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          finished
              ? 'Took ${_fmt(task.elapsed)}'
              : 'Elapsed ${_fmt(task.elapsed)}${task.remaining != null ? ' · about ${_fmt(task.remaining!)} left' : ''}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (finished)
          _GradientButton(label: 'Done', icon: Icons.check_rounded, onPressed: onDone)
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: task.stopping ? null : onStop,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onHide,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Hide'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.hourglass_top_rounded, size: 40, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.sm),
        Text('Another ART task is running',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'Wait for it to finish, or open it and tap Stop.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(onPressed: onClose, child: const Text('OK')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: double.tryParse(value) ?? 0),
            duration: const Duration(milliseconds: 400),
            builder: (context, v, _) => Text(
              v.round().toString(),
              style:
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: color),
            ),
          ),
          Text(label,
              style:
                  theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Gradient progress ring. Determinate values ease smoothly between updates;
/// null spins an indeterminate comet arc.
class _ProgressRing extends StatefulWidget {
  const _ProgressRing({
    required this.progress,
    required this.finished,
    required this.success,
    this.center,
  });

  final double? progress;
  final bool finished;
  final bool success;
  final String? center;

  @override
  State<_ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<_ProgressRing> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final spinning = !widget.finished;
    if (spinning && !_spin.isAnimating) _spin.repeat();
    if (!spinning && _spin.isAnimating) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = widget.finished && !widget.success
        ? [AppColors.warning, AppColors.warning]
        : widget.finished
            ? [scheme.tertiary, AppColors.success]
            : [scheme.primary, scheme.secondary, scheme.tertiary];

    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.progress ?? 0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => AnimatedBuilder(
        animation: _spin,
        builder: (context, _) => CustomPaint(
          painter: _RingPainter(
            value: widget.progress == null ? null : value,
            spin: _spin.value,
            colors: colors,
            track: scheme.surfaceContainerHighest,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) =>
                  ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
              child: widget.finished
                  ? Icon(
                      widget.success ? Icons.check_rounded : Icons.pause_rounded,
                      key: ValueKey(widget.success),
                      size: 64,
                      color: colors.last,
                    )
                  : Text(
                      widget.center ?? '',
                      key: const ValueKey('text'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(
      {required this.value, required this.spin, required this.colors, required this.track});

  final double? value;
  final double spin;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
        arcRect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track);

    final double start;
    final double sweep;
    if (value == null) {
      start = spin * math.pi * 2 - math.pi / 2;
      sweep = math.pi * (0.55 + 0.35 * math.sin(spin * math.pi * 2));
    } else {
      start = -math.pi / 2;
      sweep = math.max(0.001, value!) * math.pi * 2;
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [...colors, colors.first],
        transform: GradientRotation(start),
      ).createShader(rect);
    canvas.drawArc(arcRect, start, sweep, false, paint);

    // Soft glow at the leading edge while working.
    if (value == null || value! < 1) {
      final end = start + sweep;
      final c = size.center(Offset.zero);
      final r = arcRect.width / 2;
      canvas.drawCircle(
        Offset(c.dx + r * math.cos(end), c.dy + r * math.sin(end)),
        stroke * 0.9,
        Paint()
          ..color = colors.last.withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.spin != spin || oldDelegate.colors != colors;
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
        boxShadow: [
          BoxShadow(
              color: scheme.primary.withOpacity(0.35),
              blurRadius: 18,
              spreadRadius: -6,
              offset: const Offset(0, 8)),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
