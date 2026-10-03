import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';

/// Permission recovery shared by file recording and live PCM capture.
class MicrophoneAccess {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static Future<bool>? _pending;

  static Future<bool> ensure(
    Future<bool> Function() request, {
    Future<bool> Function()? openSettings,
  }) => _pending ??= _ensure(
    request,
    openSettings ?? openAppSettings,
  ).whenComplete(() => _pending = null);

  static Future<bool> _ensure(
    Future<bool> Function() request,
    Future<bool> Function() openSettings,
  ) async {
    // The recorder asks the OS when permission has not been decided yet.
    // Channel/hardware failures propagate instead of being called a denial.
    if (await request()) return true;
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return false;
    final en =
        AppLocalizations.of(context)?.localeName.startsWith('en') ?? false;
    final settings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(en ? 'Microphone access needed' : '마이크 사용 권한이 필요해요'),
        content: Text(
          en
              ? 'Allow microphone access in the app settings, then return and tap Record again. If access is restricted, check Screen Time or device management.'
              : '앱 설정에서 마이크를 허용한 뒤 돌아와 녹음 버튼을 다시 눌러 주세요. 기기에서 제한한 경우 스크린 타임이나 기기 관리 설정을 확인해 주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(en ? 'Not now' : '나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(en ? 'Open settings' : '설정 열기'),
          ),
        ],
      ),
    );
    if (settings == true) {
      bool opened = false;
      try {
        opened = await openSettings();
      } catch (_) {
        /* Show manual route. */
      }
      if (!opened && context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(en ? 'Open device settings' : '기기 설정을 열어 주세요'),
            content: Text(
              en
                  ? 'In Settings, find SpeechBridge and allow Microphone access.'
                  : '기기의 설정 앱에서 말이음을 찾아 마이크 사용을 허용해 주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(en ? 'OK' : '확인'),
              ),
            ],
          ),
        );
      }
    }
    // Returning from settings must never start an unexpected recording.
    return false;
  }
}
