import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';
import 'package:speech_rehab/features/practice/view/widgets/mouth_video_preview_sheet.dart';
import 'package:speech_rehab/services/practice_history_service.dart';

enum _RecordingFilter { all, word, short, long, failed, saved }

enum _RecordingSort { newest, lowScore, highScore }

class RecordingLibraryScreen extends ConsumerStatefulWidget {
  const RecordingLibraryScreen({super.key});

  @override
  ConsumerState<RecordingLibraryScreen> createState() =>
      _RecordingLibraryScreenState();
}

class _RecordingLibraryScreenState
    extends ConsumerState<RecordingLibraryScreen> {
  _RecordingFilter _filter = _RecordingFilter.all;
  _RecordingSort _sort = _RecordingSort.newest;
  final Set<String> _selectedSessionIds = {};

  bool get _isSelecting => _selectedSessionIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final practice = ref.watch(practiceProvider);
    final notifier = ref.read(practiceProvider.notifier);
    final recordings = practice.history
        .where((session) => session.audioFilePath.trim().isNotEmpty)
        .where(_matchesFilter)
        .toList();
    _sortRecordings(recordings);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text(
          _isSelecting ? '${_selectedSessionIds.length}개 선택' : '녹음 보관함',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isSelecting) ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '선택 취소',
              onPressed: () => setState(_selectedSessionIds.clear),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: '선택 삭제',
              onPressed: () => _deleteSelectedRecordings(context, notifier),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist_outlined),
              tooltip: '여러 개 선택',
              onPressed: recordings.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _selectedSessionIds.add(recordings.first.id);
                      });
                    },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: '전체 연습 기록',
              onPressed: () =>
                  Navigator.pushNamed(context, '/practice_history'),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          _buildSummary(practice.history),
          const SizedBox(height: 14),
          _buildFilterChips(),
          const SizedBox(height: 10),
          _buildLibraryTools(context, notifier),
          const SizedBox(height: 14),
          if (recordings.isEmpty)
            _buildEmptyState()
          else
            ...recordings.map(
              (session) => _buildRecordingCard(
                context,
                session,
                notifier,
                isSelected: _selectedSessionIds.contains(session.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<PracticeSession> history) {
    final recordings = history
        .where((session) => session.audioFilePath.trim().isNotEmpty)
        .toList();
    final failed = recordings.where((session) => session.score < 70).length;
    final saved = recordings
        .where(
          (session) => ref
              .watch(practiceProvider)
              .savedReviewSessionIds
              .contains(session.id),
        )
        .length;
    final latest = recordings.isEmpty
        ? null
        : DateFormat('MM.dd HH:mm').format(recordings.first.timestamp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.library_music, color: Colors.greenAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '저장된 녹음 ${recordings.length}개',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  latest == null
                      ? '연습 후 녹음이 자동으로 여기에 모입니다.'
                      : '최근 $latest · 실패 녹음 $failed개',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                if (saved > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    '반복 저장 $saved개',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(_RecordingFilter.all, '전체', Icons.all_inclusive),
          _buildFilterChip(
            _RecordingFilter.word,
            '단어',
            Icons.sports_esports_outlined,
          ),
          _buildFilterChip(_RecordingFilter.short, '짧은 문장', Icons.short_text),
          _buildFilterChip(_RecordingFilter.long, '긴 문장', Icons.notes_outlined),
          _buildFilterChip(_RecordingFilter.failed, '실패', Icons.error_outline),
          _buildFilterChip(
            _RecordingFilter.saved,
            '반복 저장',
            Icons.bookmark_added_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTools(BuildContext context, PracticeNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_RecordingSort>(
                value: _sort,
                dropdownColor: const Color(0xFF202020),
                iconEnabledColor: Colors.white54,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sort = value);
                },
                items: const [
                  DropdownMenuItem(
                    value: _RecordingSort.newest,
                    child: Text('최신순'),
                  ),
                  DropdownMenuItem(
                    value: _RecordingSort.lowScore,
                    child: Text('점수 낮은 순'),
                  ),
                  DropdownMenuItem(
                    value: _RecordingSort.highScore,
                    child: Text('점수 높은 순'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => _deleteUnavailableRecordings(context, notifier),
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            label: const Text('재생불가 삭제'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
              side: BorderSide(
                color: Colors.orangeAccent.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    _RecordingFilter filter,
    String label,
    IconData icon,
  ) {
    final selected = _filter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _filter = filter),
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? Colors.black : Colors.white54,
        ),
        label: Text(label),
        selectedColor: Colors.greenAccent,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
        side: BorderSide(color: selected ? Colors.greenAccent : Colors.white10),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.graphic_eq, color: Colors.white30, size: 42),
          SizedBox(height: 12),
          Text(
            '조건에 맞는 녹음이 없습니다.',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '단어게임이나 문장 읽기를 마치면 녹음이 자동으로 저장됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(
    BuildContext context,
    PracticeSession session,
    PracticeNotifier notifier, {
    required bool isSelected,
  }) {
    final practice = ref.watch(practiceProvider);
    final modeColor = _modeColor(session.mode);
    final date = DateFormat('yyyy.MM.dd HH:mm').format(session.timestamp);
    final preview = session.targetText.replaceAll('\n', ' ');
    final isSavedForReview = practice.savedReviewSessionIds.contains(
      session.id,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onLongPress: () => _toggleSelection(session.id),
      onTap: _isSelecting ? () => _toggleSelection(session.id) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.greenAccent.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.greenAccent.withValues(alpha: 0.55)
                : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_isSelecting) ...[
                  Checkbox(
                    value: isSelected,
                    activeColor: Colors.greenAccent,
                    checkColor: Colors.black,
                    onChanged: (_) => _toggleSelection(session.id),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_modeIcon(session.mode), color: modeColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _modeLabel(session.mode),
                        style: TextStyle(
                          color: modeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildScoreBadge(session.score),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              preview,
              maxLines: session.mode == PracticeMode.longSentence.storageValue
                  ? 3
                  : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            if (session.spokenText.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '인식된 발음: ${session.spokenText}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetaChip(Icons.category_outlined, session.category),
                if (session.durationSeconds > 0)
                  _buildMetaChip(
                    Icons.timer_outlined,
                    '${session.durationSeconds}초',
                  ),
                if (session.score < 70)
                  _buildMetaChip(Icons.error_outline, '다시 연습 추천'),
                if (isSavedForReview)
                  _buildMetaChip(Icons.bookmark_added_outlined, '반복 저장'),
                if (session.videoFilePath?.trim().isNotEmpty ?? false)
                  _buildMetaChip(Icons.videocam_outlined, '입모양 영상'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSelecting
                        ? null
                        : () async {
                            final ok = await notifier.playRecording(
                              session.audioFilePath,
                            );
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text('녹음 파일을 재생할 수 없습니다.'),
                                  ),
                                );
                            }
                          },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('듣기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.08,
                      ),
                      disabledForegroundColor: Colors.white30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (session.videoFilePath?.trim().isNotEmpty ?? false) ...[
                  IconButton(
                    tooltip: '입모양 영상 보기',
                    onPressed: _isSelecting
                        ? null
                        : () => MouthVideoPreviewSheet.show(
                            context,
                            session.videoFilePath!,
                          ),
                    icon: const Icon(Icons.video_library_outlined),
                    color: Colors.greenAccent,
                    disabledColor: Colors.white24,
                  ),
                ],
                IconButton(
                  tooltip: isSavedForReview ? '반복 저장 해제' : '반복연습 저장',
                  onPressed: _isSelecting
                      ? null
                      : () => notifier.toggleSavedReviewSession(session),
                  icon: Icon(
                    isSavedForReview
                        ? Icons.bookmark_added
                        : Icons.bookmark_add_outlined,
                  ),
                  color: isSavedForReview ? Colors.greenAccent : Colors.white54,
                  disabledColor: Colors.white24,
                ),
                IconButton(
                  tooltip: '다시 연습',
                  onPressed: _isSelecting
                      ? null
                      : () {
                          notifier.practiceAgainFromSession(session);
                          Navigator.pushNamed(
                            context,
                            session.mode == PracticeMode.wordGame.storageValue
                                ? '/word_game'
                                : '/practice',
                          );
                        },
                  icon: const Icon(Icons.replay_outlined),
                  color: Colors.white70,
                  disabledColor: Colors.white24,
                ),
                IconButton(
                  tooltip: '삭제',
                  onPressed: _isSelecting
                      ? null
                      : () =>
                            _deleteSingleRecording(context, notifier, session),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.white38,
                  disabledColor: Colors.white24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(String sessionId) {
    setState(() {
      if (_selectedSessionIds.contains(sessionId)) {
        _selectedSessionIds.remove(sessionId);
      } else {
        _selectedSessionIds.add(sessionId);
      }
    });
  }

  Future<void> _deleteSingleRecording(
    BuildContext context,
    PracticeNotifier notifier,
    PracticeSession session,
  ) async {
    await notifier.deleteSession(session.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${_modeLabel(session.mode)} 녹음을 삭제했습니다.')),
      );
  }

  Future<void> _deleteSelectedRecordings(
    BuildContext context,
    PracticeNotifier notifier,
  ) async {
    final ids = _selectedSessionIds.toList();
    if (ids.isEmpty) {
      return;
    }

    setState(_selectedSessionIds.clear);
    for (final id in ids) {
      await notifier.deleteSession(id);
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('녹음 ${ids.length}개를 삭제했습니다.')));
  }

  Future<void> _deleteUnavailableRecordings(
    BuildContext context,
    PracticeNotifier notifier,
  ) async {
    final deletedCount = await notifier.deleteUnavailableRecordings();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            deletedCount == 0
                ? '재생 불가능한 녹음이 없습니다.'
                : '재생 불가능한 녹음 $deletedCount개를 삭제했습니다.',
          ),
        ),
      );
  }

  Widget _buildScoreBadge(int score) {
    final color = score >= 90
        ? Colors.greenAccent
        : score >= 70
        ? Colors.orangeAccent
        : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        '$score점',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  bool _matchesFilter(PracticeSession session) {
    return switch (_filter) {
      _RecordingFilter.all => true,
      _RecordingFilter.word =>
        session.mode == PracticeMode.wordGame.storageValue,
      _RecordingFilter.short =>
        session.mode == PracticeMode.shortSentence.storageValue,
      _RecordingFilter.long =>
        session.mode == PracticeMode.longSentence.storageValue,
      _RecordingFilter.failed => session.score < 70,
      _RecordingFilter.saved =>
        ref.watch(practiceProvider).savedReviewSessionIds.contains(session.id),
    };
  }

  void _sortRecordings(List<PracticeSession> recordings) {
    switch (_sort) {
      case _RecordingSort.newest:
        recordings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return;
      case _RecordingSort.lowScore:
        recordings.sort((a, b) {
          final scoreCompare = a.score.compareTo(b.score);
          if (scoreCompare != 0) return scoreCompare;
          return b.timestamp.compareTo(a.timestamp);
        });
        return;
      case _RecordingSort.highScore:
        recordings.sort((a, b) {
          final scoreCompare = b.score.compareTo(a.score);
          if (scoreCompare != 0) return scoreCompare;
          return b.timestamp.compareTo(a.timestamp);
        });
        return;
    }
  }

  String _modeLabel(String mode) {
    return switch (mode) {
      'wordGame' => '단어게임',
      'longSentence' => '긴 문장 읽기',
      'freeSpeech' => '자유 말하기',
      _ => '짧은 문장 읽기',
    };
  }

  IconData _modeIcon(String mode) {
    return switch (mode) {
      'wordGame' => Icons.sports_esports_outlined,
      'longSentence' => Icons.notes_outlined,
      'freeSpeech' => Icons.forum_outlined,
      _ => Icons.short_text,
    };
  }

  Color _modeColor(String mode) {
    return switch (mode) {
      'wordGame' => Colors.greenAccent,
      'longSentence' => Colors.orangeAccent,
      'freeSpeech' => Colors.purpleAccent,
      _ => Colors.blueAccent,
    };
  }
}
