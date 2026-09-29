import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../settings/presentation/providers/theme_provider.dart';

/// Anchors for tour targets. Screens wrap the relevant widget in a
/// `KeyedSubtree(key: TourKeys.x, ...)`; missing anchors (e.g. tablet layout)
/// fall back to a centred card, so the tour never gets stuck.
abstract final class TourKeys {
  static final homeHero = GlobalKey(debugLabel: 'tour.homeHero');
  static final homeBoost = GlobalKey(debugLabel: 'tour.homeBoost');
  static final homeTelemetry = GlobalKey(debugLabel: 'tour.homeTelemetry');
  static final homeVitals = GlobalKey(debugLabel: 'tour.homeVitals');
  static final homeStorage = GlobalKey(debugLabel: 'tour.homeStorage');
  static final homeQuickActions = GlobalKey(debugLabel: 'tour.homeQuickActions');
  static final gamesList = GlobalKey(debugLabel: 'tour.gamesList');
  static final tweaksStatus = GlobalKey(debugLabel: 'tour.tweaksStatus');
  static final tweaksAdvice = GlobalKey(debugLabel: 'tour.tweaksAdvice');
  static final tweaksPresets = GlobalKey(debugLabel: 'tour.tweaksPresets');
  static final tweaksActions = GlobalKey(debugLabel: 'tour.tweaksActions');
  static final tweaksList = GlobalKey(debugLabel: 'tour.tweaksList');

  /// Bottom tab buttons, in AppShell order.
  static final tabs = List.generate(5, (i) => GlobalKey(debugLabel: 'tour.tab$i'));
}

class TourStep {
  const TourStep({
    required this.title,
    required this.body,
    required this.icon,
    this.target,
    this.route,
  });

  final String title;
  final String body;
  final IconData icon;

  /// Widget to spotlight; null shows a centred card with no hand.
  final GlobalKey? target;

  /// Tab to open first; null keeps the current screen.
  final String? route;
}

final List<TourStep> featureTourSteps = [
  const TourStep(
    route: RouteNames.home,
    icon: Icons.waving_hand_rounded,
    title: 'Welcome to Moha Lab',
    body:
        'A quick hands-on tour of every feature. Follow the hand, or tap Next. You can skip anytime.',
  ),
  TourStep(
    route: RouteNames.home,
    target: TourKeys.homeHero,
    icon: Icons.phone_android_rounded,
    title: 'Your device at a glance',
    body:
        'See how many tweaks are really active and which access mode you have: Shizuku, ADB grant or standard.',
  ),
  TourStep(
    route: RouteNames.home,
    target: TourKeys.homeBoost,
    icon: Icons.rocket_launch_rounded,
    title: 'One-tap Boost',
    body: 'Stops cached background apps before you play, then shows the RAM it actually freed.',
  ),
  TourStep(
    route: RouteNames.home,
    target: TourKeys.homeTelemetry,
    icon: Icons.monitor_heart_rounded,
    title: 'Live telemetry',
    body: 'Battery, memory and network health update live while this screen is open.',
  ),
  TourStep(
    route: RouteNames.home,
    target: TourKeys.homeVitals,
    icon: Icons.thermostat_rounded,
    title: 'CPU clocks & thermals',
    body:
        'Real per-core clock speeds and Android\'s own throttling forecast, so you know when heat is about to cost FPS.',
  ),
  TourStep(
    route: RouteNames.home,
    target: TourKeys.homeStorage,
    icon: Icons.cleaning_services_rounded,
    title: 'Storage cleanup',
    body: 'Clears app caches and reports the space freed on your storage.',
  ),
  TourStep(
    route: RouteNames.home,
    target: TourKeys.homeQuickActions,
    icon: Icons.bolt_rounded,
    title: 'Quick actions',
    body: 'Shortcuts to Tweaks, Games, the gaming Network test and Device details.',
  ),
  TourStep(
    target: TourKeys.tabs[1],
    icon: Icons.sports_esports_rounded,
    title: 'Games tab',
    body: 'Every installed game is detected automatically. Let\'s take a look.',
  ),
  TourStep(
    route: RouteNames.games,
    target: TourKeys.gamesList,
    icon: Icons.tune_rounded,
    title: 'Per-game tuning',
    body:
        'Tap any game to set Game Mode, render resolution and an FPS cap, compile it for speed, then Turbo Launch.',
  ),
  TourStep(
    target: TourKeys.tabs[2],
    icon: Icons.tune_rounded,
    title: 'Tweaks tab',
    body: 'All system tweaks live here, and each one is verified on your device.',
  ),
  TourStep(
    route: RouteNames.optimization,
    target: TourKeys.tweaksStatus,
    icon: Icons.verified_user_rounded,
    title: 'Access status',
    body:
        'Shows which permissions are ready. Connect Shizuku, or grant once over ADB, to unlock more tweaks.',
  ),
  TourStep(
    route: RouteNames.optimization,
    target: TourKeys.tweaksAdvice,
    icon: Icons.insights_rounded,
    title: 'Recommended for you',
    body:
        'The app analyses your RAM, CPU, display, temperature, battery and network, then suggests tweaks with the reason for each — and warns what to skip right now.',
  ),
  TourStep(
    route: RouteNames.optimization,
    target: TourKeys.tweaksPresets,
    icon: Icons.auto_awesome_rounded,
    title: 'Presets',
    body: 'Competitive, Balanced or Battery in one tap. Your choice is remembered.',
  ),
  TourStep(
    route: RouteNames.optimization,
    target: TourKeys.tweaksActions,
    icon: Icons.flash_on_rounded,
    title: 'Maintenance actions',
    body:
        'RAM Boost and cache cleanup, plus Compile All Apps and System Dexopt with a live progress screen.',
  ),
  TourStep(
    route: RouteNames.optimization,
    target: TourKeys.tweaksList,
    icon: Icons.toggle_on_rounded,
    title: 'Real switches',
    body:
        'Each switch shows the device\'s true setting. Tap a row to see the exact command. Switching off restores your original value.',
  ),
  TourStep(
    target: TourKeys.tabs[3],
    icon: Icons.memory_rounded,
    title: 'Device tab',
    body: 'Full hardware specs, battery health and the gaming network test.',
  ),
  TourStep(
    target: TourKeys.tabs[4],
    icon: Icons.settings_rounded,
    title: 'Settings',
    body: 'Theme (light, dark, AMOLED), backups and data, and a button to replay this tour.',
  ),
  const TourStep(
    route: RouteNames.home,
    icon: Icons.celebration_rounded,
    title: 'You\'re all set!',
    body: 'Start with Boost or a preset, then tune your favourite games. Have fun!',
  ),
];

/// Current step index, or null when the tour is not running.
class FeatureTourController extends Notifier<int?> {
  static const _doneKey = 'feature_tour_done_v1';

  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  @override
  int? build() => null;

  bool get hasCompleted => _prefs?.getBool(_doneKey) ?? false;

  void start() => state = 0;

  /// Starts the tour once, for users who have never finished or skipped it.
  void startIfFirstLaunch() {
    if (_prefs != null && !hasCompleted) start();
  }

  void next() {
    final i = state;
    if (i == null) return;
    i + 1 >= featureTourSteps.length ? finish() : state = i + 1;
  }

  void back() {
    final i = state;
    if (i != null && i > 0) state = i - 1;
  }

  void finish() {
    state = null;
    unawaited(_prefs?.setBool(_doneKey, true));
  }
}

final featureTourProvider =
    NotifierProvider<FeatureTourController, int?>(FeatureTourController.new);

/// Spotlight overlay rendered above the app shell while the tour runs.
class FeatureTourOverlay extends ConsumerStatefulWidget {
  const FeatureTourOverlay({super.key, required this.location});

  /// Current router path, used to decide whether a step must navigate.
  final String location;

  @override
  ConsumerState<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends ConsumerState<FeatureTourOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final CurvedAnimation _moveCurve =
      CurvedAnimation(parent: _move, curve: Curves.easeInOutCubic);

  final GlobalKey _overlayKey = GlobalKey();
  Rect? _from;
  Rect? _to;
  bool _resolving = false;
  int _token = 0;

  @override
  void dispose() {
    _moveCurve.dispose();
    _move.dispose();
    _tap.dispose();
    super.dispose();
  }

  Rect? get _currentRect {
    if (_to == null) return null;
    if (_from == null) return _to;
    return Rect.lerp(_from, _to, _moveCurve.value);
  }

  Future<void> _resolve(int index) async {
    final token = ++_token;
    final step = featureTourSteps[index];
    setState(() => _resolving = true);

    if (step.route != null && widget.location != step.route) {
      GoRouter.of(context).go(step.route!);
      // Let the tab fade-through finish before measuring.
      await Future<void>.delayed(const Duration(milliseconds: 320));
    }

    Rect? target;
    final key = step.target;
    if (key != null) {
      for (var i = 0; i < 30 && key.currentContext == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (token != _token || !mounted) return;
      }
      final ctx = key.currentContext;
      if (ctx != null && ctx.mounted && Scrollable.maybeOf(ctx) != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.3,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
      if (token != _token || !mounted) return;
      target = _measure(key);
    }

    if (!mounted) return;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final begin = _currentRect;
    setState(() {
      _resolving = false;
      _from = begin ?? target;
      _to = target;
    });
    _move.forward(from: 0);
    if (target != null && !reduceMotion) {
      _tap.repeat();
    } else {
      _tap.stop();
    }
  }

  Rect? _measure(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    final overlay = _overlayKey.currentContext?.findRenderObject();
    if (box is! RenderBox || overlay is! RenderBox || !box.hasSize || !box.attached) {
      return null;
    }
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    return (topLeft & box.size).inflate(6);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(featureTourProvider, (prev, next) {
      if (next == null) {
        _tap.stop();
        _from = _to = null;
        return;
      }
      HapticFeedback.selectionClick();
      _resolve(next);
    });

    final index = ref.watch(featureTourProvider);
    if (index == null) return const SizedBox.shrink();
    final step = featureTourSteps[index];
    final controller = ref.read(featureTourProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) index == 0 ? controller.finish() : controller.back();
      },
      child: LayoutBuilder(
        key: _overlayKey,
        builder: (context, constraints) {
          final size = constraints.biggest;
          return AnimatedBuilder(
            animation: Listenable.merge([_move, _tap]),
            builder: (context, _) {
              final rect = _currentRect;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  if (!_resolving && rect != null && rect.contains(d.localPosition)) {
                    controller.next();
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SpotlightPainter(
                          rect: rect,
                          pulse: _tap.value,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    if (rect != null && !_resolving) _Hand(rect: rect, t: _tap.value),
                    if (!_resolving)
                      _TipCard(
                        key: ValueKey(index),
                        step: step,
                        index: index,
                        total: featureTourSteps.length,
                        target: _to,
                        area: size,
                        onNext: controller.next,
                        onBack: index > 0 ? controller.back : null,
                        onSkip: controller.finish,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.rect, required this.pulse, required this.color});

  final Rect? rect;
  final double pulse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withOpacity(0.72);
    final full = Offset.zero & size;
    if (rect == null) {
      canvas.drawRect(full, scrim);
      return;
    }
    final radius = math.min(24.0, rect!.shortestSide / 2);
    final hole = RRect.fromRectAndRadius(rect!, Radius.circular(radius));
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(full)
        ..addRRect(hole),
      scrim,
    );
    final glow = 0.5 + 0.5 * math.sin(pulse * math.pi * 2);
    canvas.drawRRect(
      hole.inflate(3 + glow * 3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = color.withOpacity(0.18 + glow * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.pulse != pulse || oldDelegate.color != color;
}

/// Animated pointing hand that "taps" the centre of the spotlight.
class _Hand extends StatelessWidget {
  const _Hand({required this.rect, required this.t});

  final Rect rect;

  /// Tap loop progress 0..1: press, ripple, release, rest.
  final double t;

  static const double _size = 58;

  @override
  Widget build(BuildContext context) {
    final press = t < 0.18
        ? Curves.easeOut.transform(t / 0.18)
        : t < 0.36
            ? 1 - Curves.easeIn.transform((t - 0.18) / 0.18)
            : 0.0;
    final ripple = ((t - 0.12) / 0.6).clamp(0.0, 1.0);
    final tip = rect.center;

    return Stack(
      children: [
        if (ripple > 0 && ripple < 1)
          Positioned(
            left: tip.dx - 36 * ripple,
            top: tip.dy - 36 * ripple,
            child: IgnorePointer(
              child: Container(
                width: 72 * ripple,
                height: 72 * ripple,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.35 * (1 - ripple)),
                  border: Border.all(color: Colors.white.withOpacity(0.7 * (1 - ripple)), width: 2),
                ),
              ),
            ),
          ),
        Positioned(
          // The glyph's fingertip sits near its top-centre.
          left: tip.dx - _size * 0.40,
          top: tip.dy - _size * 0.06 + press * 5,
          child: IgnorePointer(
            child: Transform.scale(
              scale: 1 - press * 0.12,
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.touch_app_rounded,
                size: _size,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 4))],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatefulWidget {
  const _TipCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.target,
    required this.area,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final TourStep step;
  final int index;
  final int total;
  final Rect? target;
  final Size area;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final padding = MediaQuery.paddingOf(context);
    final target = widget.target;
    final last = widget.index == widget.total - 1;

    // Card goes on the side of the target with more room.
    double? top;
    double? bottom;
    if (target == null) {
      top = null;
      bottom = null;
    } else if (target.center.dy < widget.area.height * 0.5) {
      top = math.min(target.bottom + 20, widget.area.height - 260 - padding.bottom);
    } else {
      bottom =
          math.min(widget.area.height - target.top + 20, widget.area.height - 260 - padding.top);
    }

    final card = FadeTransition(
      opacity: CurvedAnimation(parent: _in, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween(begin: Offset(0, top != null ? -0.06 : 0.06), end: Offset.zero)
            .animate(CurvedAnimation(parent: _in, curve: Curves.easeOutCubic)),
        child: GlassCard(
          level: AppGlassLevel.level4,
          blur: 18,
          padding:
              const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
                    ),
                    child: Icon(widget.step.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'STEP ${widget.index + 1} OF ${widget.total}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (!last)
                    TextButton(
                      onPressed: widget.onSkip,
                      style: TextButton.styleFrom(minimumSize: const Size(48, 36)),
                      child: const Text('Skip'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.step.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                widget.step.body,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (widget.index + 1) / widget.total,
                  minHeight: 4,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (widget.onBack != null)
                    TextButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back'),
                    ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
                    ),
                    child: FilledButton.icon(
                      onPressed: widget.onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      icon:
                          Icon(last ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 18),
                      label: Text(last ? 'Let\'s go' : (widget.index == 0 ? 'Start tour' : 'Next')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (target == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: card),
        ),
      );
    }
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: top,
      bottom: bottom,
      child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: card),
      ),
    );
  }
}
