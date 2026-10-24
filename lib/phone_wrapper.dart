import 'package:flutter/material.dart';

/// Wraps any child (such as a `MaterialApp.router` navigator or individual view)
/// inside a realistic iPhone 15 Pro bezel with Dynamic Island, status bar, and
/// home indicator bar.
class PhoneFrameWrapper extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final VoidCallback? onToggleTheme;

  const PhoneFrameWrapper({
    super.key,
    required this.isDark,
    required this.child,
    this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 393 / 852,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(54),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF7B7D82),
                    const Color(0xFF3E4044),
                    const Color(0xFF5A5D64),
                  ]
                : [
                    const Color(0xFFE5E1D8),
                    const Color(0xFF9C988E),
                    const Color(0xFFD5D0C5),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.25),
              blurRadius: 45,
              spreadRadius: 2,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4.5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.all(9.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(42),
            child: MediaQuery(
              // Inject realistic top/bottom safe area padding for Dynamic Island
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(top: 44, bottom: 20)),
              child: Stack(
                children: [
                  Positioned.fill(child: child),

                  // Decorative Dynamic Island + Status Bar Overlay (Excluded from Semantics)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '9:41',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: -0.3,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Container(
                                width: 96,
                                height: 27,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.signal_cellular_alt_rounded,
                                    size: 15,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.wifi_rounded,
                                    size: 15,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.battery_full_rounded,
                                    size: 17,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Decorative Bottom Home Indicator (Excluded from Semantics)
                  Positioned(
                    bottom: 6,
                    left: 0,
                    right: 0,
                    child: ExcludeSemantics(
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 125,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.32),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
