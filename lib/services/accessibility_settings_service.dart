import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final textSizeProvider = NotifierProvider<TextSizeController, double>(
  TextSizeController.new,
);

class TextSizeController extends Notifier<double> {
  bool _changed = false;
  @override
  double build() {
    _load();
    return 1;
  }

  Future<void> _load() async {
    final value =
        (await SharedPreferences.getInstance()).getDouble('rehab_text_scale') ??
        1;
    if (!_changed && ref.mounted) state = value.clamp(1.0, 2.0).toDouble();
  }

  Future<void> setSize(double value) async {
    _changed = true;
    final next = value.clamp(1.0, 2.0).toDouble();
    if (!await (await SharedPreferences.getInstance()).setDouble(
      'rehab_text_scale',
      next,
    )) {
      throw StateError('Could not save text size');
    }
    if (ref.mounted) state = next;
  }
}
