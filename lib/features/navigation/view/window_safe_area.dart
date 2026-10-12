import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Makes iPad window controls part of the safe area for every Navigator route.
class WindowSafeArea extends StatefulWidget {
  const WindowSafeArea({super.key, required this.child});

  final Widget child;

  @override
  State<WindowSafeArea> createState() => _WindowSafeAreaState();
}

class _WindowSafeAreaState extends State<WindowSafeArea> {
  static const _channel = MethodChannel('speech_rehab/window_layout');
  double _top = 0;
  int _revision = 0;
  bool get _usesNativeInsets =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (_usesNativeInsets) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'topInsetChanged') {
          _revision++;
          _update(call.arguments);
        }
      });
      _load();
    }
  }

  Future<void> _load() async {
    final revision = _revision;
    try {
      final top = await _channel.invokeMethod<num>('getTopInset');
      // A layout update can arrive while the initial request is in flight.
      if (revision == _revision) _update(top);
    } on MissingPluginException {
      // Older hosts keep the ordinary Flutter safe area.
    } on PlatformException {
      // Preserve platform-provided insets when the bridge is unavailable.
    }
  }

  void _update(Object? value) {
    if (!mounted || value is! num) return;
    final top = value.toDouble();
    if (!top.isFinite || top < 0 || top == _top) return;
    setState(() => _top = top);
  }

  @override
  void dispose() {
    if (_usesNativeInsets) _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(top: math.max(media.padding.top, _top)),
        viewPadding: media.viewPadding.copyWith(
          top: math.max(media.viewPadding.top, _top),
        ),
      ),
      child: widget.child,
    );
  }
}
