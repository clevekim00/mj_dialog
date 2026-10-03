import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../rehab/view/rehab_ui.dart';

/// Image stays in memory. Only the reviewed crop is passed to local OCR.
class ImageReviewScreen extends StatefulWidget {
  const ImageReviewScreen({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<ImageReviewScreen> createState() => _ImageReviewState();
}

class _ImageReviewState extends State<ImageReviewScreen> {
  ui.Image? _image;
  RangeValues _horizontal = const RangeValues(0, 1),
      _vertical = const RangeValues(0, 1);
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (mounted) {
        setState(() => _image = frame.image);
      } else {
        frame.image.dispose();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open image / 이미지를 열지 못했어요.');
      }
    }
  }

  Future<void> _rotate() async {
    final source = _image!;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.translate(source.height.toDouble(), 0);
    canvas.rotate(1.5707963267948966);
    canvas.drawImage(source, Offset.zero, Paint());
    final picture = recorder.endRecording();
    final rotated = await picture.toImage(source.height, source.width);
    picture.dispose();
    if (!mounted) {
      rotated.dispose();
      return;
    }
    setState(() {
      _image = rotated;
      _horizontal = const RangeValues(0, 1);
      _vertical = const RangeValues(0, 1);
    });
    source.dispose();
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      final image = _image!;
      final rect = Rect.fromLTRB(
        _horizontal.start * image.width,
        _vertical.start * image.height,
        _horizontal.end * image.width,
        _vertical.end * image.height,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        rect,
        Rect.fromLTWH(0, 0, rect.width, rect.height),
        Paint(),
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(
        rect.width.round().clamp(1, image.width),
        rect.height.round().clamp(1, image.height),
      );
      picture.dispose();
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      cropped.dispose();
      if (mounted) Navigator.pop(context, data!.buffer.asUint8List());
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not crop image / 자르지 못했어요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = rehabEnglish(context);
    return RehabPage(
      title: en ? 'Review image' : '이미지 확인',
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _busy || _image == null ? null : _accept,
          child: Text(en ? 'Use selected area' : '선택한 영역에서 글 가져오기'),
        ),
      ),
      children: [
        Text(
          en
              ? 'Crop out private details. Adjust the horizontal and vertical ranges, then extract text.'
              : '개인정보나 필요 없는 부분을 잘라내세요. 가로·세로 범위를 조절한 뒤 글을 가져옵니다.',
        ),
        if (_error != null) Text(_error!),
        if (_image == null)
          const LinearProgressIndicator()
        else ...[
          SizedBox(
            height: 340,
            child: CustomPaint(
              painter: _CropPreview(_image!, _horizontal, _vertical),
            ),
          ),
          Text(en ? 'Left / right crop' : '왼쪽·오른쪽 자르기'),
          RangeSlider(
            values: _horizontal,
            divisions: 100,
            labels: RangeLabels(
              '${(_horizontal.start * 100).round()}%',
              '${(_horizontal.end * 100).round()}%',
            ),
            onChanged: _busy
                ? null
                : (v) {
                    if (v.end - v.start >= .05) {
                      setState(() => _horizontal = v);
                    }
                  },
          ),
          Text(en ? 'Top / bottom crop' : '위·아래 자르기'),
          RangeSlider(
            values: _vertical,
            divisions: 100,
            labels: RangeLabels(
              '${(_vertical.start * 100).round()}%',
              '${(_vertical.end * 100).round()}%',
            ),
            onChanged: _busy
                ? null
                : (v) {
                    if (v.end - v.start >= .05) setState(() => _vertical = v);
                  },
          ),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      await _rotate();
                    } catch (_) {
                      if (mounted) {
                        setState(
                          () => _error = en
                              ? 'Could not rotate image.'
                              : '이미지를 회전하지 못했어요.',
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            icon: const Icon(Icons.rotate_right),
            label: Text(en ? 'Rotate 90°' : '90도 회전'),
          ),
        ],
      ],
    );
  }
}

class _CropPreview extends CustomPainter {
  _CropPreview(this.image, this.horizontal, this.vertical);
  final ui.Image image;
  final RangeValues horizontal, vertical;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / image.width).clamp(
      0.0,
      size.height / image.height,
    );
    final width = (image.width * scale).toDouble(),
        height = (image.height * scale).toDouble();
    final rect = Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint(),
    );
    final crop = Rect.fromLTRB(
      rect.left + horizontal.start * width,
      rect.top + vertical.start * height,
      rect.left + horizontal.end * width,
      rect.top + vertical.end * height,
    );
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRect(crop);
    canvas.drawPath(mask, Paint()..color = Colors.black54);
    canvas.drawRect(
      crop,
      Paint()
        ..color = Colors.lightBlueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _CropPreview old) => true;
}
