import 'sentence_keyboard_dismiss_button.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/audio/stt_service.dart';
import '../rehab/view/rehab_ui.dart';

/// Transcription only. No audio file or practice recording is created here.
class SentenceVoiceInputScreen extends StatefulWidget {
  const SentenceVoiceInputScreen({
    super.key,
    required this.language,
    this.initialText = '',
    this.speech,
  });
  final String language;
  final String initialText;
  final SttService? speech;
  @override
  State<SentenceVoiceInputScreen> createState() => _SentenceVoiceInputState();
}

class _SentenceVoiceInputState extends State<SentenceVoiceInputScreen>
    with WidgetsBindingObserver {
  late final _speech =
      widget.speech ?? SttService(languageTag: widget.language);
  late final _text = TextEditingController(text: widget.initialText);
  final _editFocus = FocusNode();
  final _editorKey = GlobalKey();
  bool _starting = false,
      _listening = false,
      _finishing = false,
      _background = false,
      _endedDuringStart = false;
  String _prefix = '';
  String? _message;
  int _generation = 0;
  Timer? _limit;
  Future<void>? _stopping;
  bool get _locked => _starting || _listening || _finishing;
  String tr(String ko, String en) => rehabEnglish(context) ? en : ko;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speech.sessionEnded.addListener(_ended);
    _speech.recognitionError.addListener(_error);
  }

  void _ended() {
    if (_starting) {
      _endedDuringStart = true;
      return;
    }
    if (_listening && !_finishing) unawaited(_finish());
  }

  void _error() {
    if (!mounted || !_locked) return;
    setState(
      () => _message = tr(
        '음성 인식이 중단됐어요. 받아쓴 문장은 유지됩니다.',
        'Recognition stopped. The text received is still here.',
      ),
    );
    _ended();
  }

  Future<void> _edit() async {
    if (_starting || _finishing) return;
    // Editing is an explicit action: finish recognition first, then invalidate
    // its late results before giving the keyboard back to the user.
    if (_listening) await _finish();
    if (!mounted || _locked) return;
    // iPad can hide its keyboard while the field still owns focus. Complete
    // a focus-out frame so Edit also reopens that existing input connection.
    _editFocus.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _locked) return;
    _editFocus.requestFocus();
    final editorContext = _editorKey.currentContext;
    if (editorContext != null && editorContext.mounted) {
      await Scrollable.ensureVisible(
        editorContext,
        alignment: .25,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  Future<void> _start() async {
    if (_locked) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final generation = ++_generation;
    _prefix = _text.text.trimRight();
    setState(() {
      _starting = true;
      _endedDuringStart = false;
      _message = null;
    });
    try {
      final started = await _speech.startListening(
        onResult: (value, isFinal) async {
          if (!mounted || generation != _generation || value.trim().isEmpty) {
            return;
          }
          final combined = [
            _prefix,
            value.trim(),
          ].where((v) => v.isNotEmpty).join('\n');
          setState(
            () => _text.value = TextEditingValue(
              text: combined,
              selection: TextSelection.collapsed(offset: combined.length),
            ),
          );
        },
      );
      if (!mounted || generation != _generation) {
        // A permission response can arrive after the user has left this screen.
        await _speech.dispose();
        return;
      }
      setState(() {
        _listening = started;
        if (!started) {
          _message = tr(
            '음성 입력을 시작하지 못했어요. 마이크·음성 인식 권한과 언어·연결 상태를 확인해 주세요.',
            'Could not start voice input. Check microphone/speech permissions, language and connection.',
          );
        }
      });
      if (started) {
        _limit = Timer(const Duration(seconds: 45), () => unawaited(_finish()));
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _message = tr(
            '음성 입력에 연결하지 못했어요. 직접 입력도 사용할 수 있어요.',
            'Could not connect to voice input. You can still type.',
          ),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _starting = false);
      }
    }
    if (mounted &&
        generation == _generation &&
        _listening &&
        (_background || _endedDuringStart)) {
      await _finish();
    }
  }

  Future<void> _finish() =>
      _stopping ??= _finishOnce().whenComplete(() => _stopping = null);
  Future<void> _finishOnce() async {
    if (!_listening || _finishing) return;
    _limit?.cancel();
    setState(() => _finishing = true);
    try {
      await _speech.stopListening().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Invalidate late results before releasing the editor.
      _generation++;
      try {
        await _speech.dispose().timeout(const Duration(seconds: 1));
      } catch (_) {}
      if (mounted) {
        setState(
          () => _message = tr(
            '중지 확인에 시간이 걸렸어요. 글은 유지됩니다. 필요하면 음성 입력 화면을 다시 열어 주세요.',
            'Stopping took too long. Your text is retained. Reopen voice input if needed.',
          ),
        );
      }
    } finally {
      _generation++;
      if (mounted) {
        setState(() {
          _listening = false;
          _finishing = false;
          _message ??= _text.text.trim() == _prefix.trim()
              ? tr(
                  '새로 인식된 문장이 없어요. 다시 말하거나 직접 입력해 주세요.',
                  'No new text was recognized. Try again or type.',
                )
              : tr(
                  '문장을 확인하고 수정하세요. 이어서 말하면 새 줄에 추가됩니다.',
                  'Review and edit the text. Continue speaking to append a new line.',
                );
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _background = false;
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Permission sheets temporarily make iOS inactive during startup.
      if (state == AppLifecycleState.paused || !_starting) _background = true;
      if (_listening) unawaited(_finish());
    }
  }

  Future<void> _cancel() async {
    _generation++;
    _limit?.cancel();
    // Invalidate callbacks and stop the microphone before closing animation.
    unawaited(_speech.dispose().catchError((_) {}));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _settings() async {
    bool opened = false;
    try {
      opened = await openAppSettings();
    } catch (_) {}
    if (!opened && mounted) {
      setState(
        () => _message = tr(
          '기기의 설정에서 말이음의 마이크·음성 인식 권한을 확인해 주세요.',
          'Open device Settings and check SpeechBridge microphone/speech permissions.',
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _limit?.cancel();
    _speech.sessionEnded.removeListener(_ended);
    _speech.recognitionError.removeListener(_error);
    unawaited(_speech.dispose().catchError((_) {}));
    _editFocus.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(tr('음성으로 문장 입력', 'Enter sentences by voice')),
      actions: const [SentenceKeyboardDismissButton()],
      leading: IconButton(
        onPressed: _cancel,
        icon: const Icon(Icons.close),
        tooltip: tr('취소 · 기존 문장 유지', 'Cancel · keep original text'),
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const ValueKey('sentence-voice-toggle'),
              onPressed: _starting || _finishing
                  ? null
                  : _listening
                  ? _finish
                  : _start,
              icon: Icon(_listening ? Icons.stop : Icons.mic),
              label: Text(
                _starting
                    ? tr('권한·연결 확인 중', 'Checking access')
                    : _finishing
                    ? tr('마지막 문장 확인 중', 'Finishing transcription')
                    : _listening
                    ? tr('음성 입력 끝내기', 'Finish voice input')
                    : tr('말하기 · 이어서 입력', 'Speak · append text'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              key: const ValueKey('sentence-voice-apply'),
              onPressed: _locked || _text.text.trim().isEmpty
                  ? null
                  : () {
                      final value = _text.text.trim();
                      Navigator.pop(
                        context,
                        value == widget.initialText.trim() ? null : value,
                      );
                    },
              child: Text(tr('수정한 문장 가져오기', 'Use edited sentences')),
            ),
          ],
        ),
      ),
    ),
    body: ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          tr(
            '기존 문장은 유지하고, 말한 내용을 새 줄에 추가해요. 짧은 문장씩 말하고 멈춘 뒤 수정하세요.',
            'Your existing text is kept. Speak a short sentence to append a new line, then stop and edit.',
          ),
        ),
        Text(
          widget.language == 'ko-KR'
              ? '인식 언어: 한국어'
              : 'Recognition language: English',
        ),
        Text(
          tr(
            '기기의 음성 인식을 사용하며 언어·기기에 따라 인터넷 연결과 OS 제공자의 처리가 필요할 수 있어요. 입력용 음성을 앱에 저장하지 않으며 두 번 읽기의 연습 녹음으로 세지 않아요.',
            'Uses device speech recognition; depending on device/language, internet access and processing by the OS provider may be needed. Input audio is not stored by this app or counted as practice recordings.',
          ),
        ),
        const SizedBox(height: 16),
        if (_locked) ...[
          const LinearProgressIndicator(),
          Text(
            _listening
                ? tr(
                    '듣고 있어요. 잠시 쉬어 인식이 끝나도 이어서 입력할 수 있어요.',
                    'Listening. If recognition stops during a pause, you can continue with another phrase.',
                  )
                : tr('잠시 기다려 주세요.', 'Please wait.'),
          ),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            key: const ValueKey('sentence-voice-edit'),
            onPressed: _starting || _finishing ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(tr('문장 편집하기', 'Edit sentences')),
          ),
        ),
        KeyedSubtree(
          key: _editorKey,
          child: TextField(
            key: const ValueKey('sentence-voice-text'),
            focusNode: _editFocus,
            onTap: () {
              if (_locked) unawaited(_edit());
            },
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            controller: _text,
            readOnly: _locked,
            minLines: 5,
            maxLines: 14,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: tr(
                '받아쓴 문장 · 수정 가능',
                'Transcribed sentences · editable',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_message!, semanticsLabel: _message),
          ),
        TextButton.icon(
          onPressed: _locked ? null : _settings,
          icon: const Icon(Icons.settings_outlined),
          label: Text(
            tr('마이크·음성 인식 권한 설정', 'Microphone / speech permission settings'),
          ),
        ),
      ],
    ),
  );
}
