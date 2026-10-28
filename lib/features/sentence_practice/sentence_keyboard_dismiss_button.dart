import 'package:flutter/material.dart';
import '../rehab/view/rehab_ui.dart';

/// Always reachable in the app bar, including with an iPad software keyboard.
class SentenceKeyboardDismissButton extends StatelessWidget {
  const SentenceKeyboardDismissButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: rehabEnglish(context) ? 'Hide keyboard' : '키보드 내리기',
    icon: const Icon(Icons.keyboard_hide_outlined),
    onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
  );
}
