import 'dart:async';
import '../art/pixel_game_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../../../services/audio/stt_service.dart';
import '../../../services/microphone_access.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../rehab/view/rehab_ui.dart';
import 'syllable_runner_engine.dart';

class SyllableRunnerScreen extends StatefulWidget {
  const SyllableRunnerScreen({super.key, this.speech});
  final SttService? speech;
  @override
  State<SyllableRunnerScreen> createState() => _RunnerState();
}

class _RunnerState extends State<SyllableRunnerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final SttService _speech;
  final _gameFocus = FocusNode(debugLabel: 'Syllable runner keyboard');
  SyllableRunnerEngine _game = SyllableRunnerEngine();
  late final Ticker _ticker;
  Duration _previous = Duration.zero;
  bool _whiteCat = false;
  String _consonant = 'ㄱ', _heard = '';
  bool _playing = false,
      _voice = false,
      _listening = false,
      _opening = false,
      _disposed = false;
  int _generation = 0;
  String? _notice;
  Timer? _window;
  Future<void>? _stopping;
  bool get en => rehabEnglish(context);
  String tr(String ko, String english) => en ? english : ko;
  @override
  void initState() {
    super.initState();
    _speech = widget.speech ?? SttService(languageTag: 'ko-KR');
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _previous).inMicroseconds / 1000000;
      _previous = elapsed;
      if (!_playing) return;
      final wasActing = _game.actionActive;
      setState(() => _game.tick(dt));
      if (_game.finished || _game.failed) {
        _playing = false;
        _ticker.stop();
        unawaited(_stopVoice());
      } else if (wasActing && !_game.actionActive && _voice) {
        unawaited(_listen());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  Future<void> _stopVoice() async {
    _generation++;
    _window?.cancel();
    _listening = false;
    await (_stopping ??= _speech.stopListening().whenComplete(
      () => _stopping = null,
    ));
  }

  void _pause() {
    if (!mounted) return;
    _ticker.stop();
    setState(() => _playing = false);
    unawaited(_stopVoice());
  }

  Future<void> _start(bool voice) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _notice = null;
    });
    try {
      if (voice) {
        // permission_handler has no macOS implementation. The desktop speech
        // plugin requests both microphone and speech authorization itself.
        if ((defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.android) &&
            !await MicrophoneAccess.ensure(
              () async => (await Permission.microphone.request()).isGranted,
            )) {
          return;
        }
        if (!await _speech.init()) {
          if (mounted) {
            setState(
              () => _notice = tr(
                '음성 인식을 사용할 수 없어요. OS의 음성 인식 권한·한국어 지원을 확인하거나 버튼으로 시작하세요.',
                'Speech recognition unavailable. Check speech permission/Korean support or start with buttons.',
              ),
            );
          }
          return;
        }
      }
      if (!mounted ||
          _disposed ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
        return;
      }
      setState(() {
        if (_game.finished || _game.failed) return;
        _voice = voice;
        _playing = true;
        _heard = '';
      });
      _previous = Duration.zero;
      _ticker.start();
      _gameFocus.requestFocus();
      if (voice) await _listen();
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = tr(
            '마이크에 연결하지 못했어요. 버튼으로도 놀 수 있어요.',
            'Microphone unavailable. You can play using buttons.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _listen() async {
    if (!_playing || !_voice || _disposed || _game.actionActive) return;
    await _stopVoice();
    if (!_playing || !_voice || _disposed || _game.actionActive) return;
    final generation = ++_generation;
    _heard = '';
    final ok = await _speech.startListening(
      contextualStrings: RunnerAction.values
          .map((a) => runnerSyllable(_consonant, a))
          .toList(),
      onResult: (text, finalResult) async {
        if (!mounted || !_playing || generation != _generation) return;
        setState(() => _heard = text);
        final command = runnerCommand(text, _consonant);
        if (command != null) _act(command, true);
      },
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _listening = ok;
      if (!ok) {
        _voice = false;
        _notice = tr(
          '음성 연결이 끊겼어요. 버튼으로 계속하거나 잠시 쉬고 다시 시작하세요.',
          'Speech disconnected. Continue with buttons or pause and restart.',
        );
      }
    });
    if (ok) {
      _window = Timer(const Duration(seconds: 5), () {
        if (generation == _generation && _playing) unawaited(_listen());
      });
    }
  }

  void _act(RunnerAction action, bool voice) {
    if (!_playing) return;
    if (_game.command(action, voice: voice)) {
      setState(() => _notice = null);
      unawaited(_stopVoice());
    }
  }

  void _configure(VoidCallback change) {
    _pause();
    setState(change);
  }

  Future<void> _chooseConsonant() async {
    if (_playing) _pause();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr('연습할 자음을 선택하세요', 'Choose a Korean consonant'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    mainAxisExtent: 90,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: runnerConsonants.length,
                  itemBuilder: (context, index) {
                    final c = runnerConsonants[index];
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: c == _consonant
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                      ),
                      onPressed: () => Navigator.pop(sheetContext, c),
                      child: FittedBox(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${runnerSyllable(c, RunnerAction.jump)} / ${runnerSyllable(c, RunnerAction.duck)}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null || selected == _consonant) return;
    setState(() {
      _consonant = selected;
      _game = SyllableRunnerEngine(mode: _game.mode);
      _heard = '';
      _notice = null;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _playing = false;
    _generation++;
    _window?.cancel();
    _ticker.dispose();
    _gameFocus.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_speech.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jump = runnerSyllable(_consonant, RunnerAction.jump),
        duck = runnerSyllable(_consonant, RunnerAction.duck);
    return Focus(
      focusNode: _gameFocus,
      onKeyEvent: (node, event) {
        if (!_playing || ModalRoute.of(context)?.isCurrent != true) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        if (key != LogicalKeyboardKey.arrowUp &&
            key != LogicalKeyboardKey.arrowDown &&
            key != LogicalKeyboardKey.space) {
          return KeyEventResult.ignored;
        }
        if (event is KeyDownEvent) {
          _act(
            key == LogicalKeyboardKey.arrowDown
                ? RunnerAction.duck
                : RunnerAction.jump,
            false,
          );
        }
        return KeyEventResult.handled;
      },
      child: RehabPage(
        title: tr('한 음절 모험 달리기', 'Syllable adventure run'),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_notice != null) Text(_notice!),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (!_playing && !_game.finished && !_game.failed) ...[
                  FilledButton(
                    onPressed: _opening ? null : () => _start(true),
                    child: Text(
                      tr('목소리로 시작 / 이어 하기', 'Start / resume with voice'),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _opening ? null : () => _start(false),
                    child: Text(
                      tr('버튼으로 시작 / 이어 하기', 'Start / resume with buttons'),
                    ),
                  ),
                ],

                if (_game.failed && _game.retries > 0)
                  FilledButton(
                    onPressed: () {
                      setState(() => _game.retry());
                    },
                    child: Text(
                      tr(
                        '다시 도전 (${_game.retries}회 남음)',
                        'Retry (${_game.retries} left)',
                      ),
                    ),
                  ),
                if (_game.finished && !_game.campaignFinished)
                  FilledButton(
                    onPressed: () {
                      setState(() => _game.nextStage());
                    },
                    child: Text(tr('다음 스테이지', 'Next stage')),
                  ),
                if (_game.campaignFinished ||
                    (_game.failed && _game.retries == 0))
                  FilledButton(
                    onPressed: () {
                      setState(
                        () => _game = SyllableRunnerEngine(mode: _game.mode),
                      );
                    },
                    child: Text(tr('처음부터 새 게임', 'New game')),
                  ),
                FilledButton.icon(
                  onPressed: _playing
                      ? () => _act(RunnerAction.jump, false)
                      : null,
                  icon: const Icon(Icons.arrow_upward),
                  label: Text('$jump · ${tr('점프', 'Jump')}'),
                ),
                FilledButton.icon(
                  onPressed: _playing
                      ? () => _act(RunnerAction.duck, false)
                      : null,
                  icon: const Icon(Icons.arrow_downward),
                  label: Text('$duck · ${tr('숙이기', 'Duck')}'),
                ),
                if (_playing)
                  OutlinedButton(
                    onPressed: _pause,
                    child: Text(tr('잠시 쉬기', 'Pause')),
                  ),
              ],
            ),
          ],
        ),
        children: [
          if (!_playing) ...[
            Text(
              tr(
                'ㅏ는 점프, ㅓ는 숙이기! 키보드는 ↑ 또는 스페이스로 점프, ↓로 숙여요. 장애물이 멀리 있어도 자유롭게 움직여요. 장애물이 가까워지면 알맞은 동작으로 통과해요.',
                'Add ㅏ to jump or ㅓ to duck. Keyboard: ↑ or Space to jump, ↓ to duck. Move freely, then use the matching action when an obstacle is near.',
              ),
            ),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: Text(
                    tr('치즈 · 노란 코숏 · 수컷', 'Cheese · yellow shorthair · male'),
                  ),
                  selected: !_whiteCat,
                  onSelected: _opening
                      ? null
                      : (_) => _configure(() => _whiteCat = false),
                ),
                ChoiceChip(
                  label: Text(
                    tr('모찌 · 흰 코숏 · 암컷', 'Mochi · white shorthair · female'),
                  ),
                  selected: _whiteCat,
                  onSelected: _opening
                      ? null
                      : (_) => _configure(() => _whiteCat = true),
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              children: [
                for (final mode in RunnerMode.values)
                  ChoiceChip(
                    label: Text(
                      mode == RunnerMode.comfortable
                          ? tr('편안 모드', 'Comfort mode')
                          : tr('도전 모드', 'Challenge mode'),
                    ),
                    selected: _game.mode == mode,
                    onSelected: _opening
                        ? null
                        : (_) {
                            if (_game.mode != mode) {
                              _configure(
                                () => _game = SyllableRunnerEngine(mode: mode),
                              );
                            }
                          },
                  ),
              ],
            ),
            Text(
              _game.mode == RunnerMode.comfortable
                  ? tr(
                      '시간 제한 없이 기다려요. 모드를 바꾸면 새 게임이 시작돼요.',
                      'Obstacles wait without a time limit. Changing mode starts a new game.',
                    )
                  : tr(
                      '장애물이 도착한 뒤 3초 안에 피하세요. 충돌하면 멈추며 스테이지마다 재시도 2회가 있어요.',
                      'Dodge within 3 seconds of arrival. A collision stops the run. Each stage allows 2 retries.',
                    ),
            ),
          ],
          Text(
            '${tr('스테이지', 'Stage')} ${_game.stage + 1} / 3 · ${[tr('햇살 초원', 'Sunny meadow'), tr('구름 언덕', 'Cloud hills'), tr('별빛 산책', 'Starlight trail')][_game.stage]}',
          ),
          if (_game.mode == RunnerMode.challenge)
            Text(
              tr('남은 재시도 ${_game.retries}회', 'Retries left: ${_game.retries}'),
            ),
          if (_game.failed)
            Text(
              tr(
                '앗, 장애물에 닿았어요. 잠깐 쉬고 다시 도전해요.',
                'Oops, an obstacle! Rest before trying again.',
              ),
            ),
          if (!_playing)
            OutlinedButton.icon(
              onPressed: _opening ? null : _chooseConsonant,
              icon: const Icon(Icons.grid_view_rounded),
              label: Text(
                '${tr('자음 선택', 'Choose consonant')} · $_consonant  ($jump / $duck)',
              ),
            ),
          const SizedBox(height: 12),
          Text(
            _game.finished
                ? tr('도착했어요! 잘 쉬어 주세요.', 'You arrived! Take a break.')
                : '${runnerSyllable(_consonant, _game.requiredAction)}!  ${_game.requiredAction == RunnerAction.jump ? tr('상자 위로 점프', 'Jump over the crate') : tr('나뭇가지 아래로 숙이기', 'Duck under the branch')}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Semantics(
            label: tr(
              '장애물 ${_game.cleared}개 통과. ${_game.waiting ? '말하기를 기다려요' : '달리는 중'}',
              '${_game.cleared} obstacles passed. ${_game.waiting ? 'Waiting for your command' : 'Running'}',
            ),
            child: SizedBox(
              height: 270,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  painter: _RunnerPainter(_game, _playing, _whiteCat),
                ),
              ),
            ),
          ),
          LinearProgressIndicator(value: _game.cleared / _game.goal),
          Text('${_game.cleared} / ${_game.goal}'),
          Text(
            tr(
              '목소리 동작 ${_game.voiceStars} · 버튼 동작 ${_game.buttonStars} · 건너뜀 ${_game.skipped}',
              'Voice actions ${_game.voiceStars} · Button actions ${_game.buttonStars} · Skipped ${_game.skipped}',
            ),
          ),
          if (_voice && _playing)
            Text(
              _listening
                  ? tr('듣고 있어요 · $_heard', 'Listening · $_heard')
                  : tr(
                      '잠깐 쉬어요 · 다음 말을 준비해요',
                      'Rest briefly · preparing the next cue',
                    ),
            ),
          if (_playing && _game.mode == RunnerMode.comfortable)
            TextButton(
              onPressed: _game.resolving
                  ? null
                  : () {
                      setState(() => _game.skip());
                    },
              child: Text(tr('이 장애물 건너뛰기', 'Skip this obstacle')),
            ),
          Text(
            tr(
              '음성 조작은 한국어 음성 인식을 사용하며 OS 설정에 따라 네트워크가 필요할 수 있어요. 인식 결과는 발음 점수가 아니에요. 이 게임은 MPT 측정이 아니며 녹음 파일을 저장하지 않아요.',
              'Voice controls use Korean OS speech recognition, which may require a network. Recognition is not a pronunciation score. This game is not an MPT test and saves no recordings.',
            ),
          ),
        ],
      ),
    );
  }
}

class _RunnerPainter extends CustomPainter {
  _RunnerPainter(this.game, this.playing, this.whiteCat);
  final bool whiteCat;
  final SyllableRunnerEngine game;
  final bool playing;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, ground = (h * .8 / 4).floor() * 4.0;
    PixelGameArt.scenery(
      canvas,
      size,
      scroll: game.distance,
      night: game.stage == 2,
    );
    final paint = Paint()..isAntiAlias = false;
    if (game.stage == 1) {
      for (var i = 0; i < 5; i++) {
        final x = ((i * 190 - game.distance * 8) % (w + 190)) - 95;
        for (var step = 0; step < 4; step++) {
          canvas.drawRect(
            Rect.fromLTWH(
              x + step * 12,
              ground - 20 - step * 12,
              120 - step * 24,
              20 + step * 12,
            ),
            paint..color = const Color(0xff82bcb1),
          );
        }
      }
    }
    if (game.stage == 2) {
      for (var i = 0; i < 7; i++) {
        PixelGameArt.star(canvas, Offset((i + .5) * w / 7, 24 + (i % 3) * 18));
      }
    }

    if (!game.finished) {
      final x = (game.obstacleX * w / 4).round() * 4.0;
      if (game.requiredAction == RunnerAction.jump) {
        canvas.drawRect(
          Rect.fromLTWH(x - 16, ground - 36, 32, 36),
          paint..color = const Color(0xff965e48),
        );
        canvas.drawRect(
          Rect.fromLTWH(x - 12, ground - 32, 24, 4),
          paint..color = const Color(0xffefba72),
        );
        canvas.drawRect(Rect.fromLTWH(x - 4, ground - 28, 8, 24), paint);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(x - 24, ground - 84, 48, 40),
          paint..color = const Color(0xff765278),
        );
        canvas.drawRect(
          Rect.fromLTWH(x - 28, ground - 88, 56, 8),
          paint..color = const Color(0xffc2a1c5),
        );
      }
      PixelGameArt.star(canvas, Offset(x, ground - 110));
    }
    PixelGameArt.cat(
      canvas,
      Offset(w * .25, ground - game.jumpHeight * h),
      white: whiteCat,
      duck: game.action == RunnerAction.duck,
      stride: playing && !game.waiting && (game.distance * 6).floor().isEven,
    );
  }

  @override
  bool shouldRepaint(covariant _RunnerPainter oldDelegate) => true;
}
