import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// Only media explicitly reviewed for this exact prompt may demonstrate speech.
class ReviewedSpeechMedia {
  const ReviewedSpeechMedia({
    required this.asset,
    required this.prompt,
    required this.reviewedBy,
    required this.version,
    required this.audioSynchronized,
  });
  final String asset, prompt, reviewedBy, version;
  final bool audioSynchronized;
  bool matches(String text) =>
      prompt == text &&
      reviewedBy.isNotEmpty &&
      version.isNotEmpty &&
      audioSynchronized;
}

String? firstHangulConsonant(String text) {
  final runes = text.trim().runes;
  if (runes.isEmpty || runes.first < 0xac00 || runes.first > 0xd7a3) {
    return null;
  }
  const initials = [
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
  ];
  final initial = initials[(runes.first - 0xac00) ~/ 588];
  return initial == 'ㅇ' ? null : initial;
}

class PracticeGuide extends StatefulWidget {
  const PracticeGuide({
    super.key,
    required this.text,
    required this.instruction,
    required this.english,
    required this.locked,
    required this.listen,
    required this.stop,
    this.media,
    this.playing = false,
    this.recording = false,
  });
  final String text, instruction;
  final bool english, locked;
  final bool playing, recording;
  final Future<void> Function(String) listen;
  final Future<void> Function() stop;
  final ReviewedSpeechMedia? media;
  @override
  State<PracticeGuide> createState() => PracticeGuideState();
}

class PracticeGuideState extends State<PracticeGuide> {
  final _videoKey = GlobalKey<_GuideVideoState>();
  Future<void> stopMedia() async {
    await _videoKey.currentState?.stopMedia();
  }

  @override
  void didUpdateWidget(covariant PracticeGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _step = 0;
      _open = !_quick;
    }
  }

  int _step = 0;
  bool _open = true, _changed = false, _quick = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final quick =
        (await SharedPreferences.getInstance()).getBool('rehab_guide_quick') ??
        false;
    if (mounted && !_changed) {
      setState(() {
        _quick = quick;
        _open = !quick;
      });
    }
  }

  Future<void> _setQuick(bool value) async {
    _changed = true;
    final saved = await (await SharedPreferences.getInstance()).setBool(
      'rehab_guide_quick',
      value,
    );
    if (mounted && saved) setState(() => _quick = value);
  }

  Future<void> _advance() async {
    await widget.stop();
    if (!mounted) return;
    setState(() {
      _changed = true;
      if (_step < 2) {
        _step++;
      } else {
        _open = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.english;
    if (widget.recording) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            liveRegion: true,
            child: Text(
              en ? 'Your turn · recording your voice' : '내 차례 · 목소리를 녹음하고 있어요',
            ),
          ),
        ),
      );
    }
    final steps = en
        ? ['Listen first', 'Check one part', 'Speak when ready']
        : ['먼저 들어요', '한 부분씩 확인해요', '준비되면 말해요'];
    final chunks = widget.text.contains('/')
        ? widget.text.split('/')
        : widget.text.split(' ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    en ? 'How do I practise?' : '어떻게 연습하나요?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: en ? 'Show or hide guide' : '안내 펼치기·접기',
                  onPressed: widget.locked
                      ? null
                      : () => setState(() {
                          _changed = true;
                          _open = !_open;
                        }),
                  icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
            if (widget.playing)
              TextButton.icon(
                onPressed: widget.stop,
                icon: const Icon(Icons.stop),
                label: Text(en ? 'Stop example' : '예시 멈추기'),
              ),
            if (_open) ...[
              Text('${_step + 1} / 3 · ${steps[_step]}'),
              const SizedBox(height: 12),
              if (_step == 0) ...[
                Text(
                  en
                      ? 'Listen once. You do not need to speak at the same time.'
                      : '예시를 한 번 들어요. 동시에 따라 말하지 않아도 돼요.',
                ),
                if (widget.media?.matches(widget.text) == true)
                  _GuideVideo(
                    key: _videoKey,
                    media: widget.media!,
                    english: en,
                    locked: widget.locked,
                    beforePlay: widget.stop,
                  ),
                OutlinedButton.icon(
                  onPressed: widget.locked
                      ? null
                      : () => widget.listen(widget.text.replaceAll('/', ' ')),
                  icon: const Icon(Icons.volume_up),
                  label: Text(
                    en ? 'Listen · synthetic voice' : '예시 듣기 · 합성 음성',
                  ),
                ),
              ],
              if (_step == 1) ...[
                Text(widget.instruction),
                const SizedBox(height: 12),
                if (!en && firstHangulConsonant(widget.text) != null)
                  Text(
                    '첫소리 확인: ${firstHangulConsonant(widget.text)} → ${widget.text.trim().substring(0, 1)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final chunk in chunks.where(
                      (c) => c.trim().isNotEmpty,
                    ))
                      ActionChip(
                        label: Text(
                          chunk.trim(),
                          style: const TextStyle(fontSize: 22),
                        ),
                        onPressed: widget.locked
                            ? null
                            : () => widget.listen(chunk.trim()),
                      ),
                  ],
                ),
                Text(
                  en
                      ? 'Tap a part to hear it. Pause where comfortable; the spaces are not a timer.'
                      : '부분을 누르면 들을 수 있어요. 편안한 곳에서 쉬세요. 칸 간격은 시간 제한이 아니에요.',
                ),
              ],
              if (_step == 2)
                Text(
                  en
                      ? 'Start recording when ready. Listen to yourself afterwards. You may pause or finish at any time.'
                      : '준비되면 녹음 시작을 눌러요. 끝나면 내 목소리를 들어보세요. 언제든 쉬거나 마쳐도 괜찮아요.',
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.locked ? null : _advance,
                child: Text(
                  en
                      ? (_step == 2 ? 'Ready to practise' : 'Next instruction')
                      : (_step == 2 ? '직접 연습할게요' : '다음 안내'),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  en ? 'Start with guide folded next time' : '다음에는 안내를 접고 시작',
                ),
                value: _quick,
                onChanged: widget.locked ? null : _setQuick,
              ),
            ] else
              TextButton(
                onPressed: widget.locked
                    ? null
                    : () => setState(() {
                        _changed = true;
                        _step = 0;
                        _open = true;
                      }),
                child: Text(en ? 'Show guide again' : '안내 다시 보기'),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuideVideo extends StatefulWidget {
  const _GuideVideo({
    super.key,
    required this.media,
    required this.english,
    required this.locked,
    required this.beforePlay,
  });
  final Future<void> Function() beforePlay;
  final ReviewedSpeechMedia media;
  final bool english, locked;
  @override
  State<_GuideVideo> createState() => _GuideVideoState();
}

class _GuideVideoState extends State<_GuideVideo> with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _error = false;
  int _epoch = 0;
  Future<void> stopMedia() async {
    _epoch++;
    await _controller.pause();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(widget.media.asset);
    _controller
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((Object _) {
          if (mounted) setState(() => _error = true);
        });
    _controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant _GuideVideo old) {
    super.didUpdateWidget(old);
    if (widget.locked) unawaited(stopMedia());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(stopMedia());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_changed);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error || _controller.value.hasError) {
      return Text(
        widget.english
            ? 'Video unavailable. Use the text and audio guide.'
            : '영상을 사용할 수 없어요. 글과 음성 안내를 이용하세요.',
      );
    }
    if (!_controller.value.isInitialized) {
      return Text(widget.english ? 'Loading optional video…' : '선택 영상 불러오는 중…');
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        OutlinedButton(
          onPressed: widget.locked
              ? null
              : () async {
                  if (_controller.value.isPlaying) {
                    await _controller.pause();
                  } else {
                    await widget.beforePlay();
                    final epoch = _epoch;
                    await _controller.seekTo(Duration.zero);
                    if (mounted && epoch == _epoch && !widget.locked) {
                      await _controller.play();
                    }
                  }
                },
          child: Text(
            widget.english ? 'Play / pause demonstration' : '시범 재생·일시정지',
          ),
        ),
      ],
    );
  }
}
