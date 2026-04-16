import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mj_dialog/features/chat/provider/chat_provider.dart';

class AnimatedOrb extends StatefulWidget {
  final ConversationState state;

  const AnimatedOrb({super.key, required this.state});

  @override
  State<AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<AnimatedOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double pulse = _controller.value;
        double baseSize = 100.0;
        List<Color> gradientColors;
        List<BoxShadow> shadows;

        switch (widget.state) {
          case ConversationState.idle:
            baseSize = 120.0 + (pulse * 10);
            gradientColors = [Colors.grey[800]!, Colors.grey[900]!];
            shadows = [];
            break;
          case ConversationState.listening:
            baseSize = 140.0 + (pulse * 30);
            gradientColors = [Colors.blue[400]!, Colors.cyan[300]!];
            shadows = [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.4 * pulse),
                blurRadius: 40 + (pulse * 20),
                spreadRadius: 10 + (pulse * 10),
              )
            ];
            break;
          case ConversationState.thinking:
            baseSize = 120.0 + (sin(pulse * pi * 2) * 15);
            gradientColors = [Colors.purpleAccent, Colors.pinkAccent];
            shadows = [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ];
            break;
          case ConversationState.speaking:
            baseSize = 150.0 + (sin(pulse * pi * 3) * 20); // Faster pulse for speaking
            gradientColors = [Colors.white, Colors.grey[200]!];
            shadows = [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3 * pulse),
                blurRadius: 50 + (pulse * 30),
                spreadRadius: 10 + (pulse * 20),
              )
            ];
            break;
          case ConversationState.feedback:
            baseSize = 80.0;
            gradientColors = [Colors.teal[300]!, Colors.teal[500]!];
            shadows = [
              BoxShadow(
                color: Colors.teal.withValues(alpha: 0.4),
                blurRadius: 20,
              )
            ];
            break;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: baseSize,
          height: baseSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: gradientColors),
            boxShadow: shadows,
          ),
        );
      },
    );
  }
}
