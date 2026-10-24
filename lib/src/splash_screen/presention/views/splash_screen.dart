import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/core/common/application/riverpod/current_theme_controller.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/glass_orb_painter.dart';
import 'package:sentinel/core/widgets/sentinel_cube_logo_painter.dart';
import 'package:sentinel/src/groups/presention/app/adapter/groups_adapter.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleOut;
  late final DateTime _bootStartTime;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _bootStartTime = DateTime.now();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _fadeIn = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _scaleOut = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        ref.read(hostsAdapterProvider.notifier).getHostFromLocalBase(),
        ref.read(groupsAdapterProvider.notifier).getGroupsFromLocalBase(),
      ]);
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHomeSmoothly() async {
    if (_isNavigating) return;
    _isNavigating = true;

    final elapsed = DateTime.now().difference(_bootStartTime);
    const minSplashDuration = Duration(milliseconds: 1100);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (mounted) {
      context.go(SentinelRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final isDark =
        theme == ThemeMode.dark ||
        (theme == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final tokens = SentinelThemeTokens(isDark);
    final hostsState = ref.watch(hostsAdapterProvider);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    ref.listen(hostsAdapterProvider, (previous, next) {
      if (next is HostsLoaded) {
        _navigateToHomeSmoothly();
      }
      if (next is HostsError) {
        debugPrint(next.message);
      }
    });

    if (hostsState is HostsLoaded && !_isNavigating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToHomeSmoothly();
      });
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tokens.bgTop, tokens.bgBottom],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top-right 3D Glass Orb with gentle floating motion
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final dy = disableAnimations
                    ? 0.0
                    : math.sin(_pulseController.value * 2 * math.pi) * 10.0;
                return Positioned(top: 70 + dy, right: -45, child: child!);
              },
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: CustomPaint(
                    size: const Size(230, 230),
                    painter: GlassOrbPainter(isDark: isDark),
                  ),
                ),
              ),
            ),

            // Bottom-left secondary 3D Glass Orb
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final dy = disableAnimations
                    ? 0.0
                    : math.cos(_pulseController.value * 2 * math.pi) * 8.0;
                return Positioned(bottom: 60 + dy, left: -55, child: child!);
              },
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.65,
                    child: CustomPaint(
                      size: const Size(175, 175),
                      painter: GlassOrbPainter(isDark: isDark),
                    ),
                  ),
                ),
              ),
            ),

            // Center Ambient Radial Glow
            ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final pulse = disableAnimations
                      ? 0.5
                      : 0.5 +
                            0.5 *
                                math.sin(_pulseController.value * 2 * math.pi);
                  return IgnorePointer(
                    child: Container(
                      width: 200 + (pulse * 35),
                      height: 200 + (pulse * 35),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tokens.greenAccent.withValues(
                              alpha: isDark
                                  ? 0.10 + (pulse * 0.08)
                                  : 0.08 + (pulse * 0.05),
                            ),
                            blurRadius: 85,
                            spreadRadius: 20,
                          ),
                          if (isDark)
                            BoxShadow(
                              color: const Color(0xFF32789A)
                                  .withValues(alpha: 0.14),
                              blurRadius: 70,
                              spreadRadius: 12,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main Animated Centerpiece
            FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scaleOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 156,
                        height: 156,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                return CustomPaint(
                                  size: const Size(156, 156),
                                  painter: _OrbitalSweepPainter(
                                    progress: disableAnimations
                                        ? 0.0
                                        : _pulseController.value,
                                    accentColor: tokens.greenAccent,
                                    secondaryColor: tokens.blueAccent,
                                    isDark: isDark,
                                  ),
                                );
                              },
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(34),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 20,
                                  sigmaY: 20,
                                ),
                                child: Container(
                                  width: 112,
                                  height: 112,
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: tokens.cardSurface,
                                    borderRadius: BorderRadius.circular(34),
                                    border: Border.all(
                                      color: tokens.cardBorder,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.45 : 0.08,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: CustomPaint(
                                    painter: SentinelCubeLogoPainter(
                                      isDark: isDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Semantics(
                      header: true,
                      child: Text(
                        'Sentinel',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'INFRASTRUCTURE & SSH MESH',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Glassmorphic Status Pill
            Positioned(
              bottom: 48,
              child: FadeTransition(
                opacity: _fadeIn,
                child: _buildStatusPill(
                  hostsState,
                  tokens,
                  isDark,
                  disableAnimations,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(
    HostsState state,
    SentinelThemeTokens tokens,
    bool isDark,
    bool disableAnimations,
  ) {
    final isError = state is HostsError;
    final statusColor = isError ? tokens.redAccent : tokens.greenAccent;
    final statusText = switch (state) {
      HostsInitial() => 'Initializing encrypted vault...',
      HostsLoading() => 'Loading SSH hosts & credentials...',
      HostsLoaded(:final hosts) =>
        '${hosts.length} ${hosts.length == 1 ? 'host' : 'hosts'} ready • Launching...',
      HostsError(:final message) => message,
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: GlassCard(
        tokens: tokens,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final glow = disableAnimations
                      ? 0.5
                      : 0.4 +
                            0.6 *
                                math
                                    .sin(_pulseController.value * 2 * math.pi)
                                    .abs();
                  return Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: glow * 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 230),
              child: Text(
                statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isError ? tokens.redTextAccent : tokens.textSecondary,
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isError) ...[
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Retry loading hosts',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () {
                    ref
                        .read(hostsAdapterProvider.notifier)
                        .getHostFromLocalBase();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.redAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: tokens.redTextAccent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrbitalSweepPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color secondaryColor;
  final bool isDark;

  const _OrbitalSweepPainter({
    required this.progress,
    required this.accentColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    canvas.drawCircle(center, radius, trackPaint);

    final startAngle = progress * 2 * math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(startAngle),
        colors: [
          Colors.transparent,
          secondaryColor.withValues(alpha: 0.25),
          accentColor.withValues(alpha: 0.85),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, math.pi * 1.35, false, sweepPaint);

    final dotAngle = startAngle + math.pi * 1.35;
    final dotOffset = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );

    canvas.drawCircle(
      dotOffset,
      4.5,
      Paint()
        ..color = accentColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(dotOffset, 2.2, Paint()..color = accentColor);
  }

  @override
  bool shouldRepaint(covariant _OrbitalSweepPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
