import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const LockSyncApp());
}

class LockSyncApp extends StatelessWidget {
  const LockSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LockSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF040608),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4FF),
          surface: Color(0xFF080C10),
        ),
      ),
      home: const MobileLandingScreen(),
    );
  }
}

class MobileLandingScreen extends StatelessWidget {
  const MobileLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C10),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: const IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(height: 12),

                            // Brand & Graphic
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BrandWordmark(),
                                SizedBox(height: 10),
                                Text(
                                  'Your lock, redefined.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF7A889B),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                SizedBox(height: 42),
                                SmartLockGraphic(),
                              ],
                            ),

                            // Bottom Actions & Footer
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 32),
                                BottomActionsSection(),
                                SizedBox(height: 12),
                              ],
                            ),
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
    );
  }
}

// ==========================================
// 2. BRAND WORDMARK
// ==========================================
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 27,
          fontWeight: FontWeight.w800,
          letterSpacing: 3.2,
        ),
        children: [
          TextSpan(
            text: 'LOCK',
            style: TextStyle(
              color: Color(0xFFF1F5F9), // Near-white
            ),
          ),
          TextSpan(
            text: 'SYNC',
            style: TextStyle(
              color: Color(0xFF00D4FF), // Vivid Cyan
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. SMART LOCK VISUAL & ARDUINO CIRCUITRY
// ==========================================
class SmartLockGraphic extends StatelessWidget {
  const SmartLockGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Faint cyan ambient glow around lock
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.12),
                  blurRadius: 52,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // Custom Painted Technical Lock & Circuit Details
          CustomPaint(
            size: const Size(210, 210),
            painter: ArduinoLockPainter(),
          ),
        ],
      ),
    );
  }
}

class ArduinoLockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Outer Circuit Track Ring (Subtle PCB boundary)
    final outerRingPaint = Paint()
      ..color = const Color(0xFF142433)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 94, outerRingPaint);

    // 2. Arduino Circuit Traces & PCB Vias (Understated details)
    final circuitTracePaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final viaPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final viaHolePaint = Paint()
      ..color = const Color(0xFF080C10)
      ..style = PaintingStyle.fill;

    // Helper to draw a circuit via (PCB through-hole pad)
    void drawVia(Offset pos) {
      canvas.drawCircle(pos, 2.5, viaPaint);
      canvas.drawCircle(pos, 1.2, viaHolePaint);
    }

    // 4 Orthogonal Circuit Leads (representing GPIO / UART connections)
    // Top lead
    canvas.drawLine(
      Offset(center.dx, center.dy - 78),
      Offset(center.dx, center.dy - 98),
      circuitTracePaint,
    );
    drawVia(Offset(center.dx, center.dy - 98));

    // Bottom lead
    canvas.drawLine(
      Offset(center.dx, center.dy + 78),
      Offset(center.dx, center.dy + 98),
      circuitTracePaint,
    );
    drawVia(Offset(center.dx, center.dy + 98));

    // Left lead with 45-degree angle trace
    final leftPath = Path()
      ..moveTo(center.dx - 78, center.dy)
      ..lineTo(center.dx - 88, center.dy)
      ..lineTo(center.dx - 98, center.dy - 10);
    canvas.drawPath(leftPath, circuitTracePaint);
    drawVia(Offset(center.dx - 98, center.dy - 10));

    // Right lead with 45-degree angle trace
    final rightPath = Path()
      ..moveTo(center.dx + 78, center.dy)
      ..lineTo(center.dx + 88, center.dy)
      ..lineTo(center.dx + 98, center.dy + 10);
    canvas.drawPath(rightPath, circuitTracePaint);
    drawVia(Offset(center.dx + 98, center.dy + 10));

    // Micro Pin Indicators (4 Cardinal points around outer circumference)
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final r1 = 89.0;
      final r2 = 94.0;
      final p1 = Offset(center.dx + r1 * math.cos(angle), center.dy + r1 * math.sin(angle));
      final p2 = Offset(center.dx + r2 * math.cos(angle), center.dy + r2 * math.sin(angle));
      canvas.drawLine(p1, p2, circuitTracePaint);
    }

    // 3. Primary Cyan Illuminated Ring
    // Outer subtle glow stroke
    final ringGlowPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2;
    canvas.drawCircle(center, 74, ringGlowPaint);

    // Crisp high-contrast cyan ring
    final illuminatedRingPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, 74, illuminatedRingPaint);

    // Inner hairline concentric ring
    final innerHairline = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, 63, innerHairline);

    // 4. Central Refined Smart-Lock Icon
    // Shackle (Top U-shape)
    final shacklePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final shacklePath = Path()
      ..moveTo(center.dx - 13, center.dy - 9)
      ..lineTo(center.dx - 13, center.dy - 23)
      ..arcToPoint(
        Offset(center.dx + 13, center.dy - 23),
        radius: const Radius.circular(13),
      )
      ..lineTo(center.dx + 13, center.dy - 9);
    canvas.drawPath(shacklePath, shacklePaint);

    // Lock Body (Geometric technical enclosure)
    final bodyPaint = Paint()
      ..color = const Color(0xFF0D1622)
      ..style = PaintingStyle.fill;

    final bodyBorderPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 8),
        width: 44,
        height: 34,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, bodyBorderPaint);

    // Center Core / Keyhole & Status Aperture
    final coreDotPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + 6), 3.2, coreDotPaint);

    final keywayPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy + 7),
      Offset(center.dx, center.dy + 14),
      keywayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// 4. BOTTOM ACTIONS & FOOTER
// ==========================================
class BottomActionsSection extends StatelessWidget {
  const BottomActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary Action: GET STARTED
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(initialMode: AuthMode.signUp),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: const Color(0xFF080C10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Global 10px radius
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'GET STARTED',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: Color(0xFF080C10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary Action: SIGN IN
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(initialMode: AuthMode.signIn),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF080C10),
              foregroundColor: const Color(0xFF00D4FF),
              side: const BorderSide(
                color: Color(0xFF00D4FF),
                width: 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Global 10px radius
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'SIGN IN',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                color: Color(0xFF00D4FF),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Footer Text
        const Text(
          'SECURE • CONNECTED • IN CONTROL',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5A6D), // Muted gray
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}
