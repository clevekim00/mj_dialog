import AVFoundation
import Flutter
import permission_handler_apple
import Speech
import UIKit
import webview_flutter_wkwebview

@objc(SafeFlutterViewController)
final class SafeFlutterViewController: FlutterViewController {
  @objc func createTouchRateCorrectionVSyncClientIfNeeded() {
    // Flutter 3.38.5 can crash here on iPadOS 26.5 when creating the
    // high-refresh-rate touch correction VSync client before the platform
    // task runner is usable. Skipping this preserves normal rendering VSync.
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioPlayer: AVAudioPlayer?
  private var audioRecorder: AVAudioRecorder?
  private var audioRecorderPath: String?
  private var audioEventSink: FlutterEventSink?
  private var speechEventSink: FlutterEventSink?
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko_KR"))
  private let speechAudioEngine = AVAudioEngine()
  private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var speechRecognitionTask: SFSpeechRecognitionTask?
  private var didConfigureFlutterChannels = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let permissionRegistrar = registrar(forPlugin: "PermissionHandlerPlugin") {
      PermissionHandlerPlugin.register(with: permissionRegistrar)
    }
    if let webViewRegistrar = registrar(forPlugin: "WebViewFlutterPlugin") {
      WebViewFlutterPlugin.register(with: webViewRegistrar)
    }
    let didFinishLaunching = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    DispatchQueue.main.async { [weak self] in
      self?.configureFlutterChannelsIfNeeded()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.configureFlutterChannelsIfNeeded()
    }
    return didFinishLaunching
  }

  private func configureFlutterChannelsIfNeeded() {
    guard !didConfigureFlutterChannels,
      currentFlutterViewController() != nil
    else {
      return
    }

    configureAudioPlayerChannel()
    configureAudioRecorderChannel()
    configureSharedPreferencesChannel()
    configurePermissionChannel()
    configureSpeechRecognitionChannel()
    didConfigureFlutterChannels = true
  }

  private func currentFlutterViewController() -> FlutterViewController? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller
    }

    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .compactMap { $0.rootViewController as? FlutterViewController }
      .first
  }

  private func configureAudioPlayerChannel() {
    guard let controller = currentFlutterViewController() else {
      return
    }
    configureAudioPlayerChannel(binaryMessenger: controller.binaryMessenger)
  }

  private func configureAudioPlayerChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "speech_rehab/audio_player",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "Audio player unavailable.", details: nil))
        return
      }

      switch call.method {
      case "playFile":
        guard
          let arguments = call.arguments as? [String: Any],
          let path = arguments["path"] as? String
        else {
          result(FlutterError(code: "invalid_args", message: "Missing audio path.", details: nil))
          return
        }
        self.playFile(path: path, result: result)
      case "stop":
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        result(nil)
      case "pause":
        self.audioPlayer?.pause()
        result(nil)
      case "resume":
        self.audioPlayer?.play()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let events = FlutterEventChannel(
      name: "speech_rehab/audio_player/events",
      binaryMessenger: binaryMessenger
    )
    events.setStreamHandler(self)
  }

  private func playFile(path: String, result: FlutterResult) {
    do {
      cancelSpeechRecognition()
      audioRecorder?.stop()
      audioRecorder = nil
      audioRecorderPath = nil

      let fileURL = URL(fileURLWithPath: path)
      guard FileManager.default.fileExists(atPath: fileURL.path) else {
        result(
          FlutterError(
            code: "file_missing",
            message: "Recording file does not exist.",
            details: path
          )
        )
        return
      }

      let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
      let fileSize = attributes[.size] as? NSNumber
      guard fileSize?.intValue ?? 0 > 0 else {
        result(
          FlutterError(
            code: "file_empty",
            message: "Recording file is empty.",
            details: path
          )
        )
        return
      }

      let session = AVAudioSession.sharedInstance()
      try session.setActive(false, options: .notifyOthersOnDeactivation)
      try session.setCategory(
        .playAndRecord,
        mode: .default,
        options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
      )
      try session.setActive(true, options: .notifyOthersOnDeactivation)
      try session.overrideOutputAudioPort(.speaker)

      audioPlayer?.stop()
      let player = try AVAudioPlayer(contentsOf: fileURL)
      player.delegate = self
      player.volume = 1.0
      player.numberOfLoops = 0
      audioPlayer = player
      guard player.prepareToPlay(), player.duration > 0 else {
        audioPlayer = nil
        result(
          FlutterError(
            code: "playback_prepare_failed",
            message: "Failed to prepare recording playback.",
            details: [
              "path": path,
              "fileSize": fileSize?.intValue ?? 0,
              "duration": player.duration,
            ]
          )
        )
        return
      }

      guard player.play() else {
        audioPlayer = nil
        result(
          FlutterError(
            code: "playback_start_failed",
            message: "AVAudioPlayer did not start playback.",
            details: [
              "path": path,
              "fileSize": fileSize?.intValue ?? 0,
              "duration": player.duration,
            ]
          )
        )
        return
      }

      debugPrint(
        "Playback started path=\(path) size=\(fileSize?.intValue ?? 0) duration=\(player.duration)"
      )
      result(nil)
    } catch {
      result(
        FlutterError(
          code: "playback_failed",
          message: "Failed to play audio file.",
          details: error.localizedDescription
        )
      )
    }
  }

  private func configureAudioRecorderChannel() {
    guard let controller = currentFlutterViewController() else {
      return
    }
    configureAudioRecorderChannel(binaryMessenger: controller.binaryMessenger)
  }

  private func configureAudioRecorderChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "speech_rehab/audio_recorder",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "Audio recorder unavailable.", details: nil))
        return
      }

      switch call.method {
      case "hasPermission":
        self.requestRecordPermission(result: result)
      case "start":
        guard
          let arguments = call.arguments as? [String: Any],
          let path = arguments["path"] as? String
        else {
          result(FlutterError(code: "invalid_args", message: "Missing recording path.", details: nil))
          return
        }
        self.startRecording(path: path, result: result)
      case "stop":
        self.stopRecording(result: result)
      case "dispose":
        self.audioRecorder?.stop()
        self.audioRecorder = nil
        self.audioRecorderPath = nil
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func requestRecordPermission(result: @escaping FlutterResult) {
    let session = AVAudioSession.sharedInstance()
    switch session.recordPermission {
    case .granted:
      result(true)
    case .denied:
      result(false)
    case .undetermined:
      session.requestRecordPermission { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    @unknown default:
      result(false)
    }
  }

  private func startRecording(path: String, result: FlutterResult) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
      try session.setActive(true)

      audioRecorder?.stop()

      let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44_100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 128_000,
      ]

      let recorder = try AVAudioRecorder(url: URL(fileURLWithPath: path), settings: settings)
      recorder.prepareToRecord()
      if recorder.record() {
        audioRecorder = recorder
        audioRecorderPath = path
        result(nil)
      } else {
        result(
          FlutterError(
            code: "recording_failed",
            message: "Failed to start recording.",
            details: nil
          )
        )
      }
    } catch {
      result(
        FlutterError(
          code: "recording_failed",
          message: "Failed to start recording.",
          details: error.localizedDescription
        )
      )
    }
  }

  private func stopRecording(result: FlutterResult) {
    let path = audioRecorderPath
    audioRecorder?.stop()
    audioRecorder = nil
    audioRecorderPath = nil
    result(path)
  }

  private func configureSharedPreferencesChannel() {
    guard let controller = currentFlutterViewController() else {
      return
    }
    configureSharedPreferencesChannel(binaryMessenger: controller.binaryMessenger)
  }

  private func configureSharedPreferencesChannel(binaryMessenger messenger: FlutterBinaryMessenger) {
    let codec = FlutterStandardMessageCodec.sharedInstance()
    let prefix =
      "dev.flutter.pigeon.shared_preferences_foundation.LegacyUserDefaultsApi"

    FlutterBasicMessageChannel(
      name: "\(prefix).remove",
      binaryMessenger: messenger,
      codec: codec
    ).setMessageHandler { message, reply in
      guard
        let arguments = message as? [Any?],
        let key = arguments.first as? String
      else {
        reply(["invalid_args", "Missing preference key.", nil])
        return
      }
      UserDefaults.standard.removeObject(forKey: key)
      reply([nil])
    }

    FlutterBasicMessageChannel(
      name: "\(prefix).setBool",
      binaryMessenger: messenger,
      codec: codec
    ).setMessageHandler { message, reply in
      self.setPreferenceValue(message: message, reply: reply)
    }

    FlutterBasicMessageChannel(
      name: "\(prefix).setDouble",
      binaryMessenger: messenger,
      codec: codec
    ).setMessageHandler { message, reply in
      self.setPreferenceValue(message: message, reply: reply)
    }

    FlutterBasicMessageChannel(
      name: "\(prefix).setValue",
      binaryMessenger: messenger,
      codec: codec
    ).setMessageHandler { message, reply in
      self.setPreferenceValue(message: message, reply: reply)
    }

    FlutterBasicMessageChannel(
      name: "\(prefix).getAll",
      binaryMessenger: messenger,
      codec: codec
    ).setMessageHandler { message, reply in
      guard
        let arguments = message as? [Any?],
        let keyPrefix = arguments.first as? String
      else {
        reply(["invalid_args", "Missing preference prefix.", nil])
        return
      }

      let allowList = arguments.count > 1 ? arguments[1] as? [String] : nil
      reply([self.getPreferenceValues(prefix: keyPrefix, allowList: allowList)])
    }

    FlutterBasicMessageChannel(
      name: "\(prefix).clear",
      binaryMessenger: messenger,
      codec: codec
    ).setMessageHandler { message, reply in
      guard
        let arguments = message as? [Any?],
        let keyPrefix = arguments.first as? String
      else {
        reply(["invalid_args", "Missing preference prefix.", nil])
        return
      }

      let allowList = arguments.count > 1 ? arguments[1] as? [String] : nil
      for key in self.preferenceKeys(prefix: keyPrefix, allowList: allowList) {
        UserDefaults.standard.removeObject(forKey: key)
      }
      reply([true])
    }
  }

  private func setPreferenceValue(
    message: Any?,
    reply: @escaping FlutterReply
  ) {
    guard
      let arguments = message as? [Any?],
      arguments.count >= 2,
      let key = arguments[0] as? String,
      let value = arguments[1]
    else {
      reply(["invalid_args", "Missing preference key or value.", nil])
      return
    }

    UserDefaults.standard.set(value, forKey: key)
    reply([nil])
  }

  private func getPreferenceValues(
    prefix: String,
    allowList: [String]?
  ) -> [String: Any] {
    let keys = preferenceKeys(prefix: prefix, allowList: allowList)
    var values: [String: Any] = [:]
    for key in keys {
      if let value = UserDefaults.standard.object(forKey: key) {
        values[key] = value
      }
    }
    return values
  }

  private func preferenceKeys(prefix: String, allowList: [String]?) -> [String] {
    let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
    return allKeys.filter { key in
      if let allowList {
        return allowList.contains(key)
      }
      return key.hasPrefix(prefix)
    }
  }

  private func configurePermissionChannel() {
    guard let controller = currentFlutterViewController() else {
      return
    }
    configurePermissionChannel(binaryMessenger: controller.binaryMessenger)
  }

  private func configurePermissionChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "speech_rehab/permissions",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "Permission service unavailable.", details: nil))
        return
      }

      switch call.method {
      case "hasAll":
        result(self.hasSpeechAndMicrophonePermission())
      case "requestAll":
        self.requestSpeechAndMicrophonePermission(result: result)
      case "openSettings":
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(nil)
          return
        }
        UIApplication.shared.open(url)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func hasSpeechAndMicrophonePermission() -> Bool {
    return AVAudioSession.sharedInstance().recordPermission == .granted
      && SFSpeechRecognizer.authorizationStatus() == .authorized
  }

  private func requestSpeechAndMicrophonePermission(result: @escaping FlutterResult) {
    let group = DispatchGroup()
    var hasMicrophone = false
    var hasSpeech = false

    group.enter()
    let session = AVAudioSession.sharedInstance()
    switch session.recordPermission {
    case .granted:
      hasMicrophone = true
      group.leave()
    case .denied:
      hasMicrophone = false
      group.leave()
    case .undetermined:
      session.requestRecordPermission { granted in
        hasMicrophone = granted
        group.leave()
      }
    @unknown default:
      hasMicrophone = false
      group.leave()
    }

    group.enter()
    switch SFSpeechRecognizer.authorizationStatus() {
    case .authorized:
      hasSpeech = true
      group.leave()
    case .denied, .restricted:
      hasSpeech = false
      group.leave()
    case .notDetermined:
      SFSpeechRecognizer.requestAuthorization { status in
        hasSpeech = status == .authorized
        group.leave()
      }
    @unknown default:
      hasSpeech = false
      group.leave()
    }

    group.notify(queue: .main) {
      result(hasMicrophone && hasSpeech)
    }
  }

  private func configureSpeechRecognitionChannel() {
    guard let controller = currentFlutterViewController() else {
      return
    }
    configureSpeechRecognitionChannel(binaryMessenger: controller.binaryMessenger)
  }

  private func configureSpeechRecognitionChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "speech_rehab/speech_recognition",
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "Speech recognizer unavailable.", details: nil))
        return
      }

      switch call.method {
      case "initialize":
        self.requestSpeechAndMicrophonePermission(result: result)
      case "startListening":
        self.startSpeechRecognition(result: result)
      case "stopListening":
        self.stopSpeechRecognition()
        result(nil)
      case "cancelListening":
        self.cancelSpeechRecognition()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let events = FlutterEventChannel(
      name: "speech_rehab/speech_recognition/events",
      binaryMessenger: binaryMessenger
    )
    events.setStreamHandler(
      ClosureStreamHandler(
        onListen: { [weak self] _, eventSink in
          self?.speechEventSink = eventSink
          return nil
        },
        onCancel: { [weak self] _ in
          self?.speechEventSink = nil
          return nil
        }
      )
    )
  }

  private func startSpeechRecognition(result: FlutterResult) {
    guard hasSpeechAndMicrophonePermission() else {
      result(false)
      return
    }

    guard let recognizer = speechRecognizer, recognizer.isAvailable else {
      result(false)
      return
    }

    do {
      cancelSpeechRecognition()

      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
      try session.setActive(true, options: .notifyOthersOnDeactivation)

      let request = SFSpeechAudioBufferRecognitionRequest()
      request.shouldReportPartialResults = true
      speechRecognitionRequest = request

      let inputNode = speechAudioEngine.inputNode
      let recordingFormat = inputNode.outputFormat(forBus: 0)
      inputNode.removeTap(onBus: 0)
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
        self?.speechRecognitionRequest?.append(buffer)
      }

      speechRecognitionTask = recognizer.recognitionTask(with: request) { [weak self] recognitionResult, error in
        guard let self else { return }

        if let recognitionResult {
          self.speechEventSink?([
            "text": recognitionResult.bestTranscription.formattedString,
            "isFinal": recognitionResult.isFinal,
          ])

          if recognitionResult.isFinal {
            self.stopSpeechRecognition()
          }
        }

        if let error {
          debugPrint("Speech recognition failed: \(error.localizedDescription)")
          self.stopSpeechRecognition()
        }
      }

      speechAudioEngine.prepare()
      try speechAudioEngine.start()
      result(true)
    } catch {
      debugPrint("Speech recognition start failed: \(error.localizedDescription)")
      cancelSpeechRecognition()
      result(false)
    }
  }

  private func stopSpeechRecognition() {
    if speechAudioEngine.isRunning {
      speechAudioEngine.stop()
      speechAudioEngine.inputNode.removeTap(onBus: 0)
    }
    speechRecognitionRequest?.endAudio()
    speechRecognitionRequest = nil
    speechRecognitionTask = nil
  }

  private func cancelSpeechRecognition() {
    if speechAudioEngine.isRunning {
      speechAudioEngine.stop()
      speechAudioEngine.inputNode.removeTap(onBus: 0)
    }
    speechRecognitionRequest?.endAudio()
    speechRecognitionRequest = nil
    speechRecognitionTask?.cancel()
    speechRecognitionTask = nil
  }
}

final class ClosureStreamHandler: NSObject, FlutterStreamHandler {
  private let onListenCallback: (Any?, @escaping FlutterEventSink) -> FlutterError?
  private let onCancelCallback: (Any?) -> FlutterError?

  init(
    onListen: @escaping (Any?, @escaping FlutterEventSink) -> FlutterError?,
    onCancel: @escaping (Any?) -> FlutterError?
  ) {
    self.onListenCallback = onListen
    self.onCancelCallback = onCancel
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    return onListenCallback(arguments, events)
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return onCancelCallback(arguments)
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    audioEventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    audioEventSink = nil
    return nil
  }
}

extension AppDelegate: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if audioPlayer === player {
      audioPlayer = nil
    }
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    audioEventSink?("complete")
  }
}
