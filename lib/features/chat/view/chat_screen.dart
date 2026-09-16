import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import 'package:speech_rehab/features/practice/view/widgets/mouth_video_preview_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden) {
      unawaited(ref.read(chatControllerProvider.notifier).endConversation());
    }
  }

  Future<void> _finishAndClose() async {
    if (_closing) return;
    setState(() => _closing = true);
    await ref.read(chatControllerProvider.notifier).endConversation();
    if (!mounted) return;
    setState(() => _closing = false);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.maybePop(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await ref.read(chatControllerProvider.notifier).submitText(text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      chatControllerProvider.select((value) => value.errorMessage),
      (previous, next) {
        if (next == null || next == previous) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
        ref.read(chatControllerProvider.notifier).clearError();
      },
    );
    final session = ref.watch(chatControllerProvider);
    final notifier = ref.read(chatControllerProvider.notifier);
    final listening = session.conversationState == ConversationState.listening;
    final busy =
        session.isProcessing || session.currentSession == null || _closing;
    final canType = !busy && !listening;
    final camera = notifier.mouthVideoController;

    return PopScope(
      canPop: !listening && !busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(notifier.endConversation());
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('소리와 녹음을 멈추려면 대화 마치기를 눌러 주세요.')),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('대화 연습'),
          actions: [
            IconButton(
              tooltip: '새 대화',
              onPressed: busy || listening ? null : notifier.createNewSession,
              icon: const Icon(Icons.add_comment_outlined),
            ),
            IconButton(
              tooltip: session.mouthVideoEnabled ? '입모양 촬영 끄기' : '입모양 촬영 켜기',
              onPressed: busy || listening
                  ? null
                  : () => notifier.setMouthVideoEnabled(
                      !session.mouthVideoEnabled,
                    ),
              icon: Icon(
                session.mouthVideoEnabled
                    ? Icons.videocam
                    : Icons.videocam_outlined,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      '말하기, 글 입력, 준비된 문장 중 편한 방법을 선택하세요. 대화에서는 발음 점수를 매기지 않습니다.',
                    ),
                    const SizedBox(height: 16),
                    for (final message
                        in session.currentSession?.messages ??
                            <ChatMessage>[]) ...[
                      Align(
                        alignment: message.role == ChatRole.user
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              message.text,
                              style: const TextStyle(fontSize: 18, height: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (listening)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          session.liveText.isEmpty
                              ? '듣고 있어요. 편안한 속도로 말씀하세요.'
                              : session.liveText,
                        ),
                      ),
                    if (session.isProcessing) const Text('응답을 준비하고 있어요.'),
                    if (session.mouthVideoError != null)
                      Text(session.mouthVideoError!),
                    if (session.mouthVideoEnabled &&
                        session.isMouthVideoReady &&
                        camera != null)
                      SizedBox(
                        height: 150,
                        child: AspectRatio(
                          aspectRatio: camera.value.aspectRatio,
                          child: CameraPreview(camera),
                        ),
                      ),
                    if (session.lastMouthVideoPath != null)
                      OutlinedButton.icon(
                        onPressed: () => MouthVideoPreviewSheet.show(
                          context,
                          session.lastMouthVideoPath!,
                        ),
                        icon: const Icon(Icons.video_library_outlined),
                        label: const Text('입모양 영상 보기'),
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final text in [
                          '잠시 쉬고 싶어요.',
                          '천천히 이야기해 주세요.',
                          '오늘 있었던 일을 이야기할게요.',
                        ])
                          ActionChip(
                            label: Text(text),
                            onPressed: canType
                                ? () => notifier.submitText(
                                    text,
                                    inputMethod: 'prepared',
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            enabled: canType,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              labelText: '글로 이야기하기',
                              hintText: '전하고 싶은 말을 입력하세요.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: '입력한 글 보내기',
                          onPressed: canType ? _send : null,
                          icon: const Icon(Icons.send),
                          constraints: const BoxConstraints(
                            minHeight: 56,
                            minWidth: 56,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => notifier.toggleVoiceInput(
                                isVoiceSupported: true,
                              ),
                        icon: Icon(listening ? Icons.stop : Icons.mic),
                        label: Text(listening ? '말하기 마치고 보내기' : '말로 이야기하기'),
                      ),
                    ),
                    TextButton(
                      onPressed: _closing ? null : _finishAndClose,
                      child: Text(_closing ? '대화를 마치고 있어요.' : '대화 마치기'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
