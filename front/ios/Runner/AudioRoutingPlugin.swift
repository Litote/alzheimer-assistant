import AVFoundation
import Flutter

/// Native plugin that manages AVAudioSession for voice chat and recovers from interruptions.
///
/// Two Dart-callable methods are exposed:
/// - `prepareAudioSession`: configure + activate the session BEFORE flutter_pcm_sound starts
///   its engine. This is the correct order per Apple's guidelines.
/// - `overrideToSpeaker`: restore category/mode AFTER flutter_pcm_sound resets them during
///   its own `setup()` call. Does NOT call `setActive` to avoid churn on a running engine.
///
/// On interruption end (call, Siri, AirPods), the session is reactivated natively and Dart
/// is notified via `audioInterruptionEnded` so the PCM engine can be restarted.
class AudioRoutingPlugin: NSObject, FlutterPlugin {
  private var _channel: FlutterMethodChannel?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "alzheimer_assistant/audio",
      binaryMessenger: registrar.messenger()
    )
    let instance = AudioRoutingPlugin()
    instance._channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)

    NotificationCenter.default.addObserver(
      instance,
      selector: #selector(handleInterruption),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance()
    )
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "prepareAudioSession":
      // Called BEFORE flutter_pcm_sound.setup() — full config including setActive.
      applyAudioConfig(activate: true, result: result)
    case "overrideToSpeaker":
      // Called AFTER flutter_pcm_sound.setup() resets the mode — restore mode only,
      // no setActive to avoid churn on an already-running engine.
      applyAudioConfig(activate: false, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func applyAudioConfig(activate: Bool, result: FlutterResult? = nil) {
    do {
      let session = AVAudioSession.sharedInstance()

      // .voiceChat stabilises hardware AEC, buffer size, and routing policy on iOS 17+.
      // .allowBluetoothA2DP uses the high-quality A2DP profile instead of falling back
      // to HFP, which applies a reduced gain and can re-route unexpectedly.
      try session.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [.defaultToSpeaker, .allowBluetoothA2DP]
      )

      try session.setPreferredSampleRate(24000)
      try session.setPreferredIOBufferDuration(0.01)

      if activate {
        try session.setActive(true)
      }

      result?(nil)
    } catch {
      result?(
        FlutterError(
          code: "AVAudioSessionError",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  @objc func handleInterruption(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }

    if type == .ended {
      guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
      if options.contains(.shouldResume) {
        // Reactivate the session with full config (setActive required after interruption).
        applyAudioConfig(activate: true)
        // Notify Dart so the PCM engine (flutter_pcm_sound) can be restarted.
        _channel?.invokeMethod("audioInterruptionEnded", arguments: nil)
      }
    }
  }
}
