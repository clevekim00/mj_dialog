import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PermissionService {
  static Future<bool> hasAllPermissions() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return true;
    }

    // Check Microphone
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) return false;

    // Check Speech Recognition (skip on Desktop)
    if (Platform.isIOS || Platform.isAndroid) {
      final speechStatus = await Permission.speech.status;
      if (!speechStatus.isGranted) return false;
    }

    return true;
  }

  static Future<bool> requestAllPermissions() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return true;
    }

    final statuses = await [
      Permission.microphone,
      if (Platform.isIOS || Platform.isAndroid) Permission.speech,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}
