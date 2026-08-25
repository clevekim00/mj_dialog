import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import 'package:speech_rehab/features/chat/view/chat_screen.dart';
import 'package:speech_rehab/features/chat/view/history_screen.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';
import 'package:speech_rehab/features/tongue_exercise/provider/tongue_exercise_provider.dart';
import 'package:speech_rehab/services/practice_history_service.dart';

class PracticeModeSelectionScreen extends ConsumerWidget {
  const PracticeModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);
    final tongueExercise = ref.watch(tongueExerciseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('오늘의 연습'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (MediaQuery.sizeOf(context).width >= 700)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/voice_analysis_menu'),
                icon: const Icon(Icons.graphic_eq),
                label: const Text('음성도구'),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.graphic_eq),
              tooltip: '음성도구',
              onPressed: () =>
                  Navigator.pushNamed(context, '/voice_analysis_menu'),
            ),
          IconButton(
            icon: const Icon(Icons.library_music),
            tooltip: '녹음 보관함',
            onPressed: () => Navigator.pushNamed(context, '/recording_library'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '히스토리',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: '성과 대시보드',
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _buildTodaySummary(practice),
          const SizedBox(height: 16),
          _buildRecommendedPractice(context, ref, practice),
          const SizedBox(height: 16),
          _buildTongueExerciseWarmupCard(context, practice, tongueExercise),
          const SizedBox(height: 22),
          _buildSectionTitle('다른 연습 선택'),
          const SizedBox(height: 12),
          _buildCompactModeGrid(context, ref),
          const SizedBox(height: 22),
          _buildRecordingLibraryCard(context, practice),
          if (_latestRepeatCandidate(practice) != null) ...[
            const SizedBox(height: 16),
            _buildRepeatCandidateCard(
              context,
              ref,
              _latestRepeatCandidate(practice)!,
            ),
          ],
          const SizedBox(height: 16),
          _buildWeeklyProgress(context, practice),
          const SizedBox(height: 16),
          _buildSafetyNotice(),
        ],
      ),
    );
  }

  Widget _buildTodaySummary(PracticeProgress practice) {
    final today = DateTime.now();
    final todayCount = practice.history.where((session) {
      return session.timestamp.year == today.year &&
          session.timestamp.month == today.month &&
          session.timestamp.day == today.day;
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.today_outlined, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todayCount == 0 ? '오늘 0회 연습' : '오늘 $todayCount회 연습',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '목표 5분 · ${practice.sessionGoal} · 피로도 ${practice.fatigueBefore}/5',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _fatigueStatusColor(
                practice.fatigueBefore,
              ).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _fatigueStatusLabel(practice.fatigueBefore),
              style: TextStyle(
                color: _fatigueStatusColor(practice.fatigueBefore),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingLibraryCard(
    BuildContext context,
    PracticeProgress practice,
  ) {
    final recordingCount = practice.history
        .where((session) => session.audioFilePath.trim().isNotEmpty)
        .length;
    final failedCount = practice.history
        .where(
          (session) =>
              session.audioFilePath.trim().isNotEmpty && session.score < 70,
        )
        .length;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(context, '/recording_library'),
      child: Container(
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
                  const Text(
                    '녹음 보관함',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recordingCount == 0
                        ? '연습한 녹음을 모아서 다시 들어보세요.'
                        : '저장된 녹음 $recordingCount개 · 실패 녹음 $failedCount개',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatCandidateCard(
    BuildContext context,
    WidgetRef ref,
    PracticeSession session,
  ) {
    final mode = PracticeModeLabel.fromStorageValue(session.mode);
    final color = session.score < 70 ? Colors.redAccent : Colors.amberAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.replay_circle_filled_outlined, color: color),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '어려웠던 문장 다시 읽기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${session.score}점',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.targetText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${mode.label} · ${session.category} · 재시도 ${session.retryCount}회',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(practiceProvider.notifier)
                        .practiceAgainFromSession(session);
                    Navigator.pushNamed(
                      context,
                      mode == PracticeMode.wordGame
                          ? '/word_game'
                          : '/practice',
                    );
                  },
                  icon: const Icon(Icons.record_voice_over_outlined),
                  label: const Text('다시 읽기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/recording_library'),
                icon: const Icon(Icons.library_music, color: Colors.white70),
                tooltip: '녹음 보기',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedPractice(
    BuildContext context,
    WidgetRef ref,
    PracticeProgress practice,
  ) {
    final recommendation = _recommendMode(practice);
    final today = DateTime.now();
    final todayCount = practice.history.where((session) {
      return session.timestamp.year == today.year &&
          session.timestamp.month == today.month &&
          session.timestamp.day == today.day;
    }).length;
    final reason = _recommendationReason(
      practice: practice,
      recommendation: recommendation,
      todayCount: todayCount,
    );
    final color = switch (recommendation) {
      PracticeMode.wordGame => Colors.greenAccent,
      PracticeMode.shortSentence => Colors.blueAccent,
      PracticeMode.longSentence => Colors.orangeAccent,
      PracticeMode.freeSpeech => Colors.purpleAccent,
    };
    final icon = switch (recommendation) {
      PracticeMode.wordGame => Icons.sports_esports_outlined,
      PracticeMode.shortSentence => Icons.short_text,
      PracticeMode.longSentence => Icons.notes_outlined,
      PracticeMode.freeSpeech => Icons.forum_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '오늘 추천 연습',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _recommendedTitle(recommendation),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reason,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.flag_outlined, practice.sessionGoal, color),
              _buildInfoChip(
                Icons.local_fire_department_outlined,
                '피로도 ${practice.fatigueBefore}/5',
                color,
              ),
              _buildInfoChip(Icons.timer_outlined, '5분', color),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _openRecommended(context, ref, recommendation),
              icon: const Icon(Icons.play_arrow),
              label: Text(_recommendedCta(recommendation)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildTongueExerciseWarmupCard(
    BuildContext context,
    PracticeProgress practice,
    TongueExerciseProgress tongueExercise,
  ) {
    final isCompleted = tongueExercise.isTodayCompleted;
    final isHighFatigue = practice.fatigueBefore >= 4;
    final status = isCompleted
        ? '오늘 완료'
        : isHighFatigue
        ? '피로도 높음 · 천천히'
        : '운동 메뉴';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(context, '/exercise_menu'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.tealAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.tealAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle_outline
                    : Icons.self_improvement,
                color: Colors.tealAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '연습 전 준비운동',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '혀운동 3분',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isCompleted
                        ? '혀운동은 오늘 완료했어요. 얼굴운동도 필요하면 이어서 해보세요.'
                        : '혀와 얼굴을 천천히 풀고 발음 연습을 시작해요.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactModeGrid(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildCompactModeCard(
          icon: Icons.sports_esports_outlined,
          title: '단어 게임',
          subtitle: '짧게 말하기',
          note: '틀린 단어 복습 가능',
          color: Colors.greenAccent,
          onTap: () {
            ref.read(practiceProvider.notifier).setMode(PracticeMode.wordGame);
            Navigator.pushNamed(context, '/word_game');
          },
        ),
        _buildCompactModeCard(
          icon: Icons.short_text,
          title: '짧은 문장 읽기',
          subtitle: '일상 표현',
          note: '부담 적은 반복',
          color: Colors.blueAccent,
          onTap: () => _openPractice(context, ref, PracticeMode.shortSentence),
        ),
        _buildCompactModeCard(
          icon: Icons.notes_outlined,
          title: '긴 문장 읽기',
          subtitle: '긴 호흡 연습',
          note: '내 문장 관리',
          color: Colors.orangeAccent,
          onTap: () => _openPractice(context, ref, PracticeMode.longSentence),
        ),
        _buildCompactModeCard(
          icon: Icons.forum_outlined,
          title: '자유 대화',
          subtitle: '상황 말하기',
          note: '주제 없이 편하게',
          color: Colors.purpleAccent,
          onTap: () {
            ref.read(chatControllerProvider.notifier).createNewSession();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String note,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(BuildContext context, PracticeProgress practice) {
    final activeDays = _countActiveDays(practice);
    final averageScore = practice.history.isEmpty
        ? 0
        : practice.history
                  .map((session) => session.score)
                  .reduce((a, b) => a + b) ~/
              practice.history.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '이번 주 흐름',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                child: const Text('대시보드 보기'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '최근 7일 중 $activeDays일 연습했습니다.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            averageScore == 0
                ? '점수 기록이 쌓이면 흐름을 보여드릴게요.'
                : '평균 점수 $averageScore점 · 피로도 ${practice.fatigueBefore}/5',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (activeDays / 7).clamp(0, 1),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, color: Colors.orangeAccent),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '쉬어야 할 때',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '사레, 호흡 불편, 갑작스러운 말 변화가 있으면 연습을 멈추고 전문가에게 문의하세요.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _recommendedTitle(PracticeMode mode) {
    return switch (mode) {
      PracticeMode.wordGame => '단어 게임 5분',
      PracticeMode.shortSentence => '짧은 문장 5분',
      PracticeMode.longSentence => '긴 문장 10분',
      PracticeMode.freeSpeech => '자유 말하기 5분',
    };
  }

  String _recommendedCta(PracticeMode mode) {
    return switch (mode) {
      PracticeMode.wordGame => '단어 게임 시작하기',
      PracticeMode.shortSentence => '짧은 문장 시작하기',
      PracticeMode.longSentence => '긴 문장 시작하기',
      PracticeMode.freeSpeech => '자유 말하기 시작하기',
    };
  }

  String _recommendationReason({
    required PracticeProgress practice,
    required PracticeMode recommendation,
    required int todayCount,
  }) {
    if (practice.fatigueBefore >= 4) {
      return '피로도가 높으니 짧게 시작하고, 불편하면 바로 쉬어 주세요.';
    }
    if (todayCount == 0) {
      return '오늘 첫 연습은 부담이 적은 ${recommendation.label}부터 시작해 보세요.';
    }
    if (practice.history.any((session) => session.score < 75)) {
      return '낮은 점수 기록이 있어 어려웠던 발음부터 가볍게 좁혀봅니다.';
    }
    return '최근 기록을 이어가며 ${recommendation.label}로 한 번 더 마무리해요.';
  }

  String _fatigueStatusLabel(int fatigue) {
    if (fatigue >= 4) {
      return '짧게 연습';
    }
    if (fatigue >= 3) {
      return '천천히';
    }
    return '상태 양호';
  }

  Color _fatigueStatusColor(int fatigue) {
    if (fatigue >= 4) {
      return Colors.orangeAccent;
    }
    if (fatigue >= 3) {
      return Colors.amberAccent;
    }
    return Colors.blueAccent;
  }

  int _countActiveDays(PracticeProgress practice) {
    final now = DateTime.now();
    return practice.history
        .where((session) => now.difference(session.timestamp).inDays < 7)
        .map(
          (session) => DateTime(
            session.timestamp.year,
            session.timestamp.month,
            session.timestamp.day,
          ),
        )
        .toSet()
        .length;
  }

  PracticeMode _recommendMode(PracticeProgress practice) {
    if (practice.history.isEmpty) {
      return PracticeMode.shortSentence;
    }

    final recent = practice.history.take(3).toList();
    final hasLowScore = recent.any((session) => session.score < 75);
    if (hasLowScore) {
      return PracticeMode.wordGame;
    }

    final lastMode = PracticeModeLabel.fromStorageValue(recent.first.mode);
    return switch (lastMode) {
      PracticeMode.wordGame => PracticeMode.shortSentence,
      PracticeMode.shortSentence => PracticeMode.longSentence,
      PracticeMode.longSentence => PracticeMode.freeSpeech,
      PracticeMode.freeSpeech => PracticeMode.shortSentence,
    };
  }

  PracticeSession? _latestRepeatCandidate(PracticeProgress practice) {
    final candidates = practice.history.where((session) {
      final mode = PracticeModeLabel.fromStorageValue(session.mode);
      final isReadableMode =
          mode == PracticeMode.shortSentence ||
          mode == PracticeMode.longSentence;
      return isReadableMode &&
          session.audioFilePath.trim().isNotEmpty &&
          (session.score < 70 || session.retryCount > 0);
    }).toList();

    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return candidates.first;
  }

  void _openPractice(BuildContext context, WidgetRef ref, PracticeMode mode) {
    ref.read(practiceProvider.notifier).setMode(mode);
    Navigator.pushNamed(context, '/practice');
  }

  void _openRecommended(
    BuildContext context,
    WidgetRef ref,
    PracticeMode mode,
  ) {
    if (mode == PracticeMode.wordGame) {
      ref.read(practiceProvider.notifier).setMode(PracticeMode.wordGame);
      Navigator.pushNamed(context, '/word_game');
      return;
    }
    if (mode == PracticeMode.freeSpeech) {
      ref.read(chatControllerProvider.notifier).createNewSession();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
      return;
    }
    _openPractice(context, ref, mode);
  }
}
