import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Mirrors `MainActivity.kt`: app-private key/value storage for the BYOK key.
  /// `PlatformKeyStore` degrades to memory when this handler is absent.
  private let storeChannelName = "com.doubler.doubler/store"
  private let audio = DoublerIosAudio()
  private var wired = false
  private var wireAttempts = 0

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    wireChannels()
    return launched
  }

  private func wireChannels() {
    guard !wired else { return }
    guard let controller = window?.rootViewController as? FlutterViewController else {
      wireAttempts += 1
      if wireAttempts < 8 {
        DispatchQueue.main.async { [weak self] in self?.wireChannels() }
      }
      return
    }
    wired = true
    let channel = FlutterMethodChannel(
      name: storeChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      let defaults = UserDefaults.standard
      let args = call.arguments as? [String: Any]
      guard let key = args?["key"] as? String else {
        result(FlutterError(code: "badArgs", message: "missing 'key' argument", details: nil))
        return
      }
      switch call.method {
      case "read":
        result(defaults.string(forKey: key))
      case "write":
        guard let value = args?["value"] as? String else {
          result(FlutterError(code: "badArgs", message: "missing 'value' argument", details: nil))
          return
        }
        defaults.set(value, forKey: key)
        result(true)
      case "remove":
        defaults.removeObject(forKey: key)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    audio.attach(messenger: controller.binaryMessenger)
  }
}

/// iOS has no other-app audio capture. Microphone + playback stay real so a
/// speakerphone session is not silent; YouTube internal audio is Android-only
/// and reported as `playbackUnsupported` so Dart falls back honestly.
final class DoublerIosAudio: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var playFormat: AVAudioFormat?
  private var capturing = false
  private var outputReady = false
  private var gain: Float = 1

  func attach(messenger: FlutterBinaryMessenger) {
    let methods = FlutterMethodChannel(
      name: "com.doubler.doubler/audio",
      binaryMessenger: messenger
    )
    methods.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    let events = FlutterEventChannel(
      name: "com.doubler.doubler/audio_pcm",
      binaryMessenger: messenger
    )
    events.setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "startCapture":
      let source = args?["source"] as? String ?? "microphone"
      if source == "playback" {
        result(["error": "playbackUnsupported"])
        return
      }
      startMicrophone(result: result)
    case "pauseCapture":
      capturing = false
      result(["ok": true])
    case "resumeCapture":
      capturing = true
      result(["ok": true])
    case "stopSession":
      stopAll()
      result(["ok": true])
    case "startOutput":
      prepareOutput()
      result(["ok": true])
    case "writeOutput":
      if let typed = args?["pcm"] as? FlutterStandardTypedData {
        enqueue(typed.data)
      }
      result(nil)
    case "pauseOutput":
      player.pause()
      result(["ok": true])
    case "stopOutput":
      player.stop()
      result(["ok": true])
    case "setGain":
      gain = Float(args?["gain"] as? Double ?? 1)
      player.volume = gain
      result(["ok": true])
    case "setDuck":
      result(["ok": true])
    case "openYouTube":
      result(openYouTube())
    case "micPermission":
      result(["granted": AVAudioSession.sharedInstance().recordPermission == .granted])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startMicrophone(result: @escaping FlutterResult) {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(
        .playAndRecord,
        mode: .spokenAudio,
        options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth]
      )
      try session.setActive(true)
    } catch {
      result(["error": "micDenied"])
      return
    }
    session.requestRecordPermission { [weak self] granted in
      DispatchQueue.main.async {
        guard let self = self else { return }
        if !granted {
          result(["error": "micDenied"])
          return
        }
        self.installTap()
        result(["ok": true])
      }
    }
  }

  private func installTap() {
    let input = engine.inputNode
    let hw = input.outputFormat(forBus: 0)
    input.removeTap(onBus: 0)
    input.installTap(onBus: 0, bufferSize: 4096, format: hw) { [weak self] buffer, _ in
      self?.emit(buffer)
    }
    engine.prepare()
    if !engine.isRunning {
      try? engine.start()
    }
    capturing = true
  }

  private func emit(_ buffer: AVAudioPCMBuffer) {
    guard capturing, let channel = buffer.floatChannelData?[0] else { return }
    let rate = buffer.format.sampleRate
    let step = rate / 16000.0
    if step <= 0 { return }
    var cursor = 0.0
    var samples = [Int16]()
    let frames = Int(buffer.frameLength)
    while cursor < Double(frames) {
      let index = min(Int(cursor), frames - 1)
      let value = channel[index]
      let clamped = max(-1, min(1, value))
      samples.append(Int16(clamped * 32767))
      cursor += step
    }
    guard !samples.isEmpty else { return }
    let data = samples.withUnsafeBufferPointer { pointer -> Data in
      Data(buffer: pointer)
    }
    DispatchQueue.main.async { [weak self] in
      self?.sink?(FlutterStandardTypedData(bytes: data))
    }
  }

  private func prepareOutput() {
    if outputReady {
      if !player.isPlaying { player.play() }
      return
    }
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 1, interleaved: false)
    playFormat = format
    engine.attach(player)
    if let format = format {
      engine.connect(player, to: engine.mainMixerNode, format: format)
    }
    engine.prepare()
    if !engine.isRunning {
      try? engine.start()
    }
    player.volume = gain
    player.play()
    outputReady = true
  }

  private func enqueue(_ data: Data) {
    prepareOutput()
    guard let format = playFormat else { return }
    let count = data.count / 2
    guard count > 0,
          let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count)),
          let dst = buffer.floatChannelData?[0] else { return }
    buffer.frameLength = AVAudioFrameCount(count)
    data.withUnsafeBytes { raw in
      let samples = raw.bindMemory(to: Int16.self)
      for i in 0..<count {
        dst[i] = Float(samples[i]) / 32768.0 * gain
      }
    }
    player.scheduleBuffer(buffer)
    if !player.isPlaying { player.play() }
  }

  private func stopAll() {
    capturing = false
    engine.inputNode.removeTap(onBus: 0)
    player.stop()
    if engine.isRunning { engine.stop() }
    outputReady = false
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func openYouTube() -> Bool {
    if let app = URL(string: "youtube://"), UIApplication.shared.canOpenURL(app) {
      UIApplication.shared.open(app)
      return true
    }
    if let web = URL(string: "https://www.youtube.com/") {
      UIApplication.shared.open(web)
      return true
    }
    return false
  }
}
