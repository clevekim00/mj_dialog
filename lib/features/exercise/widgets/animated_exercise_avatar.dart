import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedExerciseAvatar extends StatelessWidget {
  const AnimatedExerciseAvatar({
    super.key,
    required this.pulse,
    required this.stepId,
    this.shape,
    this.accentColor = Colors.pinkAccent,
    this.showChrome = true,
  });

  final double pulse;
  final String stepId;
  final String? shape;
  final Color accentColor;
  final bool showChrome;

  @override
  Widget build(BuildContext context) {
    final spec = _ExerciseVisualSpec.from(stepId: stepId, shape: shape);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF101925), Color(0xFF263748), Color(0xFF172434)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 420;
            return Stack(
              children: [
                Positioned.fill(
                  child: _ReferenceTutorBackdrop(
                    pulse: pulse,
                    stepId: stepId,
                    shape: shape,
                    accentColor: accentColor,
                    fallback: _FallbackTutorScene(
                      pulse: pulse,
                      stepId: stepId,
                      shape: shape,
                      accentColor: accentColor,
                      compact: compact,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: _CurrentStepCard(
                    spec: spec,
                    accentColor: accentColor,
                    compact: compact,
                  ),
                ),
                if (showChrome)
                  Positioned(
                    right: 14,
                    top: 14,
                    bottom: compact ? 88 : 76,
                    width: compact ? constraints.maxWidth * 0.34 : 150,
                    child: _GuidePanel(compact: compact, activeId: stepId),
                  ),
                Positioned(
                  left: 18,
                  right: showChrome && !compact ? 178 : 18,
                  bottom: 58,
                  child: _SubtitleBar(text: spec.subtitle),
                ),
                if (showChrome)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: _TimelineStrip(
                      activeId: stepId,
                      activeShape: shape,
                      accentColor: accentColor,
                      compact: compact,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReferenceTutorBackdrop extends StatelessWidget {
  const _ReferenceTutorBackdrop({
    required this.pulse,
    required this.stepId,
    required this.shape,
    required this.accentColor,
    required this.fallback,
  });

  final double pulse;
  final String stepId;
  final String? shape;
  final Color accentColor;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final breath = math.sin(pulse * math.pi * 2) * 2;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF172230), Color(0xFF2E3E4C)],
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, breath),
          child: Transform.scale(
            scale: 0.96,
            child: Image.asset(
              'assets/images/ai_speech_2d_tutor.png',
              fit: BoxFit.contain,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.06),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.22),
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: _TutorMouthOverlayPainter(
            pulse: pulse,
            stepId: stepId,
            shape: shape,
            accentColor: accentColor,
          ),
        ),
      ],
    );
  }
}

class _FallbackTutorScene extends StatelessWidget {
  const _FallbackTutorScene({
    required this.pulse,
    required this.stepId,
    required this.shape,
    required this.accentColor,
    required this.compact,
  });

  final double pulse;
  final String stepId;
  final String? shape;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TherapistScenePainter(
        pulse: pulse,
        stepId: stepId,
        shape: shape,
        accentColor: accentColor,
        compact: compact,
      ),
    );
  }
}

class _TutorMouthOverlayPainter extends CustomPainter {
  const _TutorMouthOverlayPainter({
    required this.pulse,
    required this.stepId,
    required this.shape,
    required this.accentColor,
  });

  final double pulse;
  final String stepId;
  final String? shape;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (!_isTongueStep(stepId)) return;

    final eased = Curves.easeInOut.transform(pulse);
    final swing = math.sin(pulse * math.pi * 2);
    final morph = _AvatarMorph.from(
      stepId: stepId,
      shape: shape,
      eased: eased,
      swing: swing,
    );
    final scale = math.min(size.width, size.height) / 420;
    final mouthCenter = Offset(size.width * 0.49, size.height * 0.56);

    if (morph.cheekPuff > 0) {
      final side = morph.cheekSide == 0 ? 1.0 : morph.cheekSide;
      canvas.drawCircle(
        mouthCenter.translate(side * 72 * scale, -10 * scale),
        (18 + morph.cheekPuff * 12) * scale,
        Paint()..color = accentColor.withValues(alpha: 0.18),
      );
    }

    final open = morph.open.clamp(0.0, 1.0);
    final isRestingMouth = stepId == 'tongue_ready' || stepId == 'rest';
    final mouthWidth = (42 + morph.wide * 12 - morph.round * 8) * scale;
    final mouthHeight = (4 + open * 30 + morph.round * 4) * scale;

    if (isRestingMouth || open < 0.16) {
      final lipLine = Path()
        ..moveTo(mouthCenter.dx - 18 * scale, mouthCenter.dy)
        ..quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy + 4 * scale,
          mouthCenter.dx + 18 * scale,
          mouthCenter.dy,
        );
      canvas.drawPath(
        lipLine,
        Paint()
          ..color = const Color(0xFFD96A80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * scale
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final outerLip = Path()
      ..moveTo(mouthCenter.dx - mouthWidth * 0.54, mouthCenter.dy)
      ..cubicTo(
        mouthCenter.dx - mouthWidth * 0.34,
        mouthCenter.dy - mouthHeight * 0.58,
        mouthCenter.dx + mouthWidth * 0.34,
        mouthCenter.dy - mouthHeight * 0.58,
        mouthCenter.dx + mouthWidth * 0.54,
        mouthCenter.dy,
      )
      ..cubicTo(
        mouthCenter.dx + mouthWidth * 0.33,
        mouthCenter.dy + mouthHeight * 0.62,
        mouthCenter.dx - mouthWidth * 0.33,
        mouthCenter.dy + mouthHeight * 0.62,
        mouthCenter.dx - mouthWidth * 0.54,
        mouthCenter.dy,
      )
      ..close();
    canvas.drawPath(
      outerLip,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF08BA0), Color(0xFFD95D76)],
        ).createShader(outerLip.getBounds()),
    );

    final innerMouth = Path()
      ..moveTo(mouthCenter.dx - mouthWidth * 0.42, mouthCenter.dy + 1 * scale)
      ..cubicTo(
        mouthCenter.dx - mouthWidth * 0.25,
        mouthCenter.dy - mouthHeight * 0.38,
        mouthCenter.dx + mouthWidth * 0.25,
        mouthCenter.dy - mouthHeight * 0.38,
        mouthCenter.dx + mouthWidth * 0.42,
        mouthCenter.dy + 1 * scale,
      )
      ..cubicTo(
        mouthCenter.dx + mouthWidth * 0.23,
        mouthCenter.dy + mouthHeight * 0.38,
        mouthCenter.dx - mouthWidth * 0.23,
        mouthCenter.dy + mouthHeight * 0.38,
        mouthCenter.dx - mouthWidth * 0.42,
        mouthCenter.dy + 1 * scale,
      )
      ..close();
    canvas.drawPath(
      innerMouth,
      Paint()..color = const Color(0xFF3A121C).withValues(alpha: 0.9),
    );

    if (open > 0.32) {
      final teeth = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: mouthCenter.translate(0, -mouthHeight * 0.26),
          width: mouthWidth * 0.42,
          height: 5 * scale,
        ),
        Radius.circular(3 * scale),
      );
      canvas.drawRRect(teeth, Paint()..color = const Color(0xFFFFF7F1));
    }

    final tongueVisible = morph.tongueOut > 0.04 || open > 0.22;
    if (!tongueVisible) return;

    final tongueCenter = mouthCenter.translate(
      (morph.tongueShift + morph.tongueCircleX) * 22 * scale,
      mouthHeight * 0.18 +
          morph.tongueOut * 13 * scale -
          (morph.tongueLift + morph.tongueCircleY) * 16 * scale,
    );
    final tongueWidth = (18 + morph.tongueOut * 30) * scale;
    final tongueHeight = (8 + morph.tongueOut * 17) * scale;
    final tonguePath = Path()
      ..moveTo(tongueCenter.dx - tongueWidth * 0.5, tongueCenter.dy)
      ..cubicTo(
        tongueCenter.dx - tongueWidth * 0.36,
        tongueCenter.dy - tongueHeight * 0.48,
        tongueCenter.dx + tongueWidth * 0.36,
        tongueCenter.dy - tongueHeight * 0.48,
        tongueCenter.dx + tongueWidth * 0.5,
        tongueCenter.dy,
      )
      ..cubicTo(
        tongueCenter.dx + tongueWidth * 0.42,
        tongueCenter.dy + tongueHeight * 0.58,
        tongueCenter.dx - tongueWidth * 0.42,
        tongueCenter.dy + tongueHeight * 0.58,
        tongueCenter.dx - tongueWidth * 0.5,
        tongueCenter.dy,
      )
      ..close();
    canvas.drawPath(
      tonguePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFA9B4), Color(0xFFE66D83)],
        ).createShader(tonguePath.getBounds()),
    );
    canvas.drawPath(
      tonguePath,
      Paint()
        ..color = const Color(0xFFB94B61).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale,
    );
    canvas.drawLine(
      tongueCenter.translate(0, -tongueHeight * 0.22),
      tongueCenter.translate(0, tongueHeight * 0.26),
      Paint()
        ..color = const Color(0xFFC9586C).withValues(alpha: 0.5)
        ..strokeWidth = 1.2 * scale
        ..strokeCap = StrokeCap.round,
    );

    if (stepId == 'tongue_circle') {
      final circleRect = Rect.fromCenter(
        center: mouthCenter.translate(0, 1 * scale),
        width: mouthWidth * 1.18,
        height: mouthHeight * 1.18,
      );
      canvas.drawArc(
        circleRect,
        -math.pi * 0.35,
        math.pi * 1.65,
        false,
        Paint()
          ..color = accentColor.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TutorMouthOverlayPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.stepId != stepId ||
        oldDelegate.shape != shape ||
        oldDelegate.accentColor != accentColor;
  }
}

class _CurrentStepCard extends StatelessWidget {
  const _CurrentStepCard({
    required this.spec,
    required this.accentColor,
    required this.compact,
  });

  final _ExerciseVisualSpec spec;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 116 : 148,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            spec.eyebrow,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            spec.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 24 : 30,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spec.tip,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: compact ? 44 : 52,
            height: compact ? 44 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 4),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            alignment: Alignment.center,
            child: Text(
              spec.timerHint,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidePanel extends StatelessWidget {
  const _GuidePanel({required this.compact, required this.activeId});

  final bool compact;
  final String activeId;

  @override
  Widget build(BuildContext context) {
    final isTongueGuide = _isTongueStep(activeId);
    final expressions = const ['기본', '미소', '집중'];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF203040).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTongueGuide ? '혀운동 가이드' : '입모양 가이드',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 5,
              child: isTongueGuide
                  ? _TongueGuideImageFallback(
                      compact: compact,
                      activeId: activeId,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/ai_speech_mouth_guide.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) =>
                            _MouthGuideImageFallback(compact: compact),
                      ),
                    ),
            ),
            if (!compact && isTongueGuide) ...[
              const SizedBox(height: 10),
              Text(
                '구강운동 예시',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 2,
                child: Row(
                  children: const [
                    Expanded(child: _ExpressionChip(label: '천천히')),
                    SizedBox(width: 4),
                    Expanded(child: _ExpressionChip(label: '정확히')),
                    SizedBox(width: 4),
                    Expanded(child: _ExpressionChip(label: '편안히')),
                  ],
                ),
              ),
            ],
            if (!compact && !isTongueGuide) ...[
              const SizedBox(height: 10),
              Text(
                '표정',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    for (final label in expressions)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _ExpressionChip(label: label),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MouthGuideImageFallback extends StatelessWidget {
  const _MouthGuideImageFallback({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mouthItems = const [
      _GuideMouth('아', 'a', _MouthPreviewShape.open),
      _GuideMouth('이', 'i', _MouthPreviewShape.wide),
      _GuideMouth('우', 'u', _MouthPreviewShape.round),
      _GuideMouth('파', 'pa', _MouthPreviewShape.closed),
      _GuideMouth('타', 'ta', _MouthPreviewShape.smile),
      _GuideMouth('카', 'ka', _MouthPreviewShape.openSmall),
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: compact ? 0.86 : 0.92,
      children: [
        for (final item in mouthItems)
          _MouthGuideTile(item: item, compact: compact),
      ],
    );
  }
}

class _TongueGuideImageFallback extends StatelessWidget {
  const _TongueGuideImageFallback({
    required this.compact,
    required this.activeId,
  });

  final bool compact;
  final String activeId;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _TongueGuide('준비', 'tongue_ready', _TonguePreviewShape.ready),
      _TongueGuide('내밀기', 'tongue_out', _TonguePreviewShape.out),
      _TongueGuide('넣기', 'tongue_in', _TonguePreviewShape.inward),
      _TongueGuide('왼쪽', 'tongue_left', _TonguePreviewShape.left),
      _TongueGuide('오른쪽', 'tongue_right', _TonguePreviewShape.right),
      _TongueGuide('위로', 'tongue_up', _TonguePreviewShape.up),
      _TongueGuide('아래', 'tongue_down', _TonguePreviewShape.down),
      _TongueGuide('원', 'tongue_circle', _TonguePreviewShape.circle),
      _TongueGuide('볼 L', 'cheek_left', _TonguePreviewShape.cheekLeft),
      _TongueGuide('볼 R', 'cheek_right', _TonguePreviewShape.cheekRight),
      _TongueGuide('혀끝', 'tongue_tip_up', _TonguePreviewShape.tipUp),
      _TongueGuide('휴식', 'rest', _TonguePreviewShape.rest),
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: compact ? 0.92 : 1.05,
      children: [
        for (final item in items)
          _TongueGuideTile(
            item: item,
            selected: item.id == activeId,
            compact: compact,
          ),
      ],
    );
  }
}

class _TongueGuideTile extends StatelessWidget {
  const _TongueGuideTile({
    required this.item,
    required this.selected,
    required this.compact,
  });

  final _TongueGuide item;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selected
              ? Colors.tealAccent.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _MiniTonguePainter(shape: item.shape),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MouthGuideTile extends StatelessWidget {
  const _MouthGuideTile({required this.item, required this.compact});

  final _GuideMouth item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _MiniMouthPainter(shape: item.shape),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${item.ko} (${item.roman})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpressionChip extends StatelessWidget {
  const _ExpressionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SubtitleBar extends StatelessWidget {
  const _SubtitleBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimelineStrip extends StatelessWidget {
  const _TimelineStrip({
    required this.activeId,
    required this.activeShape,
    required this.accentColor,
    required this.compact,
  });

  final String activeId;
  final String? activeShape;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (_isTongueStep(activeId)) {
      final tongueItems = const [
        _GuideMouth('준비', '호흡', _MouthPreviewShape.closed),
        _GuideMouth('내밀기', '혀', _MouthPreviewShape.open),
        _GuideMouth('넣기', '혀', _MouthPreviewShape.closed),
        _GuideMouth('왼쪽', '혀', _MouthPreviewShape.openSmall),
        _GuideMouth('오른쪽', '혀', _MouthPreviewShape.openSmall),
        _GuideMouth('위', '혀', _MouthPreviewShape.open),
        _GuideMouth('아래', '혀', _MouthPreviewShape.open),
        _GuideMouth('원', '혀', _MouthPreviewShape.round),
        _GuideMouth('볼L', '혀', _MouthPreviewShape.closed),
        _GuideMouth('볼R', '혀', _MouthPreviewShape.closed),
        _GuideMouth('혀끝', '혀', _MouthPreviewShape.openSmall),
        _GuideMouth('휴식', '쉼', _MouthPreviewShape.smile),
      ];
      final ids = const [
        'tongue_ready',
        'tongue_out',
        'tongue_in',
        'tongue_left',
        'tongue_right',
        'tongue_up',
        'tongue_down',
        'tongue_circle',
        'cheek_left',
        'cheek_right',
        'tongue_tip_up',
        'rest',
      ];

      return _TimelineContainer(
        compact: compact,
        children: [
          for (var i = 0; i < tongueItems.length; i++)
            Expanded(
              child: _TimelineItem(
                item: tongueItems[i],
                selected: ids[i] == activeId,
                index: i + 1,
                accentColor: accentColor,
                compact: compact,
              ),
            ),
        ],
      );
    }

    final items = const [
      _GuideMouth('준비', '호흡', _MouthPreviewShape.closed),
      _GuideMouth('아', 'a', _MouthPreviewShape.open),
      _GuideMouth('이', 'i', _MouthPreviewShape.wide),
      _GuideMouth('우', 'u', _MouthPreviewShape.round),
      _GuideMouth('파', 'pa', _MouthPreviewShape.closed),
      _GuideMouth('타', 'ta', _MouthPreviewShape.smile),
      _GuideMouth('카', 'ka', _MouthPreviewShape.openSmall),
    ];

    return _TimelineContainer(
      compact: compact,
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: _TimelineItem(
              item: items[i],
              selected: _isTimelineActive(items[i]),
              index: i + 1,
              accentColor: accentColor,
              compact: compact,
            ),
          ),
      ],
    );
  }

  bool _isTimelineActive(_GuideMouth item) {
    if (activeShape == 'open' && item.ko == '아') return true;
    if (activeShape == 'wideSmile' && item.ko == '이') return true;
    if (activeShape == 'round' && item.ko == '우') return true;
    if (activeId.contains('pataka') && item.ko == '파') return true;
    if (activeId.contains('lalala') && item.ko == '타') return true;
    if (activeId.contains('relax') && item.ko == '준비') return true;
    if (activeId.contains('open') && item.ko == '아') return true;
    if (activeId.contains('smile') && item.ko == '이') return true;
    if (activeId.contains('pucker') && item.ko == '우') return true;
    if (activeId.contains('round') && item.ko == '우') return true;
    if (activeId.contains('breath') && item.ko == '준비') return true;
    return false;
  }
}

class _TimelineContainer extends StatelessWidget {
  const _TimelineContainer({required this.compact, required this.children});

  final bool compact;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 44 : 54,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2B39).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(children: children),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.item,
    required this.selected,
    required this.index,
    required this.accentColor,
    required this.compact,
  });

  final _GuideMouth item;
  final bool selected;
  final int index;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: accentColor, width: 1.4) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 16 : 20,
            height: compact ? 16 : 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? accentColor
                  : Colors.white.withValues(alpha: 0.18),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 3),
            Text(
              item.ko,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TherapistScenePainter extends CustomPainter {
  const _TherapistScenePainter({
    required this.pulse,
    required this.stepId,
    required this.shape,
    required this.accentColor,
    required this.compact,
  });

  final double pulse;
  final String stepId;
  final String? shape;
  final Color accentColor;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    _drawClinicRoom(canvas, size);

    final eased = Curves.easeInOut.transform(pulse);
    final swing = math.sin(pulse * math.pi * 2);
    final morph = _AvatarMorph.from(
      stepId: stepId,
      shape: shape,
      eased: eased,
      swing: swing,
    );
    final scale = math.min(size.width, size.height) / 420;
    final center = Offset(
      compact ? size.width * 0.42 : size.width * 0.36,
      size.height * 0.55 + morph.breathLift * 4 * scale,
    );

    _drawHair(canvas, center, scale, swing);
    _drawNeckShoulders(canvas, center, scale, morph);
    _drawFace(canvas, center, scale, morph);
    _drawEyes(canvas, center, scale, morph);
    _drawMouth(canvas, center, scale, morph);
    _drawSoftLight(canvas, size);
  }

  void _drawClinicRoom(Canvas canvas, Size size) {
    final bgRect = Offset.zero & size;
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF172535), Color(0xFF2F4354)],
        ).createShader(bgRect),
    );

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.74),
      58,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFFFDFA7).withValues(alpha: 0.36),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.18, size.height * 0.74),
                radius: 90,
              ),
            ),
    );

    final poster = Rect.fromLTWH(
      size.width * 0.58,
      size.height * 0.16,
      size.width * 0.13,
      size.height * 0.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(poster, const Radius.circular(7)),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.drawLine(
      poster.centerLeft.translate(12, 0),
      poster.centerRight.translate(-12, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 3,
    );
  }

  void _drawSoftLight(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.22),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawHair(Canvas canvas, Offset center, double scale, double swing) {
    final hairShaderRect = Rect.fromCenter(
      center: center,
      width: 310 * scale,
      height: 390 * scale,
    );
    final hairPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D1514), Color(0xFF33211D), Color(0xFF754836)],
      ).createShader(hairShaderRect);

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -86 * scale),
        width: 175 * scale,
        height: 202 * scale,
      ),
      hairPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(96 * scale + swing * 5 * scale, -40 * scale),
        width: 64 * scale,
        height: 252 * scale,
      ),
      hairPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 62 * scale, center.dy - 156 * scale)
        ..quadraticBezierTo(
          center.dx - 132 * scale,
          center.dy - 80 * scale,
          center.dx - 78 * scale,
          center.dy + 108 * scale,
        )
        ..quadraticBezierTo(
          center.dx - 52 * scale,
          center.dy - 6 * scale,
          center.dx - 12 * scale,
          center.dy - 154 * scale,
        )
        ..close(),
      hairPaint,
    );

    final strandPaint = Paint()
      ..color = const Color(0xFFB37A58).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final offset = (i - 4) * 9 * scale;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx + offset, center.dy - 170 * scale)
          ..quadraticBezierTo(
            center.dx + offset * 0.4 + swing * 2 * scale,
            center.dy - 92 * scale,
            center.dx + offset * 0.7,
            center.dy - 18 * scale,
          ),
        strandPaint,
      );
    }
  }

  void _drawNeckShoulders(
    Canvas canvas,
    Offset center,
    double scale,
    _AvatarMorph morph,
  ) {
    final skin = Paint()..color = const Color(0xFFFFD4C5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, 78 * scale),
          width: 55 * scale,
          height: 76 * scale,
        ),
        Radius.circular(16 * scale),
      ),
      skin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 126 * scale, center.dy + 184 * scale)
        ..quadraticBezierTo(
          center.dx,
          center.dy + 118 * scale,
          center.dx + 128 * scale,
          center.dy + 184 * scale,
        )
        ..lineTo(center.dx + 150 * scale, center.dy + 250 * scale)
        ..lineTo(center.dx - 150 * scale, center.dy + 250 * scale)
        ..close(),
      Paint()..color = const Color(0xFFEAF0F7),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 28 * scale, center.dy + 116 * scale)
        ..lineTo(center.dx, center.dy + 152 * scale)
        ..lineTo(center.dx + 28 * scale, center.dy + 116 * scale),
      Paint()
        ..color = const Color(0xFF273D58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFace(
    Canvas canvas,
    Offset center,
    double scale,
    _AvatarMorph morph,
  ) {
    final faceCenter = center.translate(
      morph.jawShift * 5 * scale,
      -52 * scale,
    );
    final facePath = Path()
      ..moveTo(faceCenter.dx - 60 * scale, faceCenter.dy - 74 * scale)
      ..quadraticBezierTo(
        faceCenter.dx - 78 * scale,
        faceCenter.dy - 8 * scale,
        faceCenter.dx - 42 * scale,
        faceCenter.dy + 62 * scale,
      )
      ..quadraticBezierTo(
        faceCenter.dx,
        faceCenter.dy + 94 * scale + morph.open * 4 * scale,
        faceCenter.dx + 42 * scale,
        faceCenter.dy + 62 * scale,
      )
      ..quadraticBezierTo(
        faceCenter.dx + 78 * scale,
        faceCenter.dy - 8 * scale,
        faceCenter.dx + 60 * scale,
        faceCenter.dy - 74 * scale,
      )
      ..quadraticBezierTo(
        faceCenter.dx,
        faceCenter.dy - 112 * scale,
        faceCenter.dx - 60 * scale,
        faceCenter.dy - 74 * scale,
      )
      ..close();
    canvas.drawPath(
      facePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE4D8), Color(0xFFFFCABB)],
        ).createShader(facePath.getBounds()),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: faceCenter.translate(-36 * scale, 20 * scale),
        width: 26 * scale,
        height: 14 * scale,
      ),
      Paint()..color = const Color(0x55FF91A4),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: faceCenter.translate(36 * scale, 20 * scale),
        width: 26 * scale,
        height: 14 * scale,
      ),
      Paint()..color = const Color(0x55FF91A4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(faceCenter.dx, faceCenter.dy - 6 * scale)
        ..lineTo(faceCenter.dx - 6 * scale, faceCenter.dy + 19 * scale)
        ..quadraticBezierTo(
          faceCenter.dx,
          faceCenter.dy + 24 * scale,
          faceCenter.dx + 6 * scale,
          faceCenter.dy + 19 * scale,
        ),
      Paint()
        ..color = const Color(0xFFE0A392)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawEyes(
    Canvas canvas,
    Offset center,
    double scale,
    _AvatarMorph morph,
  ) {
    final faceCenter = center.translate(
      morph.jawShift * 5 * scale,
      -52 * scale,
    );
    final blink = morph.blink;
    for (final side in [-1, 1]) {
      final eyeCenter = faceCenter.translate(side * 30 * scale, -24 * scale);
      canvas.drawOval(
        Rect.fromCenter(
          center: eyeCenter,
          width: 30 * scale,
          height: math.max(3, 22 * (1 - blink)) * scale,
        ),
        Paint()..color = const Color(0xFF251817),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: eyeCenter.translate(side * 1.5 * scale, 0),
          width: 19 * scale,
          height: math.max(2, 15 * (1 - blink)) * scale,
        ),
        Paint()..color = const Color(0xFF8A5B47),
      );
      canvas.drawCircle(
        eyeCenter.translate(side * 5 * scale, -5 * scale),
        3.5 * scale * (1 - blink),
        Paint()..color = Colors.white,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: eyeCenter.translate(0, -17 * scale),
          width: 36 * scale,
          height: 11 * scale,
        ),
        side == -1 ? math.pi * 1.08 : math.pi * 1.02,
        math.pi * 0.75,
        false,
        Paint()
          ..color = const Color(0xFF211514)
          ..strokeWidth = 3 * scale
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawMouth(
    Canvas canvas,
    Offset center,
    double scale,
    _AvatarMorph morph,
  ) {
    final faceCenter = center.translate(
      morph.jawShift * 5 * scale,
      -52 * scale,
    );
    final mouthCenter = faceCenter.translate(
      morph.jawShift * 14 * scale,
      48 * scale,
    );
    final mouthWidth = math.max(
      18 * scale,
      (37 + morph.wide * 34 - morph.round * 16) * scale,
    );
    final mouthHeight = math.max(
      4 * scale,
      (7 + morph.open * 42 + morph.round * 10 - morph.press * 4) * scale,
    );
    final mouthRect = Rect.fromCenter(
      center: mouthCenter,
      width: mouthWidth,
      height: mouthHeight,
    );
    canvas.drawOval(
      mouthRect.inflate(3 * scale),
      Paint()..color = const Color(0xFFC95B70),
    );
    canvas.drawOval(mouthRect, Paint()..color = const Color(0xFF2A1018));
    if (morph.open > 0.26) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: mouthCenter.translate(0, -mouthHeight * 0.24),
            width: mouthWidth * 0.55,
            height: 6 * scale,
          ),
          Radius.circular(3 * scale),
        ),
        Paint()..color = const Color(0xFFFFF8F0),
      );
    }
    if (morph.tongueOut > 0.05 || morph.open > 0.34) {
      canvas.drawOval(
        Rect.fromCenter(
          center: mouthCenter.translate(
            (morph.tongueShift + morph.tongueCircleX) * 16 * scale,
            mouthHeight * 0.18 +
                morph.tongueOut * 16 * scale -
                (morph.tongueLift + morph.tongueCircleY) * 13 * scale,
          ),
          width: (22 + morph.tongueOut * 18) * scale,
          height: (10 + morph.tongueOut * 18) * scale,
        ),
        Paint()..color = const Color(0xFFF48A95),
      );
    }
    if (morph.cheekPuff > 0) {
      final side = morph.cheekSide == 0 ? 1.0 : morph.cheekSide;
      canvas.drawOval(
        Rect.fromCenter(
          center: faceCenter.translate(side * 48 * scale, 24 * scale),
          width: (22 + morph.cheekPuff * 14) * scale,
          height: (14 + morph.cheekPuff * 10) * scale,
        ),
        Paint()..color = const Color(0x66FF91A4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TherapistScenePainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.stepId != stepId ||
        oldDelegate.shape != shape ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.compact != compact;
  }
}

class _MiniMouthPainter extends CustomPainter {
  const _MiniMouthPainter({required this.shape});

  final _MouthPreviewShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final scale = math.min(size.width, size.height) / 68;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -4 * scale),
        width: 42 * scale,
        height: 44 * scale,
      ),
      Paint()..color = const Color(0xFFFFD2C2),
    );
    final mouth = switch (shape) {
      _MouthPreviewShape.open => (w: 25.0, h: 24.0, round: 0.0),
      _MouthPreviewShape.openSmall => (w: 22.0, h: 17.0, round: 0.0),
      _MouthPreviewShape.wide => (w: 31.0, h: 8.0, round: 0.0),
      _MouthPreviewShape.round => (w: 16.0, h: 17.0, round: 1.0),
      _MouthPreviewShape.closed => (w: 24.0, h: 5.0, round: 0.0),
      _MouthPreviewShape.smile => (w: 29.0, h: 9.0, round: 0.0),
    };
    final rect = Rect.fromCenter(
      center: center.translate(0, 10 * scale),
      width: mouth.w * scale,
      height: mouth.h * scale,
    );
    canvas.drawOval(
      rect.inflate(2 * scale),
      Paint()..color = const Color(0xFFC95B70),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = shape == _MouthPreviewShape.closed
            ? const Color(0xFFC95B70)
            : const Color(0xFF2A1018),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniMouthPainter oldDelegate) {
    return oldDelegate.shape != shape;
  }
}

class _MiniTonguePainter extends CustomPainter {
  const _MiniTonguePainter({required this.shape});

  final _TonguePreviewShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final scale = math.min(size.width, size.height) / 70;
    final facePaint = Paint()..color = const Color(0xFFFFD2C2);
    final lipPaint = Paint()..color = const Color(0xFFE17488);
    final mouthPaint = Paint()..color = const Color(0xFF2A1018);
    final tonguePaint = Paint()..color = const Color(0xFFFF8D9C);

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -4 * scale),
        width: 44 * scale,
        height: 46 * scale,
      ),
      facePaint,
    );

    final closed =
        shape == _TonguePreviewShape.ready ||
        shape == _TonguePreviewShape.inward ||
        shape == _TonguePreviewShape.cheekLeft ||
        shape == _TonguePreviewShape.cheekRight ||
        shape == _TonguePreviewShape.rest;
    final mouthRect = Rect.fromCenter(
      center: center.translate(0, 11 * scale),
      width: (closed ? 25 : 29) * scale,
      height: (closed ? 6 : 20) * scale,
    );
    canvas.drawOval(mouthRect.inflate(2 * scale), lipPaint);
    canvas.drawOval(mouthRect, closed ? lipPaint : mouthPaint);

    if (shape == _TonguePreviewShape.cheekLeft ||
        shape == _TonguePreviewShape.cheekRight) {
      final side = shape == _TonguePreviewShape.cheekLeft ? -1.0 : 1.0;
      canvas.drawCircle(
        center.translate(side * 18 * scale, 7 * scale),
        8 * scale,
        Paint()..color = const Color(0x55FF91A4),
      );
      canvas.drawCircle(
        center.translate(side * 18 * scale, 7 * scale),
        4 * scale,
        Paint()..color = const Color(0x88FF8D9C),
      );
      return;
    }

    if (closed) return;

    final tongueOffset = switch (shape) {
      _TonguePreviewShape.left => Offset(-9 * scale, 3 * scale),
      _TonguePreviewShape.right => Offset(9 * scale, 3 * scale),
      _TonguePreviewShape.up ||
      _TonguePreviewShape.tipUp => Offset(0, -5 * scale),
      _TonguePreviewShape.down => Offset(0, 10 * scale),
      _TonguePreviewShape.circle => Offset(
        math.cos(math.pi * 0.25) * 8 * scale,
        math.sin(math.pi * 0.25) * 8 * scale,
      ),
      _ => Offset(0, 8 * scale),
    };
    final tongueRect = Rect.fromCenter(
      center: center.translate(tongueOffset.dx, 13 * scale + tongueOffset.dy),
      width: (shape == _TonguePreviewShape.out ? 28 : 20) * scale,
      height: (shape == _TonguePreviewShape.out ? 20 : 12) * scale,
    );
    canvas.drawOval(tongueRect, tonguePaint);

    if (shape == _TonguePreviewShape.circle) {
      canvas.drawArc(
        Rect.fromCenter(
          center: center.translate(0, 12 * scale),
          width: 35 * scale,
          height: 31 * scale,
        ),
        -math.pi * 0.2,
        math.pi * 1.45,
        false,
        Paint()
          ..color = const Color(0xFF64EBD4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTonguePainter oldDelegate) {
    return oldDelegate.shape != shape;
  }
}

class _ExerciseVisualSpec {
  const _ExerciseVisualSpec({
    required this.eyebrow,
    required this.title,
    required this.tip,
    required this.subtitle,
    required this.timerHint,
  });

  final String eyebrow;
  final String title;
  final String tip;
  final String subtitle;
  final String timerHint;

  factory _ExerciseVisualSpec.from({
    required String stepId,
    required String? shape,
  }) {
    if (shape != null) {
      return switch (shape) {
        'open' => const _ExerciseVisualSpec(
          eyebrow: 'STEP',
          title: '아 (a)',
          tip: '턱을 자연스럽게 내리고 입을 크게 열어주세요.',
          subtitle: "입을 크게 벌리고 '아' 소리를 내는 연습입니다.",
          timerHint: '04:28',
        ),
        'wideSmile' => const _ExerciseVisualSpec(
          eyebrow: 'STEP',
          title: '이 (i)',
          tip: '입꼬리를 양옆으로 부드럽게 넓혀주세요.',
          subtitle: "입을 가로로 넓혀 '이' 소리를 연습합니다.",
          timerHint: '03:20',
        ),
        'round' => const _ExerciseVisualSpec(
          eyebrow: 'STEP',
          title: '우 (u)',
          tip: '입술을 앞으로 둥글게 모아주세요.',
          subtitle: "입술을 둥글게 모아 '우' 소리를 연습합니다.",
          timerHint: '03:12',
        ),
        'pataka' => const _ExerciseVisualSpec(
          eyebrow: 'STEP',
          title: '파타카',
          tip: '입술, 혀끝, 뒤쪽 혀를 차례대로 움직입니다.',
          subtitle: '파-타-카를 같은 속도로 또박또박 반복합니다.',
          timerHint: '04:00',
        ),
        'lala' => const _ExerciseVisualSpec(
          eyebrow: 'STEP',
          title: '라라라',
          tip: '혀끝이 위쪽을 가볍게 스치도록 움직입니다.',
          subtitle: '혀끝 움직임을 부드럽게 반복합니다.',
          timerHint: '03:30',
        ),
        _ => const _ExerciseVisualSpec(
          eyebrow: 'STEP',
          title: '준비',
          tip: '편안하게 정면을 바라보세요.',
          subtitle: '호흡을 고르고 다음 동작을 준비합니다.',
          timerHint: '02:00',
        ),
      };
    }

    return switch (stepId) {
      'open' || 'open-wide' => const _ExerciseVisualSpec(
        eyebrow: '얼굴운동',
        title: '입 열기',
        tip: '무리하지 않는 범위에서 천천히 열어주세요.',
        subtitle: '입을 크게 벌리는 얼굴운동입니다.',
        timerHint: '03:00',
      ),
      'close' => const _ExerciseVisualSpec(
        eyebrow: '얼굴운동',
        title: '입 닫기',
        tip: '입술에 과한 힘을 주지 않습니다.',
        subtitle: '입술과 턱을 부드럽게 닫습니다.',
        timerHint: '03:00',
      ),
      'pucker' || 'oo' || 'round' => const _ExerciseVisualSpec(
        eyebrow: '구강운동',
        title: '입 모으기',
        tip: '입술을 앞으로 둥글게 모아주세요.',
        subtitle: '입술 모으기 동작을 연습합니다.',
        timerHint: '03:00',
      ),
      'smile' => const _ExerciseVisualSpec(
        eyebrow: '얼굴운동',
        title: '미소',
        tip: '볼과 입꼬리를 부드럽게 올립니다.',
        subtitle: '입을 가로로 넓히는 동작입니다.',
        timerHint: '03:00',
      ),
      'breath' => const _ExerciseVisualSpec(
        eyebrow: '호흡훈련',
        title: '준비호흡',
        tip: '어깨 힘을 빼고 천천히 들이마십니다.',
        subtitle: '말하기 전 호흡을 준비합니다.',
        timerHint: '04:00',
      ),
      'tongue_ready' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '준비',
        tip: '턱과 어깨 힘을 빼고 편안히 호흡합니다.',
        subtitle: '혀운동을 시작하기 전 호흡을 고릅니다.',
        timerHint: '00:08',
      ),
      'tongue_out' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '혀 내밀기',
        tip: '혀를 천천히 앞으로 내밀고 돌아옵니다.',
        subtitle: '혀 전방 움직임을 연습합니다.',
        timerHint: '00:10',
      ),
      'tongue_in' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '혀 넣기',
        tip: '입 안으로 천천히 되돌리고 입술은 편안히 둡니다.',
        subtitle: '내민 혀를 부드럽게 안정 위치로 되돌립니다.',
        timerHint: '00:08',
      ),
      'tongue_side' ||
      'tongue_left' ||
      'tongue_right' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '혀 좌우',
        tip: '혀를 좌우로 천천히 움직여주세요.',
        subtitle: '혀 측방 움직임을 연습합니다.',
        timerHint: '00:08',
      ),
      'tongue_up' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '혀 위로',
        tip: '혀끝을 윗입술 방향으로 천천히 올립니다.',
        subtitle: '혀끝의 위쪽 움직임을 연습합니다.',
        timerHint: '00:08',
      ),
      'tongue_down' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '혀 아래',
        tip: '혀끝을 아랫입술 방향으로 천천히 내립니다.',
        subtitle: '혀끝의 아래쪽 움직임을 연습합니다.',
        timerHint: '00:08',
      ),
      'tongue_circle' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '원 그리기',
        tip: '작은 원부터 시작해 천천히 돌립니다.',
        subtitle: '혀끝으로 입술 둘레를 따라 원을 그립니다.',
        timerHint: '00:14',
      ),
      'cheek_left' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '왼쪽 볼',
        tip: '혀로 왼쪽 볼 안쪽을 가볍게 밀어주세요.',
        subtitle: '혀 측면 힘과 방향 조절을 연습합니다.',
        timerHint: '00:08',
      ),
      'cheek_right' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '오른쪽 볼',
        tip: '혀로 오른쪽 볼 안쪽을 가볍게 밀어주세요.',
        subtitle: '혀 측면 힘과 방향 조절을 연습합니다.',
        timerHint: '00:08',
      ),
      'tongue_tip_up' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '혀끝',
        tip: '혀끝을 윗잇몸 뒤쪽에 가볍게 닿게 합니다.',
        subtitle: 'ㄹ, ㄴ, ㄷ 소리를 위한 혀끝 준비 동작입니다.',
        timerHint: '00:10',
      ),
      'rest' => const _ExerciseVisualSpec(
        eyebrow: '혀운동',
        title: '휴식',
        tip: '입과 혀의 힘을 빼고 편안히 쉬어주세요.',
        subtitle: '호흡을 고르며 혀운동을 마무리합니다.',
        timerHint: '00:10',
      ),
      _ => const _ExerciseVisualSpec(
        eyebrow: '운동',
        title: '준비',
        tip: '편안한 자세로 화면을 따라 해주세요.',
        subtitle: '일반적인 구강운동 안내입니다.',
        timerHint: '03:00',
      ),
    };
  }
}

class _GuideMouth {
  const _GuideMouth(this.ko, this.roman, this.shape);

  final String ko;
  final String roman;
  final _MouthPreviewShape shape;
}

enum _MouthPreviewShape { open, openSmall, wide, round, closed, smile }

class _TongueGuide {
  const _TongueGuide(this.label, this.id, this.shape);

  final String label;
  final String id;
  final _TonguePreviewShape shape;
}

enum _TonguePreviewShape {
  ready,
  out,
  inward,
  left,
  right,
  up,
  down,
  circle,
  cheekLeft,
  cheekRight,
  tipUp,
  rest,
}

bool _isTongueStep(String stepId) {
  return stepId == 'tongue_ready' ||
      stepId == 'tongue_out' ||
      stepId == 'tongue_in' ||
      stepId == 'tongue_left' ||
      stepId == 'tongue_right' ||
      stepId == 'tongue_up' ||
      stepId == 'tongue_down' ||
      stepId == 'tongue_circle' ||
      stepId == 'cheek_left' ||
      stepId == 'cheek_right' ||
      stepId == 'tongue_tip_up' ||
      stepId == 'tongue_hold' ||
      stepId == 'rest';
}

class _AvatarMorph {
  const _AvatarMorph({
    this.open = 0,
    this.wide = 0,
    this.round = 0,
    this.press = 0,
    this.jawShift = 0,
    this.cheekPuff = 0,
    this.cheekSide = 0,
    this.tongueOut = 0,
    this.tongueShift = 0,
    this.tongueLift = 0,
    this.tongueCircleX = 0,
    this.tongueCircleY = 0,
    this.breathLift = 0,
    this.blink = 0,
  });

  final double open;
  final double wide;
  final double round;
  final double press;
  final double jawShift;
  final double cheekPuff;
  final double cheekSide;
  final double tongueOut;
  final double tongueShift;
  final double tongueLift;
  final double tongueCircleX;
  final double tongueCircleY;
  final double breathLift;
  final double blink;

  factory _AvatarMorph.from({
    required String stepId,
    required String? shape,
    required double eased,
    required double swing,
  }) {
    if (shape != null) {
      return switch (shape) {
        'open' => _AvatarMorph(open: eased),
        'wideSmile' => _AvatarMorph(wide: 0.65 + eased * 0.35, open: 0.12),
        'round' => _AvatarMorph(round: 0.7 + eased * 0.3, open: 0.22),
        'pataka' => _AvatarMorph(
          open: 0.25 + eased * 0.55,
          wide: stepId == 'aiu' ? math.max(0, swing) : 0.2,
          round: stepId == 'aiu' ? math.max(0, -swing) : 0.1,
          tongueOut: stepId == 'pataka' ? eased * 0.28 : 0,
        ),
        'lala' => _AvatarMorph(open: 0.38, tongueOut: 0.32 + eased * 0.28),
        'jawMove' => _AvatarMorph(open: 0.2, jawShift: swing),
        'tongueMove' => _AvatarMorph(
          open: 0.36,
          tongueOut: 0.45,
          tongueShift: swing,
        ),
        'cheekPuff' => _AvatarMorph(cheekPuff: 0.5 + eased * 0.5, round: 0.25),
        _ => const _AvatarMorph(),
      };
    }

    return switch (stepId) {
      'open' || 'open-wide' => _AvatarMorph(open: eased),
      'close' => const _AvatarMorph(press: 0.4),
      'pucker' ||
      'oo' ||
      'round' => _AvatarMorph(round: 0.65 + eased * 0.35, open: 0.18),
      'smile' => _AvatarMorph(wide: 0.55 + eased * 0.45),
      'jaw_side' ||
      'jaw-left' ||
      'jaw-right' => _AvatarMorph(open: 0.2, jawShift: swing),
      'cheek_puff' ||
      'cheek-puff' => _AvatarMorph(cheekPuff: 0.55 + eased * 0.45, round: 0.2),
      'breath' => _AvatarMorph(open: 0.12, breathLift: eased),
      'tongue_ready' => _AvatarMorph(open: 0.08, breathLift: eased),
      'tongue_out' => _AvatarMorph(open: 0.45, tongueOut: 0.45 + eased * 0.55),
      'tongue_in' => _AvatarMorph(open: 0.24, tongueOut: (1 - eased) * 0.45),
      'tongue_side' => _AvatarMorph(
        open: 0.38,
        tongueOut: 0.55,
        tongueShift: swing,
      ),
      'tongue_left' => _AvatarMorph(
        open: 0.38,
        tongueOut: 0.48,
        tongueShift: -0.85 * eased,
      ),
      'tongue_right' => _AvatarMorph(
        open: 0.38,
        tongueOut: 0.48,
        tongueShift: 0.85 * eased,
      ),
      'tongue_up' => _AvatarMorph(
        open: 0.42,
        tongueOut: 0.38,
        tongueLift: 0.75 * eased,
      ),
      'tongue_down' => _AvatarMorph(
        open: 0.42,
        tongueOut: 0.52,
        tongueLift: -0.55 * eased,
      ),
      'tongue_circle' => _AvatarMorph(
        open: 0.46,
        tongueOut: 0.5,
        tongueCircleX: math.cos(swing * math.pi) * 0.65,
        tongueCircleY: math.sin(swing * math.pi) * 0.55,
      ),
      'cheek_left' => _AvatarMorph(
        press: 0.2,
        cheekPuff: 0.45 + eased * 0.45,
        cheekSide: -1,
        tongueShift: -0.8,
      ),
      'cheek_right' => _AvatarMorph(
        press: 0.2,
        cheekPuff: 0.45 + eased * 0.45,
        cheekSide: 1,
        tongueShift: 0.8,
      ),
      'tongue_tip_up' => _AvatarMorph(
        open: 0.34,
        tongueOut: 0.28,
        tongueLift: 0.95 * eased,
      ),
      'rest' => _AvatarMorph(open: 0.08 * eased, breathLift: eased),
      'blink' => _AvatarMorph(blink: eased),
      _ => _AvatarMorph(open: 0.08 * eased),
    };
  }
}
