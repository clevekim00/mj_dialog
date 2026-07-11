import Cocoa
import AVFoundation
import FlutterMacOS
import ObjectiveC

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

final class MacAudioPlayerChannel: NSObject, FlutterStreamHandler, AVAudioPlayerDelegate {
  private static var associationKey = 0
  private var player: AVAudioPlayer?
  private var eventSink: FlutterEventSink?

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "speech_rehab/audio_player",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let events = FlutterEventChannel(
      name: "speech_rehab/audio_player/events",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let instance = MacAudioPlayerChannel()

    channel.setMethodCallHandler { [weak instance] call, result in
      guard let instance else {
        result(
          FlutterError(
            code: "unavailable",
            message: "Audio player is unavailable.",
            details: nil
          )
        )
        return
      }

      switch call.method {
      case "playFile":
        guard
          let arguments = call.arguments as? [String: Any],
          let path = arguments["path"] as? String
        else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "Missing audio path.",
              details: nil
            )
          )
          return
        }
        instance.playFile(path: path, result: result)
      case "stop":
        instance.player?.stop()
        instance.player = nil
        result(nil)
      case "pause":
        instance.player?.pause()
        result(nil)
      case "resume":
        guard let player = instance.player else {
          result(nil)
          return
        }
        player.play()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    events.setStreamHandler(instance)
    objc_setAssociatedObject(
      controller,
      &associationKey,
      instance,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func playFile(path: String, result: FlutterResult) {
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

    do {
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

      player?.stop()
      let nextPlayer = try AVAudioPlayer(contentsOf: fileURL)
      nextPlayer.delegate = self
      nextPlayer.volume = 1.0
      nextPlayer.numberOfLoops = 0
      player = nextPlayer

      guard nextPlayer.prepareToPlay(), nextPlayer.duration > 0 else {
        player = nil
        result(
          FlutterError(
            code: "playback_prepare_failed",
            message: "Failed to prepare recording playback.",
            details: [
              "path": path,
              "fileSize": fileSize?.intValue ?? 0,
              "duration": nextPlayer.duration,
            ]
          )
        )
        return
      }

      guard nextPlayer.play() else {
        player = nil
        result(
          FlutterError(
            code: "playback_start_failed",
            message: "AVAudioPlayer did not start playback.",
            details: [
              "path": path,
              "fileSize": fileSize?.intValue ?? 0,
              "duration": nextPlayer.duration,
            ]
          )
        )
        return
      }

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

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if self.player === player {
      self.player = nil
    }
    eventSink?("complete")
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    if self.player === player {
      self.player = nil
    }
    eventSink?(
      FlutterError(
        code: "playback_decode_failed",
        message: "Audio playback failed while decoding.",
        details: error?.localizedDescription
      )
    )
  }
}
