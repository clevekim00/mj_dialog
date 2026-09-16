import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_rehab/features/consonant_training/data/consonant_content_repository.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_history_service.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_session_service.dart';
import 'package:speech_rehab/features/consonant_training/services/pronunciation_analysis_client.dart';
import 'package:speech_rehab/services/audio/audio_player_service.dart';
import 'package:speech_rehab/services/audio/audio_recorder_service.dart';
import 'package:speech_rehab/services/audio/tts_service.dart';

class ConsonantTrainingHubScreen extends StatefulWidget {
  const ConsonantTrainingHubScreen({
    super.key,
    this.repository,
    this.historyService,
    this.sessionService,
    this.autoResume = false,
  });
  final ConsonantContentRepository? repository;
  final ConsonantTrainingHistoryService? historyService;
  final ConsonantTrainingSessionService? sessionService;
  final bool autoResume;

  @override
  State<ConsonantTrainingHubScreen> createState() =>
      _ConsonantTrainingHubScreenState();
}

class _ConsonantTrainingHubScreenState
    extends State<ConsonantTrainingHubScreen> {
  late final _history =
      widget.historyService ?? ConsonantTrainingHistoryService();
  late final _sessions =
      widget.sessionService ?? ConsonantTrainingSessionService();
  ConsonantContentRepository? _repository;
  Future<PronunciationContentPack>? _packFuture;
  ConsonantTrainingProgress? _progress;
  String? _language;
  PhonemePosition _position = PhonemePosition.onset;
  bool _updating = false;
  bool _autoResumed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode == 'ko'
        ? 'ko-KR'
        : 'en-US';
    if (_language == language) return;
    _language = language;
    _repository =
        widget.repository ?? ConsonantContentRepository(languageTag: language);
    _packFuture = _load();
  }

  Future<PronunciationContentPack> _load() async {
    final pack = await _repository!.load();
    _progress = await _sessions.load(language: pack.language);
    if (_progress != null) _position = _progress!.position;
    if (widget.autoResume && !_autoResumed && _progress?.completed == false) {
      _autoResumed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resume(pack);
      });
    }
    return pack;
  }

  Future<void> _open(
    PronunciationContentPack pack,
    ConsonantTrainingTarget target, {
    ConsonantTrainingProgress? progress,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ConsonantTrainingScreen(
          pack: pack,
          target: target,
          historyService: _history,
          sessionService: _sessions,
          initialProgress: progress,
        ),
      ),
    );
    final latest = await _sessions.load(language: pack.language);
    if (mounted) setState(() => _progress = latest);
  }

  void _resume(PronunciationContentPack pack) {
    final matches = pack.targets.where(
      (target) => target.id == _progress?.targetId,
    );
    if (matches.isNotEmpty) _open(pack, matches.first, progress: _progress);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('자음 골라 연습하기'),
      actions: [
        IconButton(
          tooltip: '훈련 기록',
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  ConsonantTrainingHistoryScreen(historyService: _history),
            ),
          ),
        ),
        IconButton(
          tooltip: '콘텐츠 업데이트',
          icon: const Icon(Icons.cloud_download_outlined),
          onPressed: _updating ? null : _updateContent,
        ),
      ],
    ),
    body: FutureBuilder<PronunciationContentPack>(
      future: _packFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return _ErrorView(
            onRetry: () => setState(() => _packFuture = _load()),
          );
        }
        final pack = snapshot.data!;
        final targets = pack.targets
            .where((target) => target.position == _position)
            .toList();
        final recentAvailable = pack.targets.any(
          (target) => target.id == _progress?.targetId,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const Text(
              '연습할 자음과 위치를 고르세요. 음절, 단어, 짧은 문장으로 연습할 수 있어요.',
              style: TextStyle(fontSize: 18),
            ),
            if (recentAvailable) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                onPressed: () => _resume(pack),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  '${_progress!.grapheme} ${_progress!.position.label} · ${_progress!.level.label} ${_progress!.completed ? '다시 연습' : '이어하기'}',
                ),
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final position in [
                  PhonemePosition.onset,
                  if (pack.language == 'en-US') PhonemePosition.medial,
                  PhonemePosition.coda,
                ])
                  SizedBox(
                    width: pack.language == 'en-US' ? 140 : 156,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(72),
                        backgroundColor: _position == position
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        side: _position == position
                            ? BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      onPressed: () => setState(() => _position = position),
                      child: Text(
                        pack.language == 'en-US'
                            ? switch (position) {
                                PhonemePosition.onset => 'Initial',
                                PhonemePosition.medial => 'Medial',
                                PhonemePosition.coda => 'Final',
                              }
                            : position.label,
                        style: const TextStyle(fontSize: 21),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final target in targets)
                  SizedBox(
                    width: 150,
                    child: _TargetCard(
                      target: target,
                      sentenceCount: pack
                          .itemsFor(target.id, ConsonantTrainingLevel.sentence)
                          .length,
                      onTap: () => _open(pack, target),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const _ClinicalNotice(),
          ],
        );
      },
    ),
  );

  Future<void> _updateContent() async {
    setState(() => _updating = true);
    try {
      final result = await _repository!.updateIfAvailable();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      if (result.updated) setState(() => _packFuture = _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('콘텐츠를 업데이트하지 못했어요. 저장된 자료로 계속 연습할 수 있어요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class ConsonantTrainingScreen extends StatefulWidget {
  const ConsonantTrainingScreen({
    super.key,
    required this.pack,
    required this.target,
    required this.historyService,
    this.sessionService,
    this.initialProgress,
    this.analysisClient,
    this.recorder,
    this.player,
    this.tts,
  });
  final PronunciationContentPack pack;
  final ConsonantTrainingTarget target;
  final ConsonantTrainingHistoryService historyService;
  final ConsonantTrainingSessionService? sessionService;
  final ConsonantTrainingProgress? initialProgress;
  final PronunciationAnalysisClient? analysisClient;
  final AudioRecorderService? recorder;
  final AudioPlayerService? player;
  final TtsService? tts;

  @override
  State<ConsonantTrainingScreen> createState() =>
      _ConsonantTrainingScreenState();
}

class _ConsonantTrainingScreenState extends State<ConsonantTrainingScreen>
    with WidgetsBindingObserver {
  late final _analysisClient =
      widget.analysisClient ?? PronunciationAnalysisClient();
  late final _recorder = widget.recorder ?? AudioRecorderService();
  late final _player = widget.player ?? AudioPlayerService();
  late final _tts = widget.tts ?? TtsService(languageTag: widget.pack.language);
  late final _sessions =
      widget.sessionService ?? ConsonantTrainingSessionService();
  ConsonantTrainingLevel _level = ConsonantTrainingLevel.syllable;
  int _index = 0;
  int _repetitions = 3;
  int _completedAttempts = 0;
  int? _fatigue;
  bool _recording = false;
  bool _saving = false;
  bool _analyzing = false;
  bool _complete = false;
  bool _saved = false;
  bool _analysisConsent = false;
  String? _notice;
  PronunciationContentItem? _recordedItem;
  ConsonantTrainingAttempt? _attempt;
  ConsonantTrainingAttempt? _previous;
  PronunciationAnalysisResult? _result;
  CancelToken? _cancelToken;
  int _operation = 0;
  bool get _locked => _recording || _saving || _analyzing;
  List<PronunciationContentItem> get _items =>
      widget.pack.itemsFor(widget.target.id, _level);
  List<ConsonantTrainingLevel> get _levels => ConsonantTrainingLevel.values
      .where(
        (level) => widget.pack.itemsFor(widget.target.id, level).isNotEmpty,
      )
      .toList();
  PronunciationContentItem get _item => _items[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final progress = widget.initialProgress;
    if (progress != null &&
        progress.targetId == widget.target.id &&
        progress.language == widget.pack.language) {
      _level = progress.level;
      _repetitions = progress.repetitions;
      _completedAttempts = progress.completed ? 0 : progress.completedAttempts;
    }
    if (!_levels.contains(_level) && _levels.isNotEmpty) _level = _levels.first;
    if (_items.isNotEmpty && progress != null) {
      final found = _items.indexWhere((item) => item.id == progress.contentId);
      _index = found >= 0
          ? found
          : progress.itemIndex.clamp(0, _items.length - 1);
    }
    if (_items.isNotEmpty) {
      unawaited(_saveProgress());
      unawaited(_loadPrevious());
    }
  }

  ConsonantTrainingProgress get _progress => ConsonantTrainingProgress(
    targetId: widget.target.id,
    grapheme: widget.target.grapheme,
    position: widget.target.position,
    level: _level,
    itemIndex: _index,
    repetitions: _repetitions,
    completedAttempts: _completedAttempts,
    completed: _complete,
    updatedAt: DateTime.now(),
    language: widget.pack.language,
    contentId: _item.id,
  );

  Future<void> _saveProgress() async {
    try {
      await _sessions.save(_progress);
    } catch (_) {
      if (mounted) setState(() => _notice = '이어하기 정보를 저장하지 못했어요.');
    }
  }

  Future<void> _loadPrevious() async {
    final item = _item;
    final previous = await widget.historyService.previousFor(
      targetId: widget.target.id,
      contentId: item.id,
      text: item.text,
      language: widget.pack.language,
      excludingId: _attempt?.id,
    );
    if (mounted && _item.id == item.id) setState(() => _previous = previous);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_recording && !_saving) unawaited(_stop());
      if (_analyzing) _cancelAnalysis();
      unawaited(_silence());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('자음 연습')),
        body: const Center(child: Text('이 자음의 연습 자료가 아직 없어요.')),
      );
    }
    return PopScope(
      canPop: !_locked,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('녹음을 저장하거나 분석을 취소한 뒤 나갈 수 있어요.')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.target.grapheme} ${widget.target.position.label} 연습',
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton.icon(
              key: const Key('consonant-record'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
                backgroundColor: _recording ? Colors.redAccent : null,
              ),
              onPressed: _saving || _analyzing || _complete
                  ? null
                  : (_recording ? _stop : _start),
              icon: Icon(_recording ? Icons.stop : Icons.mic),
              label: Text(
                _saving
                    ? '녹음 저장 중'
                    : _recording
                    ? '녹음 끝내고 저장'
                    : '따라 읽고 녹음',
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in _levels)
                    ChoiceChip(
                      label: Text(level.label),
                      selected: _level == level,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: _locked ? null : (_) => _changeLevel(level),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('이번 연습 목표 · 녹음 횟수'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final count in [3, 5, 10])
                    ChoiceChip(
                      label: Text('$count회'),
                      selected: _repetitions == count,
                      onSelected: _locked || _completedAttempts > 0
                          ? null
                          : (_) {
                              setState(() => _repetitions = count);
                              unawaited(_saveProgress());
                            },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$_completedAttempts / $_repetitions회 녹음',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              LinearProgressIndicator(value: _completedAttempts / _repetitions),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  children: [
                    Text(
                      '항목 ${_index + 1} / ${_items.length}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TargetPracticeText(
                      text: _item.text,
                      target: widget.target,
                      fontSize: _level == ConsonantTrainingLevel.sentence
                          ? 28
                          : 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.pack.language == 'ko-KR'
                          ? '밑줄은 선택한 자음의 연습 위치를 표시해요.'
                          : '${widget.target.grapheme} · ${widget.target.position.label}',
                      textAlign: TextAlign.center,
                    ),
                    if (widget.target.position == PhonemePosition.coda &&
                        widget.pack.language == 'ko-KR')
                      const Text(
                        '받침은 대표 소리 묶음으로 표시해요. 이어 읽을 때 소리가 달라질 수 있어요.',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _locked ? null : _playReference,
                icon: const Icon(Icons.volume_up_outlined),
                label: Text(
                  (_item.referenceAudioAsset?.isNotEmpty != true)
                      ? '예시 듣기 · TTS 합성 음성'
                      : '예시 녹음 듣기',
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 8),
              const Text(
                '녹음은 기기에 저장돼요. 분석 없이도 듣고 비교할 수 있어요.',
                textAlign: TextAlign.center,
              ),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_notice!, semanticsLabel: _notice),
                ),
              if (_attempt != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _locked
                      ? null
                      : () => _playRecording(_attempt!.audioFilePath),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('이번 녹음 듣기'),
                ),
                if (!_saved)
                  OutlinedButton(
                    onPressed: _locked ? null : _persistAttempt,
                    child: const Text('녹음 저장 다시 시도'),
                  ),
              ],
              if (_previous != null)
                OutlinedButton.icon(
                  onPressed: _locked
                      ? null
                      : () => _playRecording(_previous!.audioFilePath),
                  icon: const Icon(Icons.history),
                  label: const Text('이전 같은 항목 녹음 듣기'),
                ),
              if (_complete) ...[
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    '이번 연습을 마쳤어요 · $_completedAttempts회 녹음',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text('녹음 횟수는 연습량이며 발음 정확도 점수가 아니에요.'),
                FilledButton(
                  onPressed: _locked ? null : () => Navigator.pop(context),
                  child: const Text('완료하고 돌아가기'),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _locked ? null : _repeat,
                      child: const Text('같은 항목 다시 연습'),
                    ),
                    FilledButton.tonal(
                      onPressed: _locked ? null : _next,
                      child: const Text('다음 항목'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              const Text('현재 피로도 · 선택 사항'),
              Wrap(
                spacing: 8,
                children: [
                  for (var value = 1; value <= 5; value++)
                    ChoiceChip(
                      label: Text('$value'),
                      selected: _fatigue == value,
                      onSelected: _locked
                          ? null
                          : (_) => setState(
                              () => _fatigue = _fatigue == value ? null : value,
                            ),
                    ),
                ],
              ),
              const Text('1 편안함 · 5 많이 피곤함', style: TextStyle(fontSize: 12)),
              if (_attempt != null) ...[
                const SizedBox(height: 24),
                ExpansionTile(
                  key: const ValueKey('consonant-analysis'),
                  title: const Text('선택: 서버에서 음소 구간 분석'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    const Text(
                      '녹음 파일, 연습 문장, 선택 자음과 언어가 아래 분석 서버로 전송돼요. 자동 분석 결과는 발음 정확도 진단이 아니에요.',
                    ),
                    SelectableText('전송 대상: ${_analysisDestination()}'),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _analysisConsent,
                      onChanged: _locked
                          ? null
                          : (value) => setState(
                              () => _analysisConsent = value ?? false,
                            ),
                      title: const Text('이번 녹음을 이 서버로 보내는 데 동의해요'),
                    ),
                    if (_analyzing) ...[
                      const LinearProgressIndicator(),
                      TextButton(
                        onPressed: _cancelAnalysis,
                        child: const Text('분석 취소'),
                      ),
                    ] else
                      FilledButton.tonal(
                        onPressed: _locked || !_analysisConsent || !_saved
                            ? null
                            : _analyze,
                        child: const Text('동의한 녹음을 서버로 전송'),
                      ),
                    if (_result != null) _AnalysisCard(result: _result!),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              const _ClinicalNotice(),
            ],
          ),
        ),
      ),
    );
  }

  String _analysisDestination() {
    final uri = Uri.tryParse(_analysisClient.baseUrl);
    return uri == null || uri.host.isEmpty
        ? '설정되지 않음'
        : uri.replace(userInfo: '', query: '', fragment: '').toString();
  }

  Future<void> _silence() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _playReference() async {
    final item = _item;
    try {
      await _silence();
      if (!mounted || _locked || _item.id != item.id) return;
      final asset = item.referenceAudioAsset;
      if (asset == null || asset.isEmpty) {
        await _tts.speak(item.text);
      } else {
        if (!asset.startsWith('assets/') || asset.contains('..')) {
          throw const FormatException('Invalid audio asset');
        }
        final bytes = await rootBundle.load(asset);
        final directory = await getTemporaryDirectory();
        final suffix = asset.split('.').last;
        if (!RegExp(r'^(mp3|m4a|wav|aac)$').hasMatch(suffix)) {
          throw const FormatException('Unsupported audio asset');
        }
        final data = bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
        final file = File(
          '${directory.path}/consonant_reference_${sha256.convert(data)}.$suffix',
        );
        if (!await file.exists()) await file.writeAsBytes(data);
        if (mounted && !_locked && _item.id == item.id) {
          await _player.playFile(file.path);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _notice = '예시 음성을 재생하지 못했어요.');
    }
  }

  Future<void> _playRecording(String path) async {
    try {
      if (!await File(path).exists()) {
        throw const FileSystemException('Missing recording');
      }
      await _silence();
      if (mounted && !_locked) await _player.playFile(path);
    } catch (_) {
      if (mounted) {
        setState(() => _notice = '이 녹음 파일을 찾거나 재생할 수 없어요. 새로 녹음해 주세요.');
      }
    }
  }

  Future<void> _start() async {
    if (_locked || _complete) return;
    // Capture before any await. Controls stay locked until the file is saved.
    final item = _item;
    setState(() {
      _saving = true;
      _notice = null;
    });
    try {
      await _silence();
      if (!await _recorder.hasPermission()) {
        if (mounted) setState(() => _notice = '녹음하려면 마이크 권한이 필요해요.');
        return;
      }
      await _saveProgress();
      await _recorder.startRecording(
        'consonant_${widget.target.id}_${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!mounted) return;
      setState(() {
        _recordedItem = item;
        _recording = true;
        _analysisConsent = false;
        _result = null;
      });
    } catch (_) {
      if (mounted) setState(() => _notice = '녹음을 시작하지 못했어요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _stop() async {
    if (!_recording || _saving) return;
    final item = _recordedItem!;
    final fatigue = _fatigue;
    setState(() => _saving = true);
    try {
      final path = await _recorder.stopRecording();
      if (!mounted) return;
      setState(() => _recording = false);
      if (path == null || path.isEmpty) {
        setState(() => _notice = '녹음 파일을 저장하지 못했어요. 다시 녹음해 주세요.');
        return;
      }
      _attempt = ConsonantTrainingAttempt(
        id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
        targetId: widget.target.id,
        contentId: item.id,
        text: item.text,
        level: item.level,
        audioFilePath: path,
        createdAt: DateTime.now(),
        language: widget.pack.language,
        fatigue: fatigue,
        analysis: PronunciationAnalysisResult.unavailable(
          '기기에 저장한 녹음이에요. 서버 분석을 요청하지 않았어요.',
        ),
      );
      _saved = false;
      await _persistAttempt();
      await _loadPrevious();
    } catch (_) {
      if (mounted) {
        setState(() {
          _recording = false;
          _notice = '녹음을 저장하지 못했어요. 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persistAttempt() async {
    if (_attempt == null || _saved) return;
    setState(() => _saving = true);
    try {
      await widget.historyService.add(_attempt!);
      if (!mounted) return;
      setState(() {
        _saved = true;
        _completedAttempts++;
        _complete = _completedAttempts >= _repetitions;
        _notice = '녹음을 기기에 저장했어요.';
      });
      await _saveProgress();
    } catch (_) {
      if (mounted) setState(() => _notice = '녹음 보관에 실패했어요. 저장을 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _analyze() async {
    if (_locked || !_analysisConsent || _attempt == null || !_saved) return;
    final attempt = _attempt!;
    final item = _item;
    final token = CancelToken();
    final operation = ++_operation;
    setState(() {
      _analyzing = true;
      _cancelToken = token;
      _notice = null;
    });
    try {
      await _silence();
      final result = await _analysisClient.analyze(
        audioFilePath: attempt.audioFilePath,
        item: item,
        target: widget.target,
        contentVersion: widget.pack.version,
        language: widget.pack.language,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled || operation != _operation) return;
      final updated = attempt.withAnalysis(result);
      await widget.historyService.add(updated);
      if (!mounted || token.isCancelled || operation != _operation) return;
      setState(() {
        _attempt = updated;
        _result = result;
      });
    } catch (_) {
      if (mounted && operation == _operation) {
        setState(() => _notice = '분석을 완료하지 못했어요. 기기에 저장된 녹음은 다시 들을 수 있어요.');
      }
    } finally {
      if (mounted && operation == _operation) {
        setState(() {
          _analyzing = false;
          _cancelToken = null;
        });
      }
    }
  }

  void _cancelAnalysis() {
    _operation++;
    _cancelToken?.cancel('사용자가 분석을 취소했습니다.');
    setState(() {
      _analyzing = false;
      _cancelToken = null;
      _notice = '분석을 취소했어요. 녹음은 기기에 남아 있어요.';
    });
  }

  void _changeLevel(ConsonantTrainingLevel level) {
    if (_locked || level == _level) return;
    setState(() {
      _level = level;
      _index = 0;
      _completedAttempts = 0;
      _complete = false;
      _clearAttempt();
    });
    unawaited(_silence());
    unawaited(_saveProgress());
    unawaited(_loadPrevious());
  }

  void _clearAttempt() {
    _attempt = null;
    _previous = null;
    _result = null;
    _analysisConsent = false;
    _notice = null;
    _saved = false;
  }

  void _repeat() {
    if (_locked) return;
    setState(_clearAttempt);
    unawaited(_silence());
    unawaited(_loadPrevious());
  }

  void _next() {
    if (_locked) return;
    setState(() {
      _index = (_index + 1) % _items.length;
      _clearAttempt();
    });
    unawaited(_silence());
    unawaited(_saveProgress());
    unawaited(_loadPrevious());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _operation++;
    _cancelToken?.cancel('화면을 닫았습니다.');
    unawaited(_silence());
    _tts.dispose();
    _recorder.dispose();
    super.dispose();
  }
}

/// Marks the written target syllables, without claiming an acoustic assessment.
class TargetPracticeText extends StatelessWidget {
  const TargetPracticeText({
    super.key,
    required this.text,
    required this.target,
    this.fontSize = 32,
  });
  final String text;
  final ConsonantTrainingTarget target;
  final double fontSize;

  static bool matches(String character, ConsonantTrainingTarget target) {
    final code = character.runes.first;
    if (code < 0xAC00 || code > 0xD7A3) return false;
    const onsets = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
    const codas = ' ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ';
    final offset = code - 0xAC00;
    if (target.position == PhonemePosition.onset) {
      return onsets[offset ~/ 588] == target.grapheme;
    }
    if (target.position != PhonemePosition.coda) return false;
    const groups = {
      'ㄱ': 'ㄱㄲㅋ',
      'ㄴ': 'ㄴ',
      'ㄷ': 'ㄷㅅㅆㅈㅊㅌㅎ',
      'ㄹ': 'ㄹ',
      'ㅁ': 'ㅁ',
      'ㅂ': 'ㅂㅍ',
      'ㅇ': 'ㅇ',
    };
    return groups[target.grapheme]?.contains(codas[offset % 28]) ?? false;
  }

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        for (final rune in text.runes)
          TextSpan(
            text: String.fromCharCode(rune),
            style: matches(String.fromCharCode(rune), target)
                ? TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                  )
                : null,
          ),
      ],
    ),
    semanticsLabel: text,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800),
  );
}

class ConsonantTrainingHistoryScreen extends StatelessWidget {
  const ConsonantTrainingHistoryScreen({
    super.key,
    required this.historyService,
  });

  final ConsonantTrainingHistoryService historyService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자음 연습 기록')),
      body: FutureBuilder<List<ConsonantTrainingAttempt>>(
        future: historyService.load(),
        builder: (context, snapshot) {
          final attempts = snapshot.data ?? const <ConsonantTrainingAttempt>[];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (attempts.isEmpty) {
            return const Center(child: Text('아직 저장된 자음 연습이 없어요.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: attempts.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final score = attempt.analysis.hasReliableScore
                  ? attempt.analysis.overallPracticeScore
                  : null;
              return ListTile(
                title: Text('${attempt.text} · ${attempt.level.label}'),
                subtitle: Text(
                  '${attempt.createdAt.month}/${attempt.createdAt.day} · ${attempt.analysis.message ?? attempt.analysis.status.name}',
                ),
                trailing: Text(score == null ? '녹음 보관' : '$score점'),
              );
            },
          );
        },
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.target,
    required this.sentenceCount,
    required this.onTap,
  });

  final ConsonantTrainingTarget target;
  final int sentenceCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${target.grapheme} ${target.position.label} 연습',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                target.grapheme,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${target.position.label} · 문장 $sentenceCount개',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.result});

  final PronunciationAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final score = result.hasReliableScore ? result.overallPracticeScore : null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            score == null && result.phonemes.isNotEmpty
                ? '음소 구간 정렬 완료'
                : score == null
                ? '점수 없이 녹음을 보관했어요'
                : '연습 점수 $score점',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            result.message ??
                (result.phonemes.isEmpty
                    ? '기기에 저장된 녹음을 다시 들을 수 있어요.'
                    : result.phonemes
                          .map(
                            (phone) =>
                                !result.hasReliableScore ||
                                    phone.practiceScore == null
                                ? '${phone.expectedPhone}${phone.alignedPhone == null ? '' : ' → ${phone.alignedPhone}'}: ${phone.startMs}–${phone.endMs}ms 구간'
                                : '${phone.expectedPhone}: ${phone.practiceScore}점 (${phone.status.name})',
                          )
                          .join('\n')),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            result.disclaimer,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ClinicalNotice extends StatelessWidget {
  const _ClinicalNotice();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '이 기능은 성인 후천성 마비말장애의 반복 훈련을 돕는 보조 도구이며, 진단이나 치료사의 임상 판단을 대신하지 않습니다. 피로하거나 통증이 있으면 쉬어 주세요.',
      style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.45),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('훈련 콘텐츠를 불러오지 못했습니다.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
