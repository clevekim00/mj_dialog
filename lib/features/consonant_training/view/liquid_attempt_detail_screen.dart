import 'package:flutter/material.dart';
import '../model/consonant_training_models.dart';
import '../services/consonant_training_history_service.dart';
import 'liquid_review_panel.dart';

class LiquidAttemptDetailScreen extends StatefulWidget {
  const LiquidAttemptDetailScreen({
    super.key,
    required this.attempt,
    required this.history,
  });
  final ConsonantTrainingAttempt attempt;
  final ConsonantTrainingHistoryService history;
  @override
  State<LiquidAttemptDetailScreen> createState() =>
      _LiquidAttemptDetailScreenState();
}

class _LiquidAttemptDetailScreenState extends State<LiquidAttemptDetailScreen> {
  late final _previous = widget.history.previousFor(
    targetId: widget.attempt.targetId,
    contentId: widget.attempt.contentId,
    text: widget.attempt.text,
    language: widget.attempt.language,
    excludingId: widget.attempt.id,
    createdBefore: widget.attempt.createdAt,
    contentVersion: widget.attempt.contentVersion,
  );
  bool _busy = false;
  String? _error;
  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('이 녹음 기록을 삭제할까요?'),
        content: const Text('녹음 파일과 파형·분석 결과·내 체크가 함께 삭제돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.history.delete(widget.attempt.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '삭제를 마치지 못했어요. 다시 시도하세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('ㄹ 연습 기록'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _delete,
          tooltip: '녹음 기록 삭제',
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: FutureBuilder<ConsonantTrainingAttempt?>(
      future: _previous,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.attempt.text, style: const TextStyle(fontSize: 30)),
          Text(widget.attempt.createdAt.toLocal().toString().split('.').first),
          if (_error != null) Text(_error!),
          LiquidReviewPanel(
            attempt: widget.attempt,
            previous: snapshot.data,
            enabled: !_busy,
          ),
        ],
      ),
    ),
  );
}
