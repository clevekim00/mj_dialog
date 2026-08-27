import 'dart:math';

import 'package:flutter/material.dart';
import 'package:speech_rehab/features/consonant_training/data/consonant_content_repository.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_history_service.dart';
import 'package:speech_rehab/features/consonant_training/services/pronunciation_analysis_client.dart';
import 'package:speech_rehab/services/audio/audio_player_service.dart';
import 'package:speech_rehab/services/audio/audio_recorder_service.dart';
import 'package:speech_rehab/services/audio/tts_service.dart';

class ConsonantTrainingHubScreen extends StatefulWidget {
  const ConsonantTrainingHubScreen({
    super.key,
    this.repository,
    this.historyService,
  });

  final ConsonantContentRepository? repository;
  final ConsonantTrainingHistoryService? historyService;

  @override
  State<ConsonantTrainingHubScreen> createState() =>
      _ConsonantTrainingHubScreenState();
}

class _ConsonantTrainingHubScreenState
    extends State<ConsonantTrainingHubScreen> {
  ConsonantContentRepository? _repository;
  late final ConsonantTrainingHistoryService _historyService;
  Future<PronunciationContentPack>? _packFuture;
  String? _loadedLanguage;
  PhonemePosition _position = PhonemePosition.onset;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _historyService =
        widget.historyService ?? ConsonantTrainingHistoryService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final languageTag = locale.languageCode == 'ko' ? 'ko-KR' : 'en-US';
    if (_packFuture != null && _loadedLanguage == languageTag) return;
    _loadedLanguage = languageTag;
    _repository =
        widget.repository ??
        ConsonantContentRepository(languageTag: languageTag);
    _packFuture = _repository!.load();
    _refreshInBackground();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자음 집중 훈련'),
        actions: [
          IconButton(
            tooltip: '훈련 기록',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConsonantTrainingHistoryScreen(
                  historyService: _historyService,
                ),
              ),
            ),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: '콘텐츠 업데이트',
            onPressed: _updating ? null : _updateContent,
            icon: _updating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_outlined),
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
            return _ErrorView(onRetry: _reload);
          }
          final pack = snapshot.data!;
          final isEnglish = pack.language == 'en-US';
          final targets = pack.targets
              .where((target) => target.position == _position)
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                '어려운 자음을 골라 음절 → 단어 → 짧은 문장 순서로 연습하세요.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '콘텐츠 ${pack.version} · ${pack.source == 'bundled' ? '오프라인 내장본' : '업데이트본'}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
              SegmentedButton<PhonemePosition>(
                segments: [
                  ButtonSegment(
                    value: PhonemePosition.onset,
                    label: Text(isEnglish ? 'Initial' : '초성'),
                  ),
                  if (isEnglish)
                    const ButtonSegment(
                      value: PhonemePosition.medial,
                      label: Text('Medial'),
                    ),
                  ButtonSegment(
                    value: PhonemePosition.coda,
                    label: Text(isEnglish ? 'Final' : '받침'),
                  ),
                ],
                selected: {_position},
                onSelectionChanged: (value) =>
                    setState(() => _position = value.first),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisExtent: 120,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: targets.length,
                itemBuilder: (context, index) {
                  final target = targets[index];
                  return _TargetCard(
                    target: target,
                    sentenceCount: pack
                        .itemsFor(target.id, ConsonantTrainingLevel.sentence)
                        .length,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsonantTrainingScreen(
                          pack: pack,
                          target: target,
                          historyService: _historyService,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const _ClinicalNotice(),
            ],
          );
        },
      ),
    );
  }

  void _reload() => setState(() => _packFuture = _repository!.load());

  Future<void> _refreshInBackground() async {
    if (_repository!.manifestUrl.trim().isEmpty) return;
    try {
      final result = await _repository!.updateIfAvailable();
      if (mounted && result.updated) _reload();
    } catch (_) {
      // 네트워크가 없어도 내장 콘텐츠로 훈련을 계속합니다.
    }
  }

  Future<void> _updateContent() async {
    setState(() => _updating = true);
    try {
      final result = await _repository!.updateIfAvailable();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      if (result.updated) _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('업데이트하지 못했습니다: $error')));
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
    this.analysisClient,
    this.recorder,
    this.player,
    this.tts,
  });

  final PronunciationContentPack pack;
  final ConsonantTrainingTarget target;
  final ConsonantTrainingHistoryService historyService;
  final PronunciationAnalysisClient? analysisClient;
  final AudioRecorderService? recorder;
  final AudioPlayerService? player;
  final TtsService? tts;

  @override
  State<ConsonantTrainingScreen> createState() =>
      _ConsonantTrainingScreenState();
}

class _ConsonantTrainingScreenState extends State<ConsonantTrainingScreen> {
  late final PronunciationAnalysisClient _analysisClient;
  late final AudioRecorderService _recorder;
  late final AudioPlayerService _player;
  late final TtsService _tts;
  ConsonantTrainingLevel _level = ConsonantTrainingLevel.syllable;
  int _index = 0;
  int _fatigue = 2;
  bool _recording = false;
  bool _analyzing = false;
  String? _recordingPath;
  PronunciationAnalysisResult? _result;

  List<PronunciationContentItem> get _items =>
      widget.pack.itemsFor(widget.target.id, _level);
  List<ConsonantTrainingLevel> get _availableLevels => ConsonantTrainingLevel
      .values
      .where(
        (level) => widget.pack.itemsFor(widget.target.id, level).isNotEmpty,
      )
      .toList(growable: false);
  PronunciationContentItem get _item => _items[_index % _items.length];

  @override
  void initState() {
    super.initState();
    _analysisClient = widget.analysisClient ?? PronunciationAnalysisClient();
    _recorder = widget.recorder ?? AudioRecorderService();
    _player = widget.player ?? AudioPlayerService();
    _tts = widget.tts ?? TtsService(languageTag: widget.pack.language);
    if (_items.isEmpty && _availableLevels.isNotEmpty) {
      _level = _availableLevels.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.target.grapheme} 발음 훈련')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            SegmentedButton<ConsonantTrainingLevel>(
              segments: _availableLevels
                  .map(
                    (level) => ButtonSegment(
                      value: level,
                      label: Text(
                        widget.pack.language == 'en-US'
                            ? switch (level) {
                                ConsonantTrainingLevel.syllable => 'Syllable',
                                ConsonantTrainingLevel.word => 'Word',
                                ConsonantTrainingLevel.sentence => 'Sentence',
                              }
                            : level.label,
                      ),
                    ),
                  )
                  .toList(),
              selected: {_level},
              onSelectionChanged: (value) => setState(() {
                _level = value.first;
                _index = 0;
                _result = null;
                _recordingPath = null;
              }),
            ),
            const SizedBox(height: 24),
            Text(
              '${_index + 1} / ${_items.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _item.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: _level == ConsonantTrainingLevel.sentence
                          ? 26
                          : 48,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${widget.target.position.label} ${widget.target.grapheme} · 천천히 또렷하게',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _tts.speak(_item.text),
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('기준 발음 듣기'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: _recording ? Colors.redAccent : null,
              ),
              onPressed: _analyzing ? null : (_recording ? _stop : _start),
              icon: Icon(_recording ? Icons.stop : Icons.mic),
              label: Text(_recording ? '녹음 끝내고 분석' : '따라 읽고 녹음'),
            ),
            if (_analyzing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                '음소 구간을 분석하고 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ],
            if (_recordingPath != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _player.playFile(_recordingPath!),
                icon: const Icon(Icons.play_arrow),
                label: const Text('내 발음 다시 듣기'),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 18),
              _AnalysisCard(result: _result!),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('현재 피로도', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    value: _fatigue.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_fatigue',
                    onChanged: (value) =>
                        setState(() => _fatigue = value.round()),
                  ),
                ),
                Text('$_fatigue/5'),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _repeat,
                    child: const Text('다시 연습'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _next,
                    child: const Text('다음'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _ClinicalNotice(),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('마이크 권한이 필요합니다.')));
      return;
    }
    await _recorder.startRecording(
      'consonant_${widget.target.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (mounted) setState(() => _recording = true);
  }

  Future<void> _stop() async {
    final path = await _recorder.stopRecording();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _recordingPath = path;
      _analyzing = path != null;
      _result = null;
    });
    if (path == null) return;

    final attempts = await widget.historyService.load();
    final baseline = widget.historyService.baselineFor(
      attempts,
      widget.target.id,
      language: widget.pack.language,
    );
    final result = await _analysisClient.analyze(
      audioFilePath: path,
      item: _item,
      target: widget.target,
      contentVersion: widget.pack.version,
      language: widget.pack.language,
      baselineScore: baseline?.medianScore,
    );
    final attempt = ConsonantTrainingAttempt(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
      targetId: widget.target.id,
      contentId: _item.id,
      text: _item.text,
      level: _level,
      audioFilePath: path,
      createdAt: DateTime.now(),
      analysis: result,
    );
    await widget.historyService.add(attempt);
    if (mounted) {
      setState(() {
        _result = result;
        _analyzing = false;
      });
    }
  }

  void _repeat() => setState(() {
    _result = null;
    _recordingPath = null;
  });

  void _next() => setState(() {
    _index = (_index + 1) % _items.length;
    _result = null;
    _recordingPath = null;
  });

  @override
  void dispose() {
    _player.stop();
    _tts.dispose();
    _recorder.dispose();
    super.dispose();
  }
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
      appBar: AppBar(title: const Text('자음 훈련 기록')),
      body: FutureBuilder<List<ConsonantTrainingAttempt>>(
        future: historyService.load(),
        builder: (context, snapshot) {
          final attempts = snapshot.data ?? const <ConsonantTrainingAttempt>[];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (attempts.isEmpty) {
            return const Center(child: Text('아직 저장된 자음 훈련이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: attempts.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final score = attempt.analysis.overallPracticeScore;
              return ListTile(
                title: Text('${attempt.text} · ${attempt.level.label}'),
                subtitle: Text(
                  '${attempt.createdAt.month}/${attempt.createdAt.day} · ${attempt.analysis.message ?? attempt.analysis.status.name}',
                ),
                trailing: Text(score == null ? '분석 없음' : '$score점'),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              target.grapheme,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            Text(
              '${target.position.label} · 문장 $sentenceCount개',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
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
    final score = result.overallPracticeScore;
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
                ? '음소 분석을 사용할 수 없어요'
                : '연습 점수 $score점',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            result.message ??
                (result.phonemes.isEmpty
                    ? '녹음은 저장되었습니다. 분석 서버 설정을 확인해 주세요.'
                    : result.phonemes
                          .map(
                            (phone) => phone.practiceScore == null
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
