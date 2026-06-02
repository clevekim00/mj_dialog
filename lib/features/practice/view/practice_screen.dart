import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/services/practice_content_service.dart';
import '../model/practice_mode.dart';
import '../provider/practice_provider.dart';
import '../../chat/provider/chat_provider.dart';
import '../../chat/view/widgets/feedback_card.dart';
import '../../chat/view/widgets/animated_orb.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);
    final notifier = ref.read(practiceProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text(practice.mode.label),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard');
            },
            tooltip: '성과 대시보드',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/practice_history');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildRehabSessionCard(ref, practice),
              const SizedBox(height: 20),
              _buildModeSelector(ref, practice.mode),
              const SizedBox(height: 20),
              _buildTargetCard(context, ref, practice),
              const SizedBox(height: 40),
              // Changed from Expanded to a fixed/min height for scrolling compatibility
              Container(
                constraints: const BoxConstraints(minHeight: 250),
                child: Center(
                  child: _buildInteractionArea(
                    context,
                    ref,
                    practice,
                    notifier,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (practice.feedback != null) ...[
                FeedbackCard(
                  aiResponse: practice.feedback!,
                  onDismiss: () => notifier.dismissFeedback(),
                ),
                const SizedBox(height: 20),
              ],
              if (practice.state == PracticeState.completed)
                _buildActionButtons(practice, notifier),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(WidgetRef ref, PracticeMode mode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(ref, '단어', mode, PracticeMode.wordGame),
          _buildModeButton(ref, '짧은 문장', mode, PracticeMode.shortSentence),
          _buildModeButton(ref, '긴 문장', mode, PracticeMode.longSentence),
          _buildModeButton(ref, '자유', mode, PracticeMode.freeSpeech),
        ],
      ),
    );
  }

  Widget _buildRehabSessionCard(WidgetRef ref, PracticeProgress practice) {
    const goals = ['또렷하게 말하기', '천천히 말하기', '크게 말하기', '숨 조절하기'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                '오늘의 연습 세션',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '불편감, 사레, 호흡 곤란, 갑작스러운 말 변화가 있으면 연습을 멈추고 전문가에게 문의하세요.',
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          const Text(
            '목표',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goals.map((goal) {
              final isSelected = practice.sessionGoal == goal;
              return ChoiceChip(
                label: Text(goal),
                selected: isSelected,
                selectedColor: Colors.blueAccent,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? Colors.blueAccent : Colors.white12,
                ),
                onSelected: (_) {
                  ref.read(practiceProvider.notifier).setSessionGoal(goal);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '시작 전 피로도',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${practice.fatigueBefore}/5',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: practice.fatigueBefore.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white12,
            label: '${practice.fatigueBefore}',
            onChanged: practice.state == PracticeState.recording
                ? null
                : (value) {
                    ref
                        .read(practiceProvider.notifier)
                        .setFatigueBefore(value.round());
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    WidgetRef ref,
    String label,
    PracticeMode currentMode,
    PracticeMode mode,
  ) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: isSelected
          ? null
          : () => ref.read(practiceProvider.notifier).setMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetCard(
    BuildContext context,
    WidgetRef ref,
    PracticeProgress practice,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _targetLabel(practice.mode),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              if (!practice.isFreeMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (practice.mode == PracticeMode.wordGame)
                      IconButton(
                        icon: const Icon(
                          Icons.replay_circle_filled_outlined,
                          color: Colors.greenAccent,
                          size: 20,
                        ),
                        onPressed: () => _startFailedWordReview(context, ref),
                        tooltip: '틀린 단어 복습',
                      ),
                    if (practice.mode == PracticeMode.longSentence) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        onPressed: () => _showLongSentenceEditor(context, ref),
                        tooltip: '내 긴 문장 추가',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.folder_special_outlined,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () =>
                            _showCustomLongSentenceManager(context, ref),
                        tooltip: '내 긴 문장 관리',
                      ),
                    ],
                    IconButton(
                      icon: const Icon(
                        Icons.menu_book,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      onPressed: () => _showTextInputDialog(context, ref),
                      tooltip: practice.mode == PracticeMode.longSentence
                          ? '이번만 연습할 문장 입력'
                          : '연습할 문장 입력',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () =>
                          ref.read(practiceProvider.notifier).nextItem(),
                      tooltip: '다음 항목',
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            practice.isFreeMode
                ? '어제 있었던 일이나 오늘 기분,\n좋아하는 주제로 편하게 말씀해 보세요.'
                : _formatTargetText(practice),
            style: TextStyle(
              color: practice.isFreeMode ? Colors.white54 : Colors.white,
              fontSize: practice.mode == PracticeMode.wordGame
                  ? 44
                  : (practice.isFreeMode ? 18 : 22),
              fontWeight: practice.isFreeMode
                  ? FontWeight.normal
                  : FontWeight.bold,
              height: 1.4,
            ),
          ),
          if (!practice.isFreeMode) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSmallChip(Icons.category_outlined, practice.category),
                _buildSmallChip(
                  Icons.signal_cellular_alt,
                  '난이도 ${practice.difficulty}',
                ),
                if (practice.contentSource == PracticeContentSource.custom)
                  _buildSmallChip(Icons.bookmark_added_outlined, '내 문장'),
                if (practice.isReviewMode)
                  _buildSmallChip(Icons.replay_circle_filled_outlined, '복습'),
                if (practice.retryCount > 0)
                  _buildSmallChip(
                    Icons.replay_outlined,
                    '재시도 ${practice.retryCount}',
                  ),
                if (practice.streakCount > 0)
                  _buildSmallChip(
                    Icons.local_fire_department_outlined,
                    '연속 성공 ${practice.streakCount}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _targetLabel(PracticeMode mode) {
    return switch (mode) {
      PracticeMode.wordGame => '단어를 또렷하게 말해보세요:',
      PracticeMode.shortSentence => '짧은 문장을 따라 읽어보세요:',
      PracticeMode.longSentence => '긴 문장을 천천히 끊어 읽어보세요:',
      PracticeMode.freeSpeech => '다루고 싶은 주제로 말해보세요:',
    };
  }

  String _formatTargetText(PracticeProgress practice) {
    if (practice.mode != PracticeMode.longSentence) {
      return practice.targetText;
    }
    return practice.targetText
        .replaceAll(' 하면서 ', ' 하면서\n')
        .replaceAll(' 전에 ', ' 전에\n')
        .replaceAll(' 함께 ', ' 함께\n')
        .replaceAll(' 때는 ', ' 때는\n');
  }

  Widget _buildSmallChip(IconData icon, String label) {
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

  void _showTextInputDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('연습할 문장 입력', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '책에서 본 문장을 입력해 보세요...',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white10),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(practiceProvider.notifier)
                    .setTargetText(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _startFailedWordReview(BuildContext context, WidgetRef ref) {
    final started = ref.read(practiceProvider.notifier).startFailedWordReview();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(started ? '틀린 단어 복습을 시작합니다.' : '복습할 틀린 단어가 없습니다.'),
      ),
    );
  }

  void _showLongSentenceEditor(
    BuildContext context,
    WidgetRef ref, {
    PracticeContentItem? item,
  }) {
    final textController = TextEditingController(text: item?.text ?? '');
    final categoryController = TextEditingController(
      text: item?.category == null || item?.category == '내 문장'
          ? ''
          : item!.category,
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final text = textController.text.trim();
          final difficulty = CustomPracticeContentService.estimateDifficulty(
            text,
          );

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              item == null ? '내 긴 문장 추가' : '내 긴 문장 수정',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    maxLength: 160,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setState(() => errorText = null),
                    decoration: InputDecoration(
                      hintText: '반복해서 연습하고 싶은 긴 문장을 입력하세요.',
                      hintStyle: const TextStyle(color: Colors.white24),
                      errorText: errorText,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '상황 예: 병원, 전화, 가족',
                      hintStyle: TextStyle(color: Colors.white24),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '예상 난이도 $difficulty · 너무 길면 의미 단위로 끊어 표시됩니다.',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final sentence = textController.text.trim();
                  if (sentence.length < 10) {
                    setState(() => errorText = '긴 문장은 10자 이상 입력해 주세요.');
                    return;
                  }

                  final notifier = ref.read(practiceProvider.notifier);
                  if (item == null) {
                    await notifier.addCustomLongSentence(
                      text: sentence,
                      category: categoryController.text,
                    );
                  } else {
                    await notifier.updateCustomLongSentence(
                      id: item.id,
                      text: sentence,
                      category: categoryController.text,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text(item == null ? '추가' : '저장'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomLongSentenceManager(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FutureBuilder<List<PracticeContentItem>>(
            future: ref
                .read(practiceProvider.notifier)
                .loadCustomLongSentences(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '내 긴 문장',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showLongSentenceEditor(context, ref);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent,
                          ),
                        ),
                      )
                    else if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          '저장한 긴 문장이 없습니다.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${item.category} · 난이도 ${item.difficulty}',
                                style: const TextStyle(color: Colors.white38),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                      _showLongSentenceEditor(
                                        context,
                                        ref,
                                        item: item,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      await ref
                                          .read(practiceProvider.notifier)
                                          .deleteCustomLongSentence(item.id);
                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                        _showCustomLongSentenceManager(
                                          context,
                                          ref,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInteractionArea(
    BuildContext context,
    WidgetRef ref,
    PracticeProgress practice,
    PracticeNotifier notifier,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (practice.spokenText.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '인식된 내용:',
                  style: TextStyle(
                    color: Colors.blueAccent.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  practice.spokenText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        if (practice.state == PracticeState.analyzing)
          const Column(
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 20),
              Text(
                'AI가 발음을 분석하고 있습니다...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          )
        else
          _buildOrbArea(practice, notifier),
      ],
    );
  }

  Widget _buildOrbArea(PracticeProgress practice, PracticeNotifier notifier) {
    // Map PracticeState to ConversationState for AnimatedOrb
    final orbState = switch (practice.state) {
      PracticeState.recording => ConversationState.listening,
      PracticeState.analyzing => ConversationState.thinking,
      _ => ConversationState.idle,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (practice.state == PracticeState.recording) {
              notifier.stopRecording();
            } else {
              notifier.startRecording();
            }
          },
          child: AnimatedOrb(state: orbState),
        ),
        const SizedBox(height: 32),
        Text(
          practice.state == PracticeState.recording
              ? '불편하면 즉시 멈추고 쉬어 주세요'
              : _idlePrompt(practice.mode),
          style: TextStyle(
            color: practice.state == PracticeState.recording
                ? Colors.redAccent
                : Colors.white54,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _idlePrompt(PracticeMode mode) {
    return switch (mode) {
      PracticeMode.wordGame => '구슬을 터치하여 단어 녹음',
      PracticeMode.shortSentence => '구슬을 터치하여 짧은 문장 녹음',
      PracticeMode.longSentence => '구슬을 터치하여 긴 문장 녹음',
      PracticeMode.freeSpeech => '구슬을 터치하여 자유롭게 말하기',
    };
  }

  Widget _buildActionButtons(
    PracticeProgress practice,
    PracticeNotifier notifier,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: practice.isPlaying
              ? () => notifier.stopPlayback()
              : () => notifier.playRecording(null),
          icon: Icon(practice.isPlaying ? Icons.stop : Icons.play_arrow),
          label: Text(practice.isPlaying ? '재생 중지' : '내 목소리 듣기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: practice.isPlaying
                ? Colors.redAccent.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.1),
            foregroundColor: practice.isPlaying
                ? Colors.redAccent
                : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => notifier.shareRecording(),
          icon: const Icon(Icons.share, size: 20),
          label: const Text('공유'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => notifier.resetPractice(),
          icon: const Icon(Icons.refresh),
          label: const Text('다시 하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}
