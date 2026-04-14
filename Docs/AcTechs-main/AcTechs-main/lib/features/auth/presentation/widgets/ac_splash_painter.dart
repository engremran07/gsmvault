import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Inline colour constants for [AcSplashPainter].
/// Private to this file — animation-only colours not in AppColors.
class _C {
  _C._();

  // — Technician vest (safety-orange gradient) —
  static const vestAmber = Color(0xFFFF9800);
  static const vestOrange = Color(0xFFF57C00);
  static const vestBurnt = Color(0xFFE65100);

  // — Reflective stripe glow —
  static const stripeEdge = Color(0x00FFE082);
  static const stripeGlow = Color(0xCCFFE082);

  // — Skin tone —
  static const skin = Color(0xFFDEB887);

  // — Safety helmet (red gradient) —
  static const helmetRed = Color(0xFFEF5350);
  static const helmetMid = Color(0xFFD32F2F);
  static const helmetDark = Color(0xFF8B0000);

  // — Trousers & boots —
  static const trouserBlue = Color(0xFF1A237E);
  static const trouserNavy = Color(0xFF1A2744);
  static const darkBrown = Color(0xFF3E2723);

  // — Tool belt & pouches —
  static const beltBrown = Color(0xFF5D4037);
  static const pouchBrown = Color(0xFF4E342E);

  // — Metal / tools —
  static const silver = Color(0xFFBDBDBD);
  static const metalMid = Color(0xFF757575);
  static const metalDark = Color(0xFF616161);
  static const metalDeep = Color(0xFF424242);

  // — Sparks & arcs —
  static const sparkYellow = Color(0xFFFFFF00);
  static const sparkHot = Color(0xFFFF6D00);
  static const sparkGlow = Color(0xFFFFAB00);

  // — LED diagnostics —
  static const ledOrange = Color(0xFFFF5722);
  static const ledGreen = Color(0xFF4CAF50);
}

/// Peak-level custom-painted splash animation for AC Techs.
///
/// 6 phases over normalised [progress] 0→1 (mapped to ~5 seconds of scene
/// after the logo intro handled by the parent widget):
///
///   Phase 1 — Cinematic room construction: 3-D perspective walls, tiled
///             floor with vanishing point, ambient light rays, floating dust.
///   Phase 2 — AC unit materialises: holographic wireframe → solid fill,
///             multi-layer metallic gradients, specular highlights, shadow
///             cast, rotating fan visible through vent slats.
///   Phase 3 — Technician enters with joint-based limbs, reflective vest,
///             helmet shine, tool belt, bob + limb swing, floor shadow.
///   Phase 4 — Electric arc welding sparks with bezier comet trails, smoke
///             wisps, flash bloom, LED diagnostics sequence.
///   Phase 5 — Cool-air blast: layered wave fronts, tumbling 6-arm snowflakes,
///             frost crystallisation creep, temperature-gradient overlay.
///   Phase 6 — Ambient settle: room glow, gentle particle drift, final polish.
class AcSplashPainter extends CustomPainter {
  AcSplashPainter({
    required this.progress,
    required this.bgColor,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  });

  final double progress;
  final Color bgColor;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  // Phase boundaries (normalised)
  static const _p1End = 0.20;
  static const _p2End = 0.36;
  static const _p3End = 0.54;
  static const _p4End = 0.72;
  static const _p5End = 0.90;
  // Phase 6: 0.90 → 1.0

  double _c(double v) => v.clamp(0.0, 1.0);
  double _ph(double s, double e) => _c((progress - s) / (e - s));

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    _drawBackground(canvas, size, cx, cy);
    _drawAmbientRays(canvas, size, cx, cy);
    _drawRoom(canvas, size, cx, cy);
    _drawDustMotes(canvas, size, cx, cy);

    if (progress > _p1End) _drawAcUnit(canvas, size, cx, cy);
    if (progress > _p2End) _drawTechnician(canvas, size, cx, cy);
    if (progress > _p3End) _drawSparks(canvas, size, cx, cy);
    if (progress > _p3End) _drawLed(canvas, cx, cy, size);
    if (progress > _p4End) _drawCoolAir(canvas, size, cx, cy);
    if (progress > _p5End) _drawAmbientSettle(canvas, size, cx, cy);
  }

  // ===================================================================
  //  PHASE 1: BACKGROUND — deep gradient + vignette
  // ===================================================================
  void _drawBackground(Canvas canvas, Size size, double cx, double cy) {
    final p = _ph(0, _p1End);

    // multi-stop radial gradient background
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy * 0.7),
        size.longestSide * 0.8,
        [
          Color.lerp(Colors.black, bgColor, p * 0.9)!,
          Color.lerp(
            Colors.black,
            Color.lerp(bgColor, primaryColor.withValues(alpha: 0.12), 0.3),
            p,
          )!,
          Color.lerp(Colors.black, bgColor.withValues(alpha: 0.7), p * 0.6)!,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Offset.zero & size, bgPaint);

    // vignette overlay
    if (p > 0.2) {
      final vigAlpha = (p - 0.2) * 0.5;
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy * 0.75),
            size.longestSide * 0.55,
            [Colors.transparent, Colors.black.withValues(alpha: vigAlpha)],
          ),
      );
    }
  }

  // ===================================================================
  //  AMBIENT LIGHT RAYS (volumetric streaks from top-right)
  // ===================================================================
  void _drawAmbientRays(Canvas canvas, Size size, double cx, double cy) {
    final p = _ph(0.05, _p1End);
    if (p <= 0) return;

    final rayOrigin = Offset(size.width * 0.82, size.height * 0.05);
    final rayPaint = Paint()..strokeCap = StrokeCap.round;

    for (var i = 0; i < 7; i++) {
      final angle = 0.35 + i * 0.12;
      final length = size.longestSide * (0.5 + i * 0.06) * p;
      final width = 1.2 + i * 0.6;
      final alpha = (0.03 + i * 0.005) * p;

      rayPaint
        ..strokeWidth = width
        ..color = primaryColor.withValues(alpha: alpha);

      canvas.drawLine(
        rayOrigin,
        Offset(
          rayOrigin.dx - math.cos(angle) * length,
          rayOrigin.dy + math.sin(angle) * length,
        ),
        rayPaint,
      );
    }
  }

  // ===================================================================
  //  ROOM: 3-D perspective walls + tiled floor
  // ===================================================================
  void _drawRoom(Canvas canvas, Size size, double cx, double cy) {
    final p = _ph(0, _p1End);
    if (p == 0) return;

    // ── back wall ──────────────────────────────────────────────
    final wallW = size.width * 0.80;
    final wallH = size.height * 0.50;
    final wallTop = cy * 0.52;
    final wallRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, wallTop), width: wallW, height: wallH),
      const Radius.circular(4),
    );

    // Wall gradient: subtle directional lighting from top-right
    canvas.drawRRect(
      wallRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx + wallW * 0.4, wallTop - wallH * 0.4),
          Offset(cx - wallW * 0.4, wallTop + wallH * 0.4),
          [
            primaryColor.withValues(alpha: 0.10 * p),
            primaryColor.withValues(alpha: 0.04 * p),
            bgColor.withValues(alpha: 0.50 * p),
          ],
          [0.0, 0.4, 1.0],
        ),
    );

    // Wall texture: subtle horizontal brick lines
    final brickPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.04 * p)
      ..strokeWidth = 0.5;
    final wallLeft = cx - wallW / 2;
    final wallRight = cx + wallW / 2;
    final wallTopY = wallTop - wallH / 2;
    for (var row = 0; row < 18; row++) {
      final y = wallTopY + row * (wallH / 18);
      canvas.drawLine(
        Offset(wallLeft + 6, y),
        Offset(wallRight - 6, y),
        brickPaint,
      );
      // staggered vertical joints
      final stagger = (row % 2 == 0) ? 0.0 : wallW / 12;
      for (var col = 0; col < 6; col++) {
        final x = wallLeft + stagger + col * (wallW / 6);
        if (x > wallLeft + 6 && x < wallRight - 6) {
          canvas.drawLine(Offset(x, y), Offset(x, y + wallH / 18), brickPaint);
        }
      }
    }

    // Wall border (subtle glow)
    canvas.drawRRect(
      wallRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = primaryColor.withValues(alpha: 0.10 * p),
    );

    // ── floor (perspective trapezoid with tile grid) ───────────
    final floorTopY = wallTop + wallH * 0.5;
    final floorBotY = size.height * 0.92;
    final floorPath = Path()
      ..moveTo(cx - wallW * 0.50, floorTopY)
      ..lineTo(cx + wallW * 0.50, floorTopY)
      ..lineTo(cx + size.width * 0.55, floorBotY)
      ..lineTo(cx - size.width * 0.55, floorBotY)
      ..close();

    // Floor gradient
    canvas.drawPath(
      floorPath,
      Paint()
        ..shader =
            ui.Gradient.linear(Offset(cx, floorTopY), Offset(cx, floorBotY), [
              primaryColor.withValues(alpha: 0.08 * p),
              primaryColor.withValues(alpha: 0.02 * p),
            ]),
    );

    // Perspective grid lines on floor
    canvas.save();
    canvas.clipPath(floorPath);
    final gridP = Paint()
      ..color = primaryColor.withValues(alpha: 0.05 * p)
      ..strokeWidth = 0.6;

    // Horizontal lines
    for (var i = 0; i < 10; i++) {
      final t = i / 10.0;
      final y = floorTopY + (floorBotY - floorTopY) * t;
      final spread = 0.50 + (0.55 - 0.50) * t;
      canvas.drawLine(
        Offset(cx - size.width * spread, y),
        Offset(cx + size.width * spread, y),
        gridP,
      );
    }

    // Radial lines converging at vanishing point
    for (var i = -5; i <= 5; i++) {
      final baseX = cx + i * (size.width * 0.11);
      canvas.drawLine(
        Offset(cx + i * wallW * 0.04, floorTopY),
        Offset(baseX, floorBotY),
        gridP,
      );
    }
    canvas.restore();

    // Floor border
    canvas.drawPath(
      floorPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = primaryColor.withValues(alpha: 0.06 * p),
    );

    // ── ceiling line + left/right side wall hints ──────────────
    final ceilY = wallTop - wallH * 0.5;
    final sidePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.06 * p)
      ..strokeWidth = 1.0;

    // Left wall edge
    canvas.drawLine(
      Offset(cx - wallW * 0.50, ceilY),
      Offset(cx - size.width * 0.55, floorBotY),
      sidePaint,
    );
    // Right wall edge
    canvas.drawLine(
      Offset(cx + wallW * 0.50, ceilY),
      Offset(cx + size.width * 0.55, floorBotY),
      sidePaint,
    );
  }

  // ===================================================================
  //  FLOATING DUST MOTES (ambient particles through whole animation)
  // ===================================================================
  void _drawDustMotes(Canvas canvas, Size size, double cx, double cy) {
    final p = _ph(0.08, 0.30);
    if (p <= 0) return;

    final rng = math.Random(54321);
    const count = 25;

    for (var i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = cy * 0.4 + rng.nextDouble() * size.height * 0.45;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * math.pi * 2;

      // Gentle floating motion
      final t = progress * speed + phase;
      final x = baseX + math.sin(t * 2.5) * 15;
      final y = baseY + math.cos(t * 1.8) * 10 - progress * 20;

      final alpha = (p * (0.08 + rng.nextDouble() * 0.12)).clamp(0.0, 0.2);
      final r = 0.8 + rng.nextDouble() * 1.5;

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = textColor.withValues(alpha: alpha),
      );

      // soft glow
      canvas.drawCircle(
        Offset(x, y),
        r * 3,
        Paint()
          ..color = primaryColor.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  // ===================================================================
  //  AC UNIT — holographic wireframe → solid, metallic multi-layer
  // ===================================================================
  void _drawAcUnit(Canvas canvas, Size size, double cx, double cy) {
    final p = _ph(_p1End, _p2End);
    if (p == 0) return;

    final acW = size.width * 0.40;
    final acH = size.height * 0.12;
    final acX = cx;
    final acY = cy * 0.55;

    // Entry: scale with elastic ease
    final scale = 0.5 + 0.5 * Curves.elasticOut.transform(_c(p * 1.3));

    canvas.save();
    canvas.translate(acX, acY);
    canvas.scale(scale);

    // ── deep shadow ──────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(5, 8), width: acW, height: acH),
        const Radius.circular(10),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45 * p)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: acW, height: acH),
      const Radius.circular(10),
    );

    // ── Phase A (0-0.5): holographic wireframe ───────────────────
    if (p < 0.5) {
      final wp = _c(p / 0.5);
      // Wireframe outline with scan-line effect
      final wirePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = primaryColor.withValues(alpha: 0.6 * wp);
      canvas.drawRRect(bodyRect, wirePaint);

      // Horizontal scan lines sweeping down
      final scanY = -acH / 2 + wp * acH;
      canvas.drawLine(
        Offset(-acW / 2 + 5, scanY),
        Offset(acW / 2 - 5, scanY),
        Paint()
          ..color = primaryColor.withValues(alpha: 0.8 * (1 - wp))
          ..strokeWidth = 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Wireframe vent lines
      for (var i = 0; i < 6; i++) {
        final vy = -acH * 0.2 + i * acH * 0.10;
        final lineP = _c((wp - i * 0.1) / 0.4);
        if (lineP > 0) {
          canvas.drawLine(
            Offset(-acW * 0.38, vy),
            Offset(-acW * 0.38 + acW * 0.76 * lineP, vy),
            wirePaint,
          );
        }
      }
    }

    // ── Phase B (0.3-1.0): solid body ────────────────────────────
    if (p > 0.3) {
      final sp = _c((p - 0.3) / 0.7);

      // Main body: 4-stop metallic gradient
      final bodyPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(-acW / 2, -acH / 2),
          Offset(acW / 2, acH / 2),
          [
            Color.lerp(primaryColor, Colors.white, 0.40)!.withValues(alpha: sp),
            primaryColor.withValues(alpha: sp),
            Color.lerp(primaryColor, bgColor, 0.45)!.withValues(alpha: sp),
            Color.lerp(
              primaryColor,
              Colors.white,
              0.15,
            )!.withValues(alpha: sp * 0.8),
          ],
          [0.0, 0.35, 0.70, 1.0],
        );
      canvas.drawRRect(bodyRect, bodyPaint);

      // Top specular highlight band
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(acW * 0.05, -acH * 0.28),
            width: acW * 0.70,
            height: acH * 0.18,
          ),
          const Radius.circular(20),
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(-acW * 0.3, -acH * 0.3),
            Offset(acW * 0.3, -acH * 0.2),
            [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.18 * sp),
              Colors.white.withValues(alpha: 0.0),
            ],
            [0.0, 0.5, 1.0],
          ),
      );

      // Vent slats with depth (shadow + body + highlight)
      for (var i = 0; i < 7; i++) {
        final vy = -acH * 0.18 + i * acH * 0.08;
        canvas.drawLine(
          Offset(-acW * 0.36, vy + 1.5),
          Offset(acW * 0.36, vy + 1.5),
          Paint()
            ..strokeWidth = 2.5
            ..color = bgColor.withValues(alpha: 0.3 * sp),
        );
        canvas.drawLine(
          Offset(-acW * 0.36, vy),
          Offset(acW * 0.36, vy),
          Paint()
            ..strokeWidth = 2.0
            ..color = Color.lerp(
              primaryColor,
              bgColor,
              0.3,
            )!.withValues(alpha: 0.6 * sp),
        );
        canvas.drawLine(
          Offset(-acW * 0.36, vy - 0.8),
          Offset(acW * 0.36, vy - 0.8),
          Paint()
            ..strokeWidth = 0.5
            ..color = Colors.white.withValues(alpha: 0.08 * sp),
        );
      }

      // Rotating fan blades visible through vents (after cool air starts)
      if (progress > _p4End) {
        final fanP = _ph(_p4End, 1.0);
        final fanAngle = fanP * math.pi * 8;
        final fanR = acH * 0.22;

        canvas.save();
        canvas.translate(0, acH * 0.05);
        canvas.rotate(fanAngle);
        final fanPaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.12 * fanP)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
        for (var b = 0; b < 5; b++) {
          final a = b * math.pi * 2 / 5;
          canvas.drawLine(
            Offset.zero,
            Offset(math.cos(a) * fanR, math.sin(a) * fanR),
            fanPaint,
          );
        }
        canvas.restore();
      }

      // Border with subtle glow
      canvas.drawRRect(
        bodyRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = primaryColor.withValues(alpha: 0.25 * sp),
      );

      // Outer glow halo
      canvas.drawRRect(
        bodyRect.inflate(3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = primaryColor.withValues(alpha: 0.06 * sp)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // ── bottom flap (3-D depth with gradient) ──────────────────
      final flapOpen = _c((sp - 0.4) / 0.6);
      if (flapOpen > 0) {
        final flapH = acH * 0.20 * flapOpen;
        final flapPath = Path()
          ..moveTo(-acW * 0.46, acH * 0.46)
          ..lineTo(acW * 0.46, acH * 0.46)
          ..lineTo(acW * 0.42, acH * 0.46 + flapH)
          ..lineTo(-acW * 0.42, acH * 0.46 + flapH)
          ..close();
        canvas.drawPath(
          flapPath,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, acH * 0.46),
              Offset(0, acH * 0.46 + flapH),
              [
                primaryColor.withValues(alpha: 0.5 * sp),
                Color.lerp(
                  primaryColor,
                  bgColor,
                  0.5,
                )!.withValues(alpha: 0.2 * sp),
              ],
            ),
        );
        canvas.drawLine(
          Offset(-acW * 0.46, acH * 0.46),
          Offset(acW * 0.46, acH * 0.46),
          Paint()
            ..strokeWidth = 0.8
            ..color = Colors.white.withValues(alpha: 0.1 * sp),
        );
      }

      // ── mounting brackets with bolts ───────────────────────────
      for (final bx in [-acW * 0.32, acW * 0.32]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(bx, -acH * 0.62),
              width: 16,
              height: 10,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = primaryColor.withValues(alpha: 0.25 * sp),
        );
        canvas.drawCircle(
          Offset(bx, -acH * 0.62),
          2.5,
          Paint()..color = Colors.white.withValues(alpha: 0.15 * sp),
        );
      }
    }

    canvas.restore();
  }

  // ===================================================================
  //  TECHNICIAN — anatomically proportioned, joint-based animation
  // ===================================================================
  void _drawTechnician(Canvas canvas, Size size, double cx, double cy) {
    final walkP = _ph(_p2End, _p3End);
    if (walkP == 0) return;

    final easedWalk = Curves.easeInOutCubic.transform(walkP);

    final startX = size.width * -0.08;
    final endX = cx - size.width * 0.10;
    final techX = startX + (endX - startX) * easedWalk;
    final techFloorY = cy * 1.05 + size.height * 0.20;

    final walking = walkP < 0.95;
    final bobY = walking ? math.sin(walkP * 18) * 3.5 : 0.0;

    canvas.save();
    canvas.translate(techX, techFloorY + bobY);

    final h = size.height * 0.16;
    final w = h * 0.35;

    // ── floor shadow ─────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(2, h * 0.02),
        width: w * 2.2,
        height: w * 0.55,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── legs with knee joints ────────────────────────────────
    final legCycle = walking ? walkP * 20 : 0.0;
    final leftLegAngle = walking ? math.sin(legCycle) * 0.25 : 0.0;
    final rightLegAngle = walking ? math.sin(legCycle + math.pi) * 0.25 : 0.0;

    _drawLeg(canvas, -w * 0.18, -h * 0.18, h, w, leftLegAngle);
    _drawLeg(canvas, w * 0.18, -h * 0.18, h, w, rightLegAngle);

    // ── torso (safety vest with reflective stripes) ──────────
    final vestGrad = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-w / 2, -h * 0.45),
        Offset(w / 2, -h * 0.15),
        [_C.vestAmber, _C.vestOrange, _C.vestBurnt],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -h * 0.30),
          width: w,
          height: h * 0.35,
        ),
        const Radius.circular(4),
      ),
      vestGrad,
    );

    // Reflective stripes (2 horizontal)
    for (final sy in [-h * 0.34, -h * 0.26]) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(0, sy), width: w * 0.85, height: 2.2),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(-w * 0.4, sy),
            Offset(w * 0.4, sy),
            [_C.stripeEdge, _C.stripeGlow, _C.stripeEdge],
            [0.0, 0.5, 1.0],
          ),
      );
    }

    // ── tool belt ────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -h * 0.17), width: w * 1.05, height: 4),
      Paint()..color = _C.beltBrown,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -h * 0.17), width: 6, height: 5),
        const Radius.circular(1),
      ),
      Paint()..color = _C.silver,
    );
    for (final px in [-w * 0.35, w * 0.35]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(px, -h * 0.13),
            width: w * 0.22,
            height: h * 0.06,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = _C.pouchBrown,
      );
    }

    // ── arms with swing ──────────────────────────────────────
    final armCycle = walking ? walkP * 20 : 0.0;
    final leftArmAngle = walking ? math.sin(armCycle + math.pi) * 0.3 : -0.15;
    final rightArmAngle = walking ? math.sin(armCycle) * 0.3 : 0.2;

    _drawArm(canvas, -w * 0.52, -h * 0.40, h, w, leftArmAngle, false);
    _drawArm(canvas, w * 0.52, -h * 0.40, h, w, rightArmAngle, !walking);

    // ── neck ─────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, -h * 0.48),
        width: w * 0.22,
        height: h * 0.06,
      ),
      Paint()..color = _C.skin,
    );

    // ── head ─────────────────────────────────────────────────
    final headR = w * 0.38;
    final headY = -h * 0.56;

    canvas.drawCircle(Offset(0, headY), headR, Paint()..color = _C.skin);

    // ── safety helmet (with shine) ───────────────────────────
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, headY - headR * 0.05),
        width: headR * 2.4,
        height: headR * 2.2,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(headR * 0.3, headY - headR * 0.3),
          headR * 1.8,
          [_C.helmetRed, _C.helmetMid, _C.helmetDark],
          [0.0, 0.5, 1.0],
        ),
    );

    // Helmet shine arc
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(headR * 0.15, headY - headR * 0.3),
        width: headR * 1.2,
        height: headR * 0.8,
      ),
      math.pi * 1.1,
      math.pi * 0.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.25),
    );

    // Helmet brim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, headY + headR * 0.05),
          width: headR * 2.8,
          height: 3.5,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = _C.helmetDark,
    );

    // Eye dot
    canvas.drawCircle(
      Offset(headR * 0.25, headY + headR * 0.1),
      1.5,
      Paint()..color = _C.darkBrown,
    );

    canvas.restore();
  }

  void _drawLeg(
    Canvas canvas,
    double x,
    double topY,
    double h,
    double w,
    double angle,
  ) {
    canvas.save();
    canvas.translate(x, topY);
    canvas.rotate(angle);

    // Upper leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, h * 0.06),
          width: w * 0.30,
          height: h * 0.16,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-w * 0.15, 0),
          Offset(w * 0.15, 0),
          [
            _C.trouserBlue.withValues(alpha: 0.8),
            _C.trouserNavy,
            _C.trouserBlue.withValues(alpha: 0.8),
          ],
          [0.0, 0.5, 1.0],
        ),
    );

    // Lower leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, h * 0.15),
          width: w * 0.26,
          height: h * 0.12,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = _C.trouserNavy,
    );

    // Boot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.04, h * 0.21),
          width: w * 0.32,
          height: h * 0.04,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = _C.darkBrown,
    );

    canvas.restore();
  }

  void _drawArm(
    Canvas canvas,
    double x,
    double topY,
    double h,
    double w,
    double angle,
    bool holdingTool,
  ) {
    canvas.save();
    canvas.translate(x, topY);
    canvas.rotate(angle);

    // Sleeve
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, h * 0.06),
          width: w * 0.24,
          height: h * 0.12,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = _C.vestOrange,
    );

    // Forearm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, h * 0.14),
          width: w * 0.20,
          height: h * 0.10,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = _C.skin,
    );

    // Hand
    canvas.drawCircle(Offset(0, h * 0.19), w * 0.10, Paint()..color = _C.skin);

    if (holdingTool) {
      // Wrench handle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(1, h * 0.25),
            width: 3.5,
            height: h * 0.14,
          ),
          const Radius.circular(1.5),
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(-2, h * 0.20),
            Offset(4, h * 0.20),
            [_C.metalMid, _C.silver, _C.metalMid],
            [0.0, 0.5, 1.0],
          ),
      );
      // Wrench head
      canvas.drawCircle(Offset(1, h * 0.33), 5, Paint()..color = _C.metalDark);
      canvas.drawCircle(
        Offset(1, h * 0.33),
        2.5,
        Paint()..color = _C.metalDeep,
      );
    }

    canvas.restore();
  }

  // ===================================================================
  //  SPARKS — electric arc with bezier comet trails + smoke
  // ===================================================================
  void _drawSparks(Canvas canvas, Size size, double cx, double cy) {
    final p = _ph(_p3End, _p4End);
    if (p == 0) return;

    final origin = Offset(cx - size.width * 0.04, cy * 0.62);
    final rng = math.Random(99887);

    // ── Smoke wisps (behind sparks) ──────────────────────────
    for (var i = 0; i < 8; i++) {
      final delay = i * 0.06;
      final sp = _c((p - delay) / 0.6);
      if (sp <= 0) continue;

      final smokeX = origin.dx + rng.nextDouble() * 30 - 15;
      final smokeY = origin.dy - sp * (40 + rng.nextDouble() * 50);
      final smokeR = 6 + sp * 14;
      final smokeA = (1 - sp) * 0.08;

      canvas.drawCircle(
        Offset(smokeX + math.sin(sp * 4) * 8, smokeY),
        smokeR,
        Paint()
          ..color = textColor.withValues(alpha: smokeA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // ── Spark particles with comet trails ────────────────────
    for (var i = 0; i < 24; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 35.0 + rng.nextDouble() * 80.0;
      final delay = rng.nextDouble() * 0.35;
      final sp = _c((p - delay) / 0.55);

      if (sp <= 0 || sp >= 0.99) continue;

      final gravity = sp * sp * 35;
      final x = origin.dx + math.cos(angle) * speed * sp;
      final y = origin.dy + math.sin(angle) * speed * sp * 0.7 + gravity;

      final alpha = ((1.0 - sp) * 0.95).clamp(0.0, 1.0);
      final r = (3.0 - sp * 2.5).clamp(0.5, 3.5);

      final sparkColor = Color.lerp(
        _C.sparkYellow,
        _C.sparkHot,
        sp,
      )!.withValues(alpha: alpha);

      // Comet trail (3 trailing dots)
      for (var t = 1; t <= 3; t++) {
        final trailSp = _c(sp - t * 0.04);
        final tx = origin.dx + math.cos(angle) * speed * trailSp;
        final ty =
            origin.dy +
            math.sin(angle) * speed * trailSp * 0.7 +
            trailSp * trailSp * 35;
        canvas.drawCircle(
          Offset(tx, ty),
          r * (0.6 - t * 0.12),
          Paint()
            ..color = sparkColor.withValues(alpha: alpha * (0.4 - t * 0.1)),
        );
      }

      // Main spark
      canvas.drawCircle(Offset(x, y), r, Paint()..color = sparkColor);

      // Spark glow
      canvas.drawCircle(
        Offset(x, y),
        r * 4,
        Paint()
          ..color = _C.sparkGlow.withValues(alpha: alpha * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // ── Central flash bloom ──────────────────────────────────
    if (p > 0.05 && p < 0.65) {
      final flashP = (p - 0.05) / 0.6;
      final flashAlpha = math.sin(flashP * math.pi) * 0.35;

      canvas.drawCircle(
        origin,
        15 + flashP * 10,
        Paint()
          ..color = Colors.white.withValues(alpha: flashAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        origin,
        30 + flashP * 20,
        Paint()
          ..color = primaryColor.withValues(alpha: flashAlpha * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
      );
    }

    // ── Electric arc line (jagged) ───────────────────────────
    if (p > 0.1 && p < 0.8) {
      final arcP = _c((p - 0.1) / 0.7);
      final arcAlpha = math.sin(arcP * math.pi) * 0.7;

      final path = Path()..moveTo(origin.dx, origin.dy);
      final arcRng = math.Random((p * 50).toInt());
      var px = origin.dx;
      var py = origin.dy;
      for (var seg = 0; seg < 6; seg++) {
        final dx = (arcRng.nextDouble() - 0.5) * 25;
        final dy = -8 - arcRng.nextDouble() * 12;
        px += dx;
        py += dy;
        path.lineTo(px, py);
      }

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.white.withValues(alpha: arcAlpha * 0.6)
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..color = primaryColor.withValues(alpha: arcAlpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  // ===================================================================
  //  LED DIAGNOSTICS (scan → blink → solid green)
  // ===================================================================
  void _drawLed(Canvas canvas, double cx, double cy, Size size) {
    final p = _ph(_p3End, _p4End);
    final acY = cy * 0.55;
    final ledPos = Offset(cx + size.width * 0.14, acY - 6);

    double ledAlpha;
    Color ledColor;

    if (p < 0.3) {
      ledAlpha = (math.sin(p * 40) * 0.5 + 0.5).clamp(0.0, 1.0);
      ledColor = _C.vestAmber;
    } else if (p < 0.7) {
      ledAlpha = (math.sin(p * 30) * 0.5 + 0.5).clamp(0.0, 1.0);
      ledColor = Color.lerp(_C.ledOrange, _C.ledGreen, _c((p - 0.3) / 0.4))!;
    } else {
      ledAlpha = 1.0;
      ledColor = _C.ledGreen;
    }

    canvas.drawCircle(
      ledPos,
      10,
      Paint()
        ..color = ledColor.withValues(alpha: ledAlpha * 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      ledPos,
      5,
      Paint()
        ..color = ledColor.withValues(alpha: ledAlpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      ledPos,
      3.5,
      Paint()..color = ledColor.withValues(alpha: ledAlpha),
    );
    canvas.drawCircle(
      Offset(ledPos.dx - 1, ledPos.dy - 1),
      1.2,
      Paint()..color = Colors.white.withValues(alpha: ledAlpha * 0.5),
    );
  }

  // ===================================================================
  //  COOL AIR — layered wave fronts + tumbling snowflakes + frost creep
  // ===================================================================
  void _drawCoolAir(Canvas canvas, Size size, double cx, double cy) {
    final p = _ph(_p4End, _p5End);
    if (p == 0) return;

    final origin = Offset(cx, cy * 0.66);

    // ── Layered expanding wave fronts ────────────────────────
    for (var w = 0; w < 7; w++) {
      final delay = w * 0.09;
      final wP = _c((p - delay) / 0.45);
      if (wP <= 0) continue;

      final radius = 18.0 + wP * size.width * 0.32;
      final alpha = (1.0 - wP) * 0.20;
      final thickness = 3.0 - wP * 2.0;

      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(origin.dx, origin.dy + wP * 35),
          width: radius * 2,
          height: radius * 1.0,
        ),
        0.05,
        math.pi - 0.1,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness.clamp(0.5, 3.0)
          ..color = accentColor.withValues(alpha: alpha),
      );

      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(origin.dx, origin.dy + wP * 35),
          width: radius * 2,
          height: radius * 1.0,
        ),
        0.05,
        math.pi - 0.1,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (thickness * 3).clamp(1.0, 9.0)
          ..color = accentColor.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // ── Tumbling 6-arm snowflakes ────────────────────────────
    final frostRng = math.Random(7777);
    for (var i = 0; i < 40; i++) {
      final delay = frostRng.nextDouble() * 0.35;
      final particleP = _c((p - delay) / 0.55);
      if (particleP <= 0) continue;

      final angle = -math.pi * 0.08 + frostRng.nextDouble() * (math.pi * 1.16);
      final speed = 35.0 + frostRng.nextDouble() * 100.0;
      final drift = (frostRng.nextDouble() - 0.5) * 35 * particleP;
      final tumble = particleP * (3 + frostRng.nextDouble() * 4) * math.pi;

      final x = origin.dx + math.cos(angle) * speed * particleP + drift;
      final y =
          origin.dy +
          math.sin(angle) * speed * particleP * 0.55 +
          particleP * 45;

      final alpha = ((1.0 - particleP) * 0.7).clamp(0.0, 0.7);
      final r = 1.8 + frostRng.nextDouble() * 3.0;

      final sColor = Color.lerp(
        Colors.white,
        accentColor,
        0.25 + frostRng.nextDouble() * 0.35,
      )!.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(tumble);

      final armPaint = Paint()
        ..color = sColor
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;

      for (var arm = 0; arm < 6; arm++) {
        final a = arm * math.pi / 3;
        final endX = math.cos(a) * r;
        final endY = math.sin(a) * r;
        canvas.drawLine(Offset.zero, Offset(endX, endY), armPaint);

        // Branch at 60% of arm length
        if (r > 2.0) {
          final bx = endX * 0.6;
          final by = endY * 0.6;
          final branchLen = r * 0.35;
          final ba1 = a + math.pi / 6;
          final ba2 = a - math.pi / 6;
          canvas.drawLine(
            Offset(bx, by),
            Offset(
              bx + math.cos(ba1) * branchLen,
              by + math.sin(ba1) * branchLen,
            ),
            armPaint,
          );
          canvas.drawLine(
            Offset(bx, by),
            Offset(
              bx + math.cos(ba2) * branchLen,
              by + math.sin(ba2) * branchLen,
            ),
            armPaint,
          );
        }
      }

      canvas.drawCircle(Offset.zero, r * 0.25, Paint()..color = sColor);
      canvas.restore();

      canvas.drawCircle(
        Offset(x, y),
        r * 3.5,
        Paint()
          ..color = accentColor.withValues(alpha: alpha * 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // ── Frost crystallisation creep on AC unit edges ─────────
    if (p > 0.3) {
      final frostP = _c((p - 0.3) / 0.7);
      final acY = cy * 0.55;
      final acW = size.width * 0.40;
      final acH = size.height * 0.12;

      final frostRng2 = math.Random(3333);
      for (var i = 0; i < 20; i++) {
        final fx = cx - acW * 0.45 + i * (acW * 0.9 / 20);
        final frostLen = (4 + frostRng2.nextDouble() * 12) * frostP;
        final fy = acY + acH * 0.5;

        final frostPath = Path()..moveTo(fx, fy);
        var currentY = fy;
        for (var seg = 0; seg < 3; seg++) {
          final dx = (frostRng2.nextDouble() - 0.5) * 4;
          currentY += frostLen / 3;
          frostPath.lineTo(fx + dx, currentY);
        }

        canvas.drawPath(
          frostPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..color = accentColor.withValues(alpha: 0.3 * frostP)
            ..strokeCap = StrokeCap.round,
        );
      }

      // Frost glaze on AC body
      canvas.save();
      canvas.translate(cx, acY);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: acW, height: acH),
          const Radius.circular(10),
        ),
        Paint()..color = accentColor.withValues(alpha: 0.06 * frostP),
      );
      canvas.restore();
    }

    // ── Temperature gradient overlay ─────────────────────────
    if (p > 0.4) {
      final tintP = _c((p - 0.4) / 0.6);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, size.height * 0.3),
            Offset(0, size.height),
            [Colors.transparent, accentColor.withValues(alpha: 0.04 * tintP)],
          ),
      );
    }
  }

  // ===================================================================
  //  PHASE 6: AMBIENT SETTLE — final room glow + gentle drift
  // ===================================================================
  void _drawAmbientSettle(Canvas canvas, Size size, double cx, double cy) {
    final p = _ph(_p5End, 1.0);
    if (p == 0) return;

    // Soft room-wide glow centred on AC unit
    canvas.drawCircle(
      Offset(cx, cy * 0.6),
      size.width * 0.4,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.04 * p)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    // Gentle drifting mist particles
    final rng = math.Random(11111);
    for (var i = 0; i < 15; i++) {
      final baseX = cx + (rng.nextDouble() - 0.5) * size.width * 0.6;
      final baseY = cy * 0.6 + rng.nextDouble() * size.height * 0.3;
      final drift = math.sin(progress * 3 + i) * 8;

      canvas.drawCircle(
        Offset(baseX + drift, baseY - p * 15),
        1.2 + rng.nextDouble() * 1.5,
        Paint()
          ..color = accentColor.withValues(
            alpha: 0.12 * p * (1 - rng.nextDouble() * 0.4),
          ),
      );
    }

    // Final subtle vignette tighten
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy * 0.7),
          size.longestSide * 0.45,
          [Colors.transparent, Colors.black.withValues(alpha: 0.15 * p)],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant AcSplashPainter old) => old.progress != progress;
}
