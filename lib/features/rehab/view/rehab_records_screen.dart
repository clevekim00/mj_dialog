import '../mpt/mpt_result.dart';
import 'dart:async';
import '../audio/practice_waveform.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_rehab/services/audio/audio_player_service.dart';
import '../services/rehab_record_index.dart';
import '../services/rehab_session_repository.dart';
import '../model/rehab_session.dart';
import 'rehab_ui.dart';
import 'rehab_setup_screen.dart';

String recordStatus(String status, bool en) => switch (status) {
  'voicePlay' => en ? 'Voice play saved' : '발성 놀이 저장',
  'completed' => en ? 'Completed' : '완료',
  'partial' => en ? 'Partly completed' : '일부 완료',
  'paused' || 'inProgress' => en ? 'Can continue' : '이어서 가능',
  'stopped' => en ? 'Stopped' : '중단',
  'conversation' =>
    en ? 'Conversation · input methods recorded' : '대화 · 입력 방식 별도 기록',
  'measurement' => en ? 'Reference measurement' : '참고 측정',
  _ => en ? 'Earlier individual practice' : '이전 개별 연습',
};
String recordKind(String kind, bool en) => switch (kind) {
  'mpt' => en ? 'MPT measurement' : 'MPT 측정',
  'game' => en ? 'Voice play' : '발성 놀이',
  'daily' => en ? 'Daily practice' : '오늘의 연습',
  'consonant' => en ? 'Consonant' : '자음',
  'guided' => en ? 'Guided training' : '구강·호흡',
  'voice' => en ? 'Voice' : '음성',
  'chat' => en ? 'Conversation' : '대화',
  _ => en ? 'Words / sentences' : '단어·문장',
};

class RehabRecordsScreen extends ConsumerStatefulWidget {
  const RehabRecordsScreen({super.key});
  @override
  ConsumerState<RehabRecordsScreen> createState() => _RecordsState();
}

class _RecordsState extends ConsumerState<RehabRecordsScreen> {
  late Future<List<RehabRecord>> _records;
  String? _date;
  String _kind = 'all';
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _records = RehabRecordIndex(
      daily: ref.read(rehabRepositoryProvider),
    ).load();
  }

  Future<void> _open(RehabRecord record, List<RehabRecord> all) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RehabRecordDetail(record: record, all: all),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final l = rehabL10n(context), en = rehabEnglish(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.rehabRecords),
        actions: [
          IconButton(
            tooltip: l.rehabRetry,
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<RehabRecord>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.rehabLoadingError),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: Text(l.rehabRetry),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final visible = all
              .where(
                (r) =>
                    (_date == null || r.dateKey == _date) &&
                    (_kind == 'all' || r.kind == _kind),
              )
              .toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final kind in [
                        'all',
                        'daily',
                        'practice',
                        'consonant',
                        'guided',
                        'voice',
                        'chat',
                        'game',
                        'mpt',
                      ])
                        ChoiceChip(
                          label: Text(
                            kind == 'all' ? l.rehabAll : recordKind(kind, en),
                          ),
                          selected: _kind == kind,
                          onSelected: (_) => setState(() => _kind = kind),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(_date ?? l.rehabCalendar),
                        onPressed: () async {
                          final keys = all.map((r) => r.dateKey).toList()
                            ..sort();
                          final now = DateTime.now();
                          final first = keys.isEmpty
                              ? DateTime(now.year - 1)
                              : DateTime.parse(keys.first);
                          final lastStored = keys.isEmpty
                              ? now
                              : DateTime.parse(keys.last);
                          final last = lastStored.isAfter(now)
                              ? lastStored
                              : now;
                          final initial = _date == null
                              ? now
                              : DateTime.parse(_date!);
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: first.isAfter(initial) ? initial : first,
                            lastDate: last,
                            selectableDayPredicate: (day) =>
                                keys.isEmpty ||
                                keys.contains(rehabDate(day)) ||
                                rehabDate(day) == rehabDate(initial),
                          );
                          if (selected != null && mounted) {
                            setState(() => _date = rehabDate(selected));
                          }
                        },
                      ),
                      if (_date != null)
                        TextButton(
                          onPressed: () => setState(() => _date = null),
                          child: Text(l.rehabClearDate),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    en
                        ? '${visible.length} records · ${visible.expand((r) => r.recordings).length} recordings'
                        : '${visible.length}개 기록 · 녹음 ${visible.expand((r) => r.recordings).length}개',
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(l.rehabEmpty),
                    ),
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i == 0 || visible[i - 1].dateKey != visible[i].dateKey)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          visible[i].dateKey,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    RehabCard(
                      title: visible[i].title,
                      subtitle:
                          '${recordKind(visible[i].kind, en)} · ${recordStatus(visible[i].status, en)}',
                      icon: Icons.history,
                      onTap: () => _open(visible[i], all),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RehabRecordDetail extends ConsumerStatefulWidget {
  const RehabRecordDetail({super.key, required this.record, required this.all});
  final RehabRecord record;
  final List<RehabRecord> all;
  @override
  ConsumerState<RehabRecordDetail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<RehabRecordDetail>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_stop());
  }

  Future<void> _stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  AudioPlayerService? _player;
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stop());
    super.dispose();
  }

  Future<void> _play(String path) async {
    try {
      _player ??= ref.read(audioPlayerServiceProvider);
      await _player!.stop();
      await _player!.playFile(path);
    } catch (_) {
      if (mounted) setState(() => _error = rehabL10n(context).rehabAudioError);
    }
  }

  Future<void> _delete() async {
    final l = rehabL10n(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.rehabDelete),
        content: Text(l.rehabDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.rehabCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.rehabDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _player?.stop();
      final cleaned = await ref
          .read(rehabRepositoryProvider)
          .delete(widget.record.daily!.id);
      ref.invalidate(rehabSessionsProvider);
      if (mounted) {
        if (!cleaned) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                rehabEnglish(context)
                    ? 'Record removed. Some audio files could not be removed from this device.'
                    : '기록은 삭제됐지만 일부 녹음 파일을 기기에서 지우지 못했어요.',
              ),
            ),
          );
        }
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l.rehabSaveError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = rehabL10n(context), en = rehabEnglish(context), r = widget.record;
    return PopScope(
      canPop: !_busy,
      child: RehabPage(
        title: l.rehabDetails,
        children: [
          Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('${r.dateKey} · ${recordStatus(r.status, en)}'),
          const SizedBox(height: 12),
          Text(l.rehabUnscored),
          if (r.daily?.feedback['kind'] == 'mpt')
            Text(MptResult.summary(r.daily!.feedback, en)),
          if (r.daily?.feedback['kind'] == 'voiceFlight')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                (r.daily!.feedback['longestDetectedMs'] as num? ?? 0) <= 0
                    ? (en
                          ? 'No reliable voice segment detected. Not an MPT result.'
                          : '확실하게 검출된 발성 구간이 없어요. MPT 결과가 아니에요.')
                    : en
                    ? 'Voice play: longest detected segment ${((r.daily!.feedback['longestDetectedMs'] as num) / 1000).toStringAsFixed(1)} s (estimate). Not MPT.'
                    : '발성 놀이: 가장 긴 검출 구간 ${((r.daily!.feedback['longestDetectedMs'] as num) / 1000).toStringAsFixed(1)}초 (추정). MPT가 아니에요.',
              ),
            ),
          if (r.fatigueBefore != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${l.rehabFatigue}: ${r.fatigueBefore}/5 → ${r.fatigueAfter == null ? '—' : '${r.fatigueAfter}/5'}',
              ),
            ),
          if (_error != null) Text(_error!),
          for (final recording in r.recordings)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(recording.text),
                    if (r.daily != null &&
                        r.daily!.takes
                            .where(
                              (t) =>
                                  t.path == recording.path &&
                                  t.waveform.isNotEmpty,
                            )
                            .isNotEmpty)
                      ExpansionTile(
                        title: Text(en ? 'Sound over time' : '소리 크기 흐름'),
                        children: [
                          Builder(
                            builder: (_) {
                              final take = r.daily!.takes.firstWhere(
                                (t) => t.path == recording.path,
                              );
                              return PracticeWaveform(
                                values: take.waveform,
                                durationMs:
                                    take.durationMs ?? take.seconds * 1000,
                                english: en,
                              );
                            },
                          ),
                        ],
                      ),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton.icon(
                          onPressed: _busy ? null : () => _play(recording.path),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l.rehabListenMine),
                        ),
                        IconButton(
                          tooltip: en ? 'Share recording' : '녹음 공유',
                          icon: const Icon(Icons.share),
                          onPressed: _busy
                              ? null
                              : () async {
                                  try {
                                    if (!await File(recording.path).exists()) {
                                      throw StateError('Missing file');
                                    }
                                    if (!context.mounted) return;
                                    final box =
                                        context.findRenderObject() as RenderBox;
                                    await SharePlus.instance.share(
                                      ShareParams(
                                        files: [XFile(recording.path)],
                                        sharePositionOrigin:
                                            box.localToGlobal(Offset.zero) &
                                            box.size,
                                      ),
                                    );
                                  } catch (_) {
                                    if (mounted) {
                                      setState(
                                        () => _error = l.rehabAudioError,
                                      );
                                    }
                                  }
                                },
                        ),
                        if (recording.comparable)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    await _player?.stop();
                                    if (!context.mounted) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => RehabSetupScreen(
                                          customText: recording.text,
                                          contentLanguage:
                                              [
                                                'en-US',
                                                'ko-KR',
                                              ].contains(recording.language)
                                              ? recording.language
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                            child: Text(l.rehabRepeat),
                          ),
                      ],
                    ),
                    if (recording.comparable)
                      ExpansionTile(
                        title: Text(l.rehabCompare),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              en
                                  ? 'Microphone and background noise can change how recordings sound.'
                                  : '마이크와 주변 소음에 따라 녹음이 다르게 들릴 수 있어요.',
                            ),
                          ),
                          for (final other
                              in widget.all
                                  .expand((v) => v.recordings)
                                  .where(
                                    (v) =>
                                        v.comparable &&
                                        v.language == recording.language &&
                                        v.text == recording.text &&
                                        v.path != recording.path,
                                  )
                                  .take(8))
                            ListTile(
                              title: Text(rehabDate(other.date.toLocal())),
                              trailing: IconButton(
                                tooltip: l.rehabListenMine,
                                icon: const Icon(Icons.play_arrow),
                                onPressed: _busy
                                    ? null
                                    : () => _play(other.path),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          if (r.recordings.isNotEmpty)
            TextButton(
              onPressed: () => _player?.stop(),
              child: Text(l.rehabStopAudio),
            ),
          if (r.details.isNotEmpty)
            ExpansionTile(
              title: Text(l.rehabReference),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(r.details),
                ),
              ],
            ),
          if (r.daily?.canResume == true)
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      await _player?.stop();
                      if (!context.mounted) return;
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => RehabSetupScreen(resume: r.daily),
                        ),
                      );
                    },
              child: Text(l.rehabResume),
            ),
          if (r.daily != null)
            TextButton(
              onPressed: _busy ? null : _delete,
              child: Text(l.rehabDelete),
            ),
          if (r.kind == 'practice')
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/recording_library'),
              child: Text(l.rehabManageRecordings),
            ),
        ],
      ),
    );
  }
}
