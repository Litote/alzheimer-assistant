import AVFoundation
import Flutter

/// Native plugin that forces speaker routing when using AVAudioSessionCategoryPlayAndRecord.
///
/// flutter_pcm_sound sets the category without AVAudioSessionCategoryOptionDefaultToSpeaker,
/// which causes iOS to route audio through the earpiece (quiet) instead of the speaker.
/// This plugin must be called after flutter_pcm_sound's setup() completes.
///
/// Note: allowBluetooth is intentionally omitted — it activates HFP (Hands-Free Profile),
/// which applies a reduced output gain and can route audio unexpectedly when any
/// Bluetooth device is remembered by the system, even if none is physically connected.
class AudioRoutingPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "alzheimer_assistant/audio",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(AudioRoutingPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "overrideToSpeaker" else {
      result(FlutterMethodNotImplemented)
      return
    }
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playAndRecord,
        options: [.defaultToSpeaker]
      )
      result(nil)
    } catch {
      result(
        FlutterError(
          code: "AVAudioSessionError",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }
}
