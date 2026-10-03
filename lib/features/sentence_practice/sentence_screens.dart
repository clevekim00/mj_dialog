import 'image_review_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../services/audio/audio_player_service.dart';
import '../rehab/audio/practice_capture.dart';
import '../rehab/audio/practice_waveform.dart';
import '../rehab/comfort/comfort_training.dart';
import '../rehab/view/rehab_ui.dart';
import 'sentence_repository.dart';
import 'sentence_ocr.dart';
import 'sentence_analysis_client.dart';

String st(BuildContext c, String ko, String en) => rehabEnglish(c) ? en : ko;
String assessmentLabel(String status, bool en) => switch (status) {
  'completed' => en ? 'Feedback ready' : '피드백 준비됨',
  'queued' || 'running' => en ? 'Analysis pending' : '분석 대기 중',
  'unavailable' => en ? 'Analysis unavailable' : '분석이 어려워요',
  'failed' => en ? 'Could not connect · retry' : '연결 실패 · 재시도 가능',
  'cancelled' => en ? 'Cancelled' : '취소됨',
  'expired' => en ? 'Expired · request again' : '만료 · 다시 요청 가능',
  _ => en ? 'Not requested' : '아직 요청하지 않음',
};

class SentenceLibraryScreen extends StatefulWidget {
  const SentenceLibraryScreen({super.key, this.repository});
  final SentenceRepository? repository;
  @override
  State<SentenceLibraryScreen> createState() => _LibraryState();
}

class _LibraryState extends State<SentenceLibraryScreen> {
  late Future<SentenceRepository> _repo;
  String _search = '';
  @override
  void initState() {
    super.initState();
    _repo = widget.repository != null
        ? Future.value(widget.repository)
        : SentenceRepository.open();
  }

  Future<void> _add(SentenceRepository repo) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SentenceInputScreen(repository: repo),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<SentenceRepository>(
    future: _repo,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return RehabPage(
          title: st(context, '내 문장', 'My sentences'),
          children: [
            Text(
              st(
                context,
                '기록을 열지 못했어요. 저장 공간을 확인하고 다시 시도하세요.',
                'Could not open history. Check storage and retry.',
              ),
            ),
            TextButton(
              onPressed: () =>
                  setState(() => _repo = SentenceRepository.open()),
              child: Text(st(context, '다시 시도', 'Retry')),
            ),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final repo = snapshot.data!;
      return RehabPage(
        title: st(context, '내 문장 두 번 읽기', 'Read my sentence twice'),
        actions: [const ComfortButton(situation: ComfortContext.sentences)],
        children: [
          Text(
            st(
              context,
              '내게 필요한 문장을 읽고 두 목소리를 비교해요. 한 번만 녹음해도 괜찮아요.',
              'Read a useful sentence and compare two recordings. One recording is enough too.',
            ),
          ),
          FilledButton.icon(
            onPressed: () => _add(repo),
            icon: const Icon(Icons.add),
            label: Text(
              st(context, '문장 추가 · 입력 / 사진', 'Add sentence · text / image'),
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: st(context, '문장 검색', 'Search sentences'),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          for (final sentence in repo.sentences().where(
            (s) => (s['text'] as String).toLowerCase().contains(
              _search.toLowerCase(),
            ),
          ))
            Card(
              child: ListTile(
                title: Text(sentence['text'] as String),
                subtitle: Text(
                  '${sentence['language']} · ${sentence['count']} ${st(context, '회 연습', 'practice pairs')}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SentenceHistoryScreen(
                        repository: repo,
                        sentence: sentence,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
        ],
      );
    },
  );
}

class SentenceInputScreen extends StatefulWidget {
  const SentenceInputScreen({super.key, required this.repository, this.ocr});
  final SentenceRepository repository;
  final SentenceOcr? ocr;
  @override
  State<SentenceInputScreen> createState() => _InputState();
}

class _InputState extends State<SentenceInputScreen> {
  final _text = TextEditingController();
  String _language = 'ko-KR', _source = 'text';
  Uint8List? _sourceImage;
  bool _busy = false, _reviewed = false;
  String? _error;
  String _ocrStage = '';
  bool _showPermissionSettings = false;
  int _ocrGeneration = 0;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _ocr([
    SentenceImageSource source = SentenceImageSource.file,
  ]) async {
    final generation = ++_ocrGeneration;
    bool active() => mounted && generation == _ocrGeneration;
    setState(() {
      _busy = true;
      _showPermissionSettings = false;
      _ocrStage = st(context, '사진을 선택하고 있어요', 'Choosing an image');
      _error = null;
    });
    try {
      final ocr = widget.ocr ?? SentenceOcr();
      final bytes = await ocr.pickImage(
        source: source,
        onStage: (stage) {
          if (active()) {
            setState(
              () => _ocrStage = stage == 'loading'
                  ? st(context, '사진 파일을 불러오고 있어요', 'Loading the image file')
                  : st(context, '이미지를 확인하고 있어요', 'Checking the image'),
            );
          }
        },
      );
      if (bytes == null || !mounted || !active()) return;
      final cropped = await Navigator.push<Uint8List>(
        context,
        PageRouteBuilder<Uint8List>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ImageReviewScreen(bytes: bytes),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      if (cropped == null || !active()) return;
      setState(() {
        _sourceImage = cropped;
        _ocrStage = st(context, '사진의 글을 읽고 있어요', 'Reading text from the image');
      });
      final text = await ocr.recognize(cropped, _language);
      if (active()) {
        setState(() {
          _text.text = text;
          _source = 'ocr';
          _reviewed = false;
        });
      }
    } catch (error) {
      if (active()) {
        final code = error is PlatformException ? error.code : '';
        final denied = {
          'camera_access_denied',
          'photo_access_denied',
          'camera_access_denied_without_prompt',
          'photo_access_denied_without_prompt',
        }.contains(code);
        final restricted = {
          'camera_access_restricted',
          'photo_access_restricted',
        }.contains(code);
        final unavailable =
            error is MissingPluginException || code == 'channel-error';
        setState(() {
          _showPermissionSettings = denied;
          _error = denied
              ? st(
                  context,
                  '접근 권한이 꺼져 있어요. 아래 ‘앱 권한 설정 열기’에서 카메라 또는 사진 접근을 허용한 뒤 돌아와 다시 눌러 주세요. 직접 입력도 가능해요.',
                  'Access is denied. Open app permission settings below, allow camera or photo access, then return and try again. You can also type.',
                )
              : restricted
              ? st(
                  context,
                  '기기에서 카메라 또는 사진 사용을 제한하고 있어요. 스크린 타임이나 기기 관리 설정을 확인하거나 관리자에게 문의하세요. 직접 입력도 가능해요.',
                  'Camera or photo access is restricted by this device. Check Screen Time or device management, or contact the administrator. You can also type.',
                )
              : unavailable
              ? st(
                  context,
                  '사진 기능에 연결하지 못했어요. 앱을 완전히 종료하고 다시 실행해 주세요. 계속되면 앱 업데이트가 필요해요.',
                  'Could not connect to the photo feature. Close and reopen the app. If it persists, update the app.',
                )
              : code == 'no_available_camera'
              ? st(
                  context,
                  '사용할 수 있는 카메라가 없어요. 사진 보관함에서 선택하거나 직접 입력하세요.',
                  'No camera is available. Choose from the photo library or type.',
                )
              : st(
                  context,
                  '사진을 읽지 못했어요. 다른 사진을 선택하거나 직접 입력하세요. PNG/JPG 10MB·2천만 화소 이하를 사용할 수 있어요.',
                  'Could not read the photo. Choose another photo or type. Use PNG/JPG below 10 MB / 20 megapixels.',
                );
        });
      }
    } finally {
      if (active()) setState(() => _busy = false);
    }
  }

  Future<void> _openPermissionSettings() async {
    bool opened = false;
    try {
      opened = await (widget.ocr ?? SentenceOcr()).openSettings();
    } catch (_) {
      // Keep the entered text and provide a manual route if settings cannot open.
    }
    if (!opened && mounted) {
      setState(
        () => _error = st(
          context,
          '설정을 열지 못했어요. 기기의 설정 앱에서 말이음의 카메라·사진 권한을 확인해 주세요.',
          'Could not open Settings. Open the device Settings app and check SpeechBridge camera/photo permissions.',
        ),
      );
    }
  }

  void _save() {
    final lines = _text.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      setState(
        () => _error = st(
          context,
          '연습할 문장을 입력하세요. 한 줄에 한 문장씩 저장해요.',
          'Enter text to practise. Each line is saved as one sentence.',
        ),
      );
      return;
    }
    try {
      widget.repository.transaction(() {
        for (final line in lines) {
          widget.repository.addSentence(line, _language, source: _source);
        }
      });
      Navigator.pop(context);
    } catch (_) {
      setState(
        () => _error = st(
          context,
          '저장하지 못했어요. 입력한 글은 유지됩니다.',
          'Could not save. Your text is still here.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => RehabPage(
    title: st(context, '문장 입력·확인', 'Enter and review sentences'),
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          value: _reviewed,
          onChanged: _busy
              ? null
              : (v) => setState(() => _reviewed = v ?? false),
          title: Text(
            st(context, '문장과 언어를 확인했어요', 'I checked the text and language'),
          ),
        ),
        FilledButton(
          onPressed: _busy || !_reviewed ? null : _save,
          child: Text(st(context, '문장 저장', 'Save sentences')),
        ),
      ],
    ),
    children: [
      DropdownButtonFormField<String>(
        initialValue: _language,
        items: const [
          DropdownMenuItem(value: 'ko-KR', child: Text('한국어')),
          DropdownMenuItem(value: 'en-US', child: Text('English')),
        ],
        onChanged: _busy
            ? null
            : (v) => setState(() {
                _language = v!;
                _reviewed = false;
              }),
        decoration: InputDecoration(
          labelText: st(context, '읽을 문장의 언어', 'Language to read'),
        ),
      ),
      if ((widget.ocr ?? SentenceOcr()).mobileSources) ...[
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _ocr(SentenceImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(st(context, '사진 보관함에서 선택', 'Choose from photo library')),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _ocr(SentenceImageSource.camera),
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(st(context, '카메라로 촬영', 'Take a photo')),
        ),
      ] else
        OutlinedButton.icon(
          onPressed: _busy || !(widget.ocr ?? SentenceOcr()).supported
              ? null
              : () => _ocr(),
          icon: const Icon(Icons.image_outlined),
          label: Text(
            st(context, '사진에서 글 가져오기 (OCR)', 'Import text from image (OCR)'),
          ),
        ),
      Text(
        st(
          context,
          '한 줄에 한 문장씩 입력하세요. 사진의 글자는 틀릴 수 있어요. 불필요한 개인정보를 지우고 줄을 나누거나 합쳐 주세요. 원본 사진은 보관하지 않아요.',
          'Use one sentence per line. OCR can be wrong: correct the text, remove private details, and split or join lines. The original image is not retained.',
        ),
      ),
      if (_busy) ...[
        const LinearProgressIndicator(),
        Text(_ocrStage),
        TextButton(
          onPressed: () => setState(() {
            _ocrGeneration++;
            _busy = false;
          }),
          child: Text(st(context, '가져오기 취소', 'Cancel import')),
        ),
      ],
      if (_sourceImage != null)
        ExpansionTile(
          title: Text(st(context, '원본 영역과 대조하기', 'Compare with image')),
          children: [Image.memory(_sourceImage!, height: 220)],
        ),
      TextField(
        controller: _text,
        enabled: !_busy,
        minLines: 5,
        maxLines: 14,
        onChanged: (_) => setState(() => _reviewed = false),
        decoration: InputDecoration(
          labelText: st(context, '읽을 문장', 'Sentences to read'),
          border: const OutlineInputBorder(),
        ),
      ),
      if (_error != null) Text(_error!),
      if (_showPermissionSettings)
        OutlinedButton.icon(
          onPressed: _busy ? null : _openPermissionSettings,
          icon: const Icon(Icons.settings_outlined),
          label: Text(
            st(context, '앱 권한 설정 열기', 'Open app permission settings'),
          ),
        ),
    ],
  );
}

class SentenceHistoryScreen extends StatefulWidget {
  const SentenceHistoryScreen({
    super.key,
    required this.repository,
    required this.sentence,
  });
  final SentenceRepository repository;
  final Map<String, dynamic> sentence;
  @override
  State<SentenceHistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<SentenceHistoryScreen> {
  String? _error;
  Future<void> _open(String? pair) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SentencePairScreen(
          repository: widget.repository,
          sentence: widget.sentence,
          pairId: pair,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          st(c, '이 문장의 기록을 삭제할까요?', 'Delete this sentence’s history?'),
        ),
        content: Text(
          st(
            c,
            '모든 녹음과 평가가 삭제됩니다. 서버에 남은 작업은 먼저 정리해야 하며 원본 사진은 지우지 않습니다.',
            'All recordings and feedback will be deleted. Remote jobs must be cleared first. Original photos are not deleted.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(st(c, '취소', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(st(c, '삭제', 'Delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      for (final pair in widget.repository.pairs(
        widget.sentence['id'] as String,
      )) {
        for (final recording in widget.repository.recordings(
          pair['id'] as String,
        )) {
          final a =
              jsonDecode(recording['assessment'] as String)
                  as Map<String, dynamic>;
          if (a['remoteJobId'] != null) {
            throw StateError('Clear remote analysis first');
          }
        }
      }
      await widget.repository.deleteSentence(widget.sentence['id'] as String);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = st(
            context,
            '삭제를 마치지 못했어요. 각 녹음의 서버 작업 정리를 누른 뒤 다시 시도하세요.',
            'Could not finish deletion. Clear each recording’s remote job, then retry.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    return RehabPage(
      title: st(context, '문장별 기록', 'Sentence history'),
      actions: [
        IconButton(
          onPressed: _delete,
          icon: const Icon(Icons.delete_outline),
          tooltip: st(context, '문장 삭제', 'Delete sentence'),
        ),
      ],
      children: [
        SelectableText(
          widget.sentence['text'] as String,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          st(
            context,
            '녹음한 문장은 그대로 보존돼요. 다른 문장은 보관함에서 새로 추가하세요.',
            'Recorded text is preserved. Add different text as a new sentence.',
          ),
        ),
        FilledButton(
          onPressed: () => _open(null),
          child: Text(st(context, '새로 두 번 읽기', 'Start a new pair')),
        ),
        if (_error != null) Text(_error!),
        for (final pair in repo.pairs(widget.sentence['id'] as String))
          Card(
            child: ListTile(
              title: Text(
                (pair['created'] as String)
                    .replaceFirst('T', ' ')
                    .split('.')
                    .first,
              ),
              subtitle: Text(
                '${repo.recordings(pair['id'] as String).length}/2 · ${st(context, '녹음과 피드백 보기', 'Recordings and feedback')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(pair['id'] as String),
            ),
          ),
      ],
    );
  }
}

class SentencePairScreen extends StatefulWidget {
  const SentencePairScreen({
    super.key,
    required this.repository,
    required this.sentence,
    this.pairId,
    this.capture,
  });
  final SentenceRepository repository;
  final Map<String, dynamic> sentence;
  final String? pairId;
  final PracticeCapture? capture;
  @override
  State<SentencePairScreen> createState() => _PairState();
}

class _PairState extends State<SentencePairScreen> with WidgetsBindingObserver {
  late final PracticeCapture _capture;
  final _player = AudioPlayerService();
  StreamSubscription<dynamic>? _completion;
  late String _pair;
  bool _recording = false, _busy = false, _wave = true, _playing = false;
  String? _error;
  String? _pendingPath;
  int? _recordSlot;
  bool _background = false;
  Completer<void>? _playDone;
  int _playGeneration = 0;
  int? _tensionBefore, _tensionAfter;
  final Map<String, CancelToken> _analyses = {};
  final _server = TextEditingController(
    text: const String.fromEnvironment(
      'SENTENCE_ANALYSIS_URL',
      defaultValue: 'http://127.0.0.1:8001',
    ),
  );
  final _token = TextEditingController();
  List<Map<String, dynamic>> get _takes => widget.repository.recordings(_pair);
  String tr(String ko, String en) => st(context, ko, en);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _capture = widget.capture ?? PracticeCapture();
    _pair =
        widget.pairId ??
        widget.repository.startPair(widget.sentence['id'] as String);
    final pair = widget.repository
        .pairs(widget.sentence['id'] as String)
        .firstWhere((p) => p['id'] == _pair);
    _tensionBefore = pair['tension_before'] as int?;
    _tensionAfter = pair['tension_after'] as int?;
    _capture.limitReached.addListener(_limit);
    _capture.problem.addListener(_problem);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (_background && _recording && !_busy) unawaited(_stop());
  }

  void _limit() {
    if (_capture.limitReached.value && _recording && !_busy) unawaited(_stop());
  }

  void _problem() {
    if (_capture.problem.value != null && mounted) {
      setState(
        () => _error = tr(
          '마이크 입력을 확인하세요. 녹음을 멈추고 저장할 수 있어요.',
          'Check microphone input. You can stop and save.',
        ),
      );
    }
  }

  Future<void> _stopPlayback() async {
    _playGeneration++;
    if (_playDone?.isCompleted == false) _playDone!.complete();
    await _completion?.cancel();
    _completion = null;
    await _player.stop();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _play(List<Map<String, dynamic>> takes) async {
    await _stopPlayback();
    final generation = _playGeneration;
    try {
      for (final take in takes) {
        if (generation != _playGeneration || !mounted) return;
        final done = Completer<void>();
        _playDone = done;
        _completion = const EventChannel('speech_rehab/audio_player/events')
            .receiveBroadcastStream()
            .listen(
              (event) {
                if (event == 'complete' && !done.isCompleted) done.complete();
              },
              onError: (Object e) {
                if (!done.isCompleted) done.completeError(e);
              },
            );
        setState(() => _playing = true);
        await _player.playFile(widget.repository.audioPath(take));
        await done.future.timeout(
          Duration(milliseconds: (take['duration'] as int) + 5000),
        );
        await _completion?.cancel();
        _completion = null;
        if (generation != _playGeneration) return;
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      if (mounted) setState(() => _playing = false);
    } catch (_) {
      if (mounted && generation == _playGeneration) {
        setState(() {
          _playing = false;
          _error = tr(
            '녹음을 재생하지 못했어요. 파일을 확인해 주세요.',
            'Could not play recording. Check the audio file.',
          );
        });
      }
    }
  }

  Future<void> _start() async {
    if (_busy || _recording || _takes.length >= 2) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _recordSlot = _takes.length;
      await _stopPlayback();
      await _capture.startRecording('sentence_${const Uuid().v4()}');
      if (mounted) setState(() => _recording = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = tr(
            '녹음을 시작하지 못했어요. 마이크 권한을 확인하세요.',
            'Could not start recording. Check microphone access.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_background && _recording && mounted) await _stop();
  }

  Future<void> _stop() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _pendingPath ??= await _capture.stopRecording();
      if (_pendingPath == null) {
        if (mounted) {
          setState(() {
            _recording = false;
            _error = tr(
              '소리가 저장되지 않았어요. 마이크를 확인하고 다시 녹음하세요.',
              'No audio was saved. Check the microphone and try again.',
            );
          });
        }
        return;
      }
      await widget.repository.recover();
      // Recovery may have committed a previous failed save already.
      if (!_takes.any((t) => t['slot'] == _recordSlot) &&
          _pendingPath != null) {
        await widget.repository.saveRecording(
          _pair,
          _recordSlot!,
          _pendingPath!,
          _capture.durationMs,
          List.of(_capture.envelope),
        );
      }
      _pendingPath = null;
      if (mounted) {
        setState(() {
          _recording = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = tr(
            '저장하지 못했어요. 저장 재시도로 녹음을 보존하세요.',
            'Could not save. Retry saving to preserve the recording.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyze(Map<String, dynamic> take) async {
    final id = take['id'] as String;
    final previous =
        jsonDecode(take['assessment'] as String) as Map<String, dynamic>;
    final url = previous['server'] as String? ?? _server.text.trim();
    final client = SentenceAnalysisClient(
      baseUrl: url,
      accessToken: _token.text.trim(),
    );
    if (_analyses.containsKey(id)) return;
    final cancel = CancelToken();
    setState(() => _analyses[id] = cancel);
    Map<String, dynamic> current = Map.of(previous);
    try {
      final caps = await client.capabilities();
      if (caps['ready'] != true) throw StateError('Server is not ready');
      if (!mounted || cancel.isCancelled) return;
      final consent = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(tr('AI 분석을 위해 전송할까요?', 'Send for AI analysis?')),
          content: Text(
            '${tr('문장과 이 녹음만 다음 서버에 전송합니다. 원본 사진은 보내지 않아요.', 'Only this sentence and recording are sent. No original image is uploaded.')}\n$url\n${tr('분석기', 'Processor')}: ${caps['processor']}\n${tr('서버 임시 보관 최대 초', 'Maximum temporary retention (seconds)')}: ${caps['retentionSeconds']}\n${tr('진단·발음 점수가 아닌 연습 참고 피드백입니다.', 'Practice feedback, not diagnosis or pronunciation scoring.')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr('취소', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(tr('동의하고 분석', 'Agree and analyze')),
            ),
          ],
        ),
      );
      if (consent != true || cancel.isCancelled) return;
      final result = await client.analyze(
        recording: take,
        sentence: widget.sentence,
        assessment: current,
        path: widget.repository.audioPath(take),
        cancel: cancel,
        onQueued: (a) async {
          current = a;
          widget.repository.assessment(id, a);
          if (mounted) setState(() {});
        },
      );
      widget.repository.assessment(id, result);
      current = result;
      try {
        await client.delete(result['remoteJobId'] as String);
        result.remove('remoteJobId');
        widget.repository.assessment(id, result);
      } catch (_) {
        /* Keep cleanup identity for explicit retry. */
      }
    } catch (e) {
      if (current['status'] != 'completed') {
        if (e is DioException && e.response?.statusCode == 404) {
          current.remove('remoteJobId');
          current['status'] = 'expired';
        } else {
          current['status'] = cancel.isCancelled ? 'cancelled' : 'failed';
        }
        widget.repository.assessment(id, current);
      }
      if (mounted) {
        setState(
          () => _error = tr(
            '분석을 완료하지 못했어요. 녹음은 저장되어 있으며 서버 설정을 확인하고 다시 요청할 수 있어요.',
            'Analysis did not finish. Your recording is saved. Check server settings and retry.',
          ),
        );
      }
    } finally {
      _analyses.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _cleanup(Map<String, dynamic> take) async {
    final a = jsonDecode(take['assessment'] as String) as Map<String, dynamic>;
    try {
      await SentenceAnalysisClient(
        baseUrl: a['server'] as String,
        accessToken: _token.text.trim(),
      ).delete(a['remoteJobId'] as String);
      a.remove('remoteJobId');
      if ({'queued', 'running', 'failed', 'cancelled'}.contains(a['status'])) {
        a['status'] = 'cancelled';
      }
      widget.repository.assessment(take['id'] as String, a);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = tr(
            '서버 작업 정리에 실패했어요. 연결·로그인을 확인하고 다시 시도하세요.',
            'Could not clear remote job. Check connection/sign-in and retry.',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_playDone?.isCompleted == false) _playDone!.complete();
    for (final token in _analyses.values) {
      token.cancel('screen closed');
    }
    _playGeneration++;
    unawaited(_completion?.cancel());
    unawaited(_player.stop());
    _player.dispose();
    _capture.limitReached.removeListener(_limit);
    _capture.problem.removeListener(_problem);
    unawaited(_capture.dispose());
    _server.dispose();
    _token.dispose();
    super.dispose();
  }

  Widget _tension(bool before) => DropdownButtonFormField<int>(
    initialValue: before ? _tensionBefore : _tensionAfter,
    decoration: InputDecoration(
      labelText: before
          ? tr('시작 전 긴장 (선택)', 'Tension before (optional)')
          : tr('마친 뒤 긴장 (선택)', 'Tension after (optional)'),
    ),
    items: [
      DropdownMenuItem<int>(value: null, child: Text(tr('건너뛰기', 'Skip'))),
      for (var i = 0; i <= 10; i++)
        DropdownMenuItem(
          value: i,
          child: Text(
            '$i${i == 0
                ? tr(' · 없음', ' · none')
                : i == 10
                ? tr(' · 매우 높음', ' · very high')
                : ''}',
          ),
        ),
    ],
    onChanged: _recording || _busy
        ? null
        : (v) => setState(() {
            if (before) {
              _tensionBefore = v;
              widget.repository.db.execute(
                'UPDATE pairs SET tension_before=? WHERE id=?',
                [v, _pair],
              );
            } else {
              _tensionAfter = v;
              widget.repository.tensionAfter(_pair, v);
            }
          }),
  );
  @override
  Widget build(BuildContext context) {
    final en = rehabEnglish(context), takes = _takes;
    return PopScope(
      canPop: !_recording && !_busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(
            () => _error = tr(
              '먼저 녹음을 멈추고 저장해 주세요.',
              'Stop and save the recording first.',
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('두 목소리 비교', 'Compare two readings')),
          actions: [
            ComfortButton(
              situation: ComfortContext.sentences,
              enabled: !_recording && !_busy,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _busy
                  ? null
                  : _recording
                  ? _stop
                  : takes.length < 2
                  ? _start
                  : () => Navigator.pop(context),
              icon: Icon(
                _recording
                    ? Icons.stop
                    : takes.length < 2
                    ? Icons.mic
                    : Icons.check,
              ),
              label: Text(
                _busy
                    ? tr('저장·준비 중', 'Saving / preparing')
                    : _recording
                    ? (_error != null
                          ? tr('멈추고 저장 재시도', 'Stop / retry saving')
                          : tr('녹음 끝내고 저장', 'Stop and save'))
                    : takes.length < 2
                    ? '${takes.length + 1}${tr('차 녹음', ' · Record')}'
                    : tr('오늘 마치기', 'Finish today'),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SelectableText(
              widget.sentence['text'] as String,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              tr(
                '필요하면 문장 중간에 쉬어도 돼요. 한 번만 녹음하고 돌아가도 저장됩니다.',
                'Pause within the sentence whenever needed. You can leave after one recording; it stays saved.',
              ),
            ),
            if (takes.isEmpty) _tension(true),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            SwitchListTile(
              title: Text(tr('소리 흐름 보기', 'Show sound flow')),
              value: _wave,
              onChanged: (v) => setState(() => _wave = v),
            ),
            if (_recording && _wave)
              ValueListenableBuilder(
                valueListenable: _capture.frame,
                builder: (context, frame, _) => PracticeWaveform(
                  values: _capture.envelope,
                  durationMs: _capture.durationMs,
                  english: en,
                  live: frame,
                ),
              ),
            if (takes.length == 2)
              OutlinedButton(
                onPressed: _recording || _busy || _playing
                    ? null
                    : () => _play(takes),
                child: Text(tr('1차 → 2차 순서대로 듣기', 'Listen A → B')),
              ),
            if (_playing)
              TextButton(
                onPressed: _stopPlayback,
                child: Text(tr('듣기 멈추기', 'Stop playback')),
              ),
            for (final take in takes) _takeCard(take, en),
            if (takes.isNotEmpty) _tension(false),
            Text(
              tr(
                '긴장도는 내가 느낀 정도예요. 목소리에서 측정한 점수나 진단이 아니에요.',
                'Tension is your own reflection, not a voice measurement or diagnosis.',
              ),
            ),
            ExpansionTile(
              title: Text(tr('AI 분석 서버 설정', 'AI analysis server settings')),
              children: [
                TextField(
                  controller: _server,
                  enabled: _analyses.isEmpty,
                  decoration: InputDecoration(
                    labelText: tr('서버 주소 (HTTPS)', 'Server URL (HTTPS)'),
                  ),
                ),
                TextField(
                  controller: _token,
                  enabled: _analyses.isEmpty,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: tr(
                      '로그인 서버에서 발급한 단기 토큰 · 저장 안 함',
                      'Short-lived sign-in token · not saved',
                    ),
                  ),
                ),
                Text(
                  tr(
                    '서버와 음성 인식 모델이 준비되어야 AI 분석을 사용할 수 있어요. 녹음·듣기는 인터넷 없이 됩니다.',
                    'AI requires a configured server and speech model. Recording and playback work offline.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _takeCard(Map<String, dynamic> take, bool en) {
    final a = jsonDecode(take['assessment'] as String) as Map<String, dynamic>;
    final active = _analyses.containsKey(take['id']);
    final envelope = (jsonDecode(take['envelope'] as String) as List)
        .map((v) => (v as num).toDouble())
        .toList();
    final maxDuration = _takes.fold<int>(
      0,
      (longest, item) => (item['duration'] as int) > longest
          ? item['duration'] as int
          : longest,
    );
    final alignedEnvelope = List<double>.of(envelope);
    if (envelope.isNotEmpty && (take['duration'] as int) > 0) {
      final bins = (envelope.length * maxDuration / (take['duration'] as int))
          .ceil();
      alignedEnvelope.addAll(List.filled(bins - envelope.length, 0));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${(take['slot'] as int) + 1}${tr('차 녹음', ' · Recording')} · ${((take['duration'] as int) / 1000).toStringAsFixed(1)} s',
            ),
            OutlinedButton.icon(
              onPressed: _recording || _busy ? null : () => _play([take]),
              icon: const Icon(Icons.play_arrow),
              label: Text(tr('이 녹음 듣기', 'Listen to this recording')),
            ),
            if (_wave)
              PracticeWaveform(
                values: alignedEnvelope,
                durationMs: maxDuration,
                english: en,
              ),
            ExpansionTile(
              title: Text(
                '${tr('AI 피드백', 'AI feedback')} · ${assessmentLabel(a['status'] as String, en)}',
              ),
              children: [
                if (a['transcript'] != null)
                  SelectableText(
                    '${tr('AI가 인식한 글', 'AI transcript')}: ${a['transcript']}',
                  ),
                if (a['observations'] is List)
                  for (final o in a['observations'] as List)
                    Text(
                      '${o['kind'] == 'duration'
                          ? tr('녹음 길이', 'Recording length')
                          : o['kind'] == 'lowEnergyPauses'
                          ? tr('조용한 구간 수 (참고)', 'Low-energy gaps (reference)')
                          : o['kind']}: ${o['value']} ${o['unit'] ?? ''}',
                    ),
                if (a['transcriptDifferences'] is List)
                  for (final difference in a['transcriptDifferences'] as List)
                    Text(
                      '${tr('문장', 'Target')}: ${difference['target']} → ${tr('인식', 'Recognized')}: ${difference['recognized']}',
                    ),
                if (a['nextPracticeTip'] != null)
                  Text(a['nextPracticeTip'] as String),
                if (a['unavailableReason'] != null)
                  Text(
                    '${tr('분석 상태', 'Analysis status')}: ${switch (a['unavailableReason']) {
                      'too_short' => tr('녹음이 너무 짧아요', 'Recording is too short'),
                      'too_quiet' => tr('소리가 너무 작아 분석하기 어려워요', 'Audio is too quiet to analyze'),
                      'clipping' => tr('녹음이 찌그러져 분석하기 어려워요', 'Audio is heavily clipped'),
                      'no_transcript' => tr('인식된 글이 없어요', 'No transcript was recognized'),
                      _ => tr('분석하지 못했어요. 나중에 다시 시도하세요', 'Analysis failed. Try again later'),
                    }}',
                  ),
                Text(
                  tr(
                    '인식된 글이 다르다고 발음이 틀렸다는 뜻은 아니에요. 진단이나 발음 정확도 점수가 아닙니다.',
                    'Recognition differences are not necessarily pronunciation errors. This is not diagnosis or an accuracy score.',
                  ),
                ),
                if (a['status'] != 'completed')
                  TextButton(
                    onPressed: _recording || _busy || active
                        ? null
                        : () => _analyze(take),
                    child: Text(
                      tr('동의 후 AI 분석', 'Request AI analysis with consent'),
                    ),
                  ),
                if (active)
                  TextButton(
                    onPressed: () => _analyses[take['id']]?.cancel('cancelled'),
                    child: Text(tr('분석 대기 중지', 'Stop waiting')),
                  ),
                if (a['remoteJobId'] != null && !active)
                  TextButton(
                    onPressed: () => _cleanup(take),
                    child: Text(tr('서버 작업 정리', 'Clear remote job')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
