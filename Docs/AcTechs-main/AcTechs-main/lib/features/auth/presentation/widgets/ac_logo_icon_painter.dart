import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Draws the AC Techs brand icon: a stylised snowflake / gear hybrid
/// with animated glow ring and pulsing core.
///
/// [progress] 0→1 controls the entrance animation:
///   0-0.4  icon scales up with elastic ease
///   0.2-0.7  particle ring orbits and expands
///   0.6-1.0  glow intensifies, slight pulse
class AcLogoIconPainter extends CustomPainter {
  AcLogoIconPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
    required this.bgColor,
  });

  final double progress;
  final Color primaryColor;
  final Color accentColor;
  final Color bgColor;

  double _c(double v) => v.clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(cx, cy) * 0.85;

    // ── Outer glow ring ──────────────────────────────────────
    final ringP = _c((progress - 0.15) / 0.5);
    if (ringP > 0) {
      final ringR = maxR * (0.7 + 0.3 * ringP);
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = primaryColor.withValues(alpha: 0.15 * ringP)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = primaryColor.withValues(alpha: 0.25 * ringP),
      );

      // Orbiting particles on ring
      final orbitAngle = progress * math.pi * 4;
      for (var i = 0; i < 8; i++) {
        final a = orbitAngle + i * math.pi / 4;
        final px = cx + math.cos(a) * ringR;
        final py = cy + math.sin(a) * ringR;
        final pAlpha = (0.4 + math.sin(a * 2) * 0.3) * ringP;
        canvas.drawCircle(
          Offset(px, py),
          2.5,
          Paint()..color = accentColor.withValues(alpha: pAlpha),
        );
        canvas.drawCircle(
          Offset(px, py),
          6,
          Paint()
            ..color = accentColor.withValues(alpha: pAlpha * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // ── Core icon scale entrance ─────────────────────────────
    final scaleP = _c(progress / 0.45);
    final scale = Curves.elasticOut.transform(scaleP);
    if (scale <= 0) return;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    // ── Soft glow behind icon ────────────────────────────────
    canvas.drawCircle(
      Offset.zero,
      maxR * 0.55,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.08 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // ── Main snowflake: 6 arms with branches ─────────────────
    final armLen = maxR * 0.48;
    final armPaint = Paint()
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var arm = 0; arm < 6; arm++) {
      final a = arm * math.pi / 3 - math.pi / 2;

      // Gradient along arm
      final endX = math.cos(a) * armLen;
      final endY = math.sin(a) * armLen;

      armPaint.shader = ui.Gradient.linear(Offset.zero, Offset(endX, endY), [
        primaryColor.withValues(alpha: 0.9),
        accentColor.withValues(alpha: 0.6),
      ]);

      // Main arm
      canvas.drawLine(Offset.zero, Offset(endX, endY), armPaint);

      // Branches at 55% and 80%
      for (final t in [0.55, 0.80]) {
        final bx = endX * t;
        final by = endY * t;
        final branchLen = armLen * 0.28 * (1.2 - t);

        for (final dir in [1, -1]) {
          final ba = a + dir * math.pi / 4;
          canvas.drawLine(
            Offset(bx, by),
            Offset(
              bx + math.cos(ba) * branchLen,
              by + math.sin(ba) * branchLen,
            ),
            Paint()
              ..strokeWidth = 2.0
              ..strokeCap = StrokeCap.round
              ..color = primaryColor.withValues(alpha: 0.7),
          );
        }
      }

      // Diamond tip
      final tipPath = Path()
        ..moveTo(endX, endY - 3)
        ..lineTo(endX + 3, endY)
        ..lineTo(endX, endY + 3)
        ..lineTo(endX - 3, endY)
        ..close();
      canvas.drawPath(
        tipPath,
        Paint()..color = accentColor.withValues(alpha: 0.8),
      );
    }

    // ── Centre hexagonal core ────────────────────────────────
    final hexR = maxR * 0.14;
    final hexPath = Path();
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 2;
      final hx = math.cos(a) * hexR;
      final hy = math.sin(a) * hexR;
      if (i == 0) {
        hexPath.moveTo(hx, hy);
      } else {
        hexPath.lineTo(hx, hy);
      }
    }
    hexPath.close();

    // Filled hex
    canvas.drawPath(
      hexPath,
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, hexR, [
          primaryColor.withValues(alpha: 0.6),
          accentColor.withValues(alpha: 0.3),
        ]),
    );
    // Hex border
    canvas.drawPath(
      hexPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = primaryColor.withValues(alpha: 0.8),
    );

    // Gear teeth around hex (AC/mechanical hint)
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final innerR = hexR * 1.05;
      final outerR = hexR * 1.25;
      canvas.drawLine(
        Offset(math.cos(a) * innerR, math.sin(a) * innerR),
        Offset(math.cos(a) * outerR, math.sin(a) * outerR),
        Paint()
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = primaryColor.withValues(alpha: 0.5),
      );
    }

    // Centre specular dot
    canvas.drawCircle(
      const Offset(-1.5, -1.5),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.3 * progress),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AcLogoIconPainter old) =>
      old.progress != progress;
}
