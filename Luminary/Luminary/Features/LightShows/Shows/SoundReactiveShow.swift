import AVFoundation
import Foundation
import SwiftUI

@Observable
class SoundReactiveShow: LightShow {
  let id = "sound-reactive"
  let name = "Sound Reactive"
  let description = "Lights respond to music and sound from your microphone"
  let icon = "waveform"

  var theme: Theme = .spectrum
  var sensitivity: Double = 0.5
  var smoothing: Double = 0.7

  private var audioEngine: AVAudioEngine?
  private var inputNode: AVAudioInputNode?
  private var isListening = false
  private var currentAmplitude: Double = 0.0
  private var currentFrequency: Double = 0.0

  enum Theme: String, CaseIterable, Identifiable {
    case spectrum = "Spectrum"
    case pulse = "Pulse"
    case wave = "Wave"
    case energy = "Energy"

    var id: String { rawValue }

    var description: String {
      switch self {
      case .spectrum:
        return "Rainbow colors based on frequency"
      case .pulse:
        return "Brightness pulses with volume"
      case .wave:
        return "Color waves flow with rhythm"
      case .energy:
        return "High energy colors for loud sounds"
      }
    }

    var icon: String {
      switch self {
      case .spectrum: return "rainbow"
      case .pulse: return "waveform.path.ecg"
      case .wave: return "water.waves"
      case .energy: return "bolt.fill"
      }
    }
  }

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(SoundReactiveConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      guard !lights.isEmpty else { return }

      // Request microphone permission
      let hasPermission = await requestMicrophonePermission()
      guard hasPermission else {
        print("Microphone permission denied")
        return
      }

      // Set up audio engine
      let didStartEngine = await setupAudioEngine()
      guard didStartEngine else {
        print("Audio engine unavailable; aborting sound reactive show")
        return
      }

      var lastAmplitude: Double = 0.0
      var lastFrequency: Double = 0.0

      while !Task.isCancelled {
        guard let audioLevel = getAudioLevel() else {
          try? await Task.sleep(for: .seconds(0.05))
          continue
        }

        // Apply smoothing
        lastAmplitude = (lastAmplitude * smoothing) + (audioLevel.amplitude * (1 - smoothing))
        lastFrequency = (lastFrequency * smoothing) + (audioLevel.frequency * (1 - smoothing))

        // Scale by sensitivity
        let scaledAmplitude = min(1.0, lastAmplitude * sensitivity * 2)

        // Apply theme-based colors
        for (index, (lightName, position)) in lights.enumerated() {
          guard !Task.isCancelled else { break }

          let color = calculateColor(
            theme: theme,
            amplitude: scaledAmplitude,
            frequency: lastFrequency,
            lightIndex: index,
            totalLights: lights.count,
            position: position
          )

          onColorUpdate(lightName, color)
          controller.setLightColor(
            accessoryName: lightName,
            hue: color.hue,
            saturation: color.saturation,
            brightness: color.brightness
          )
        }

        try? await Task.sleep(for: .seconds(0.05))
      }

      // Clean up
      stopAudioEngine()
    }
  }

  // MARK: - Audio Analysis

  private struct AudioLevel {
    let amplitude: Double  // 0.0 to 1.0
    let frequency: Double  // 0.0 to 1.0 (normalized)
  }

  private func requestMicrophonePermission() async -> Bool {
    // First check current authorization status
    #if targetEnvironment(macCatalyst)
      if #available(macCatalyst 17.0, *) {
        let status = AVAudioApplication.shared.recordPermission
        print("Current macCatalyst permission status: \(status.rawValue)")

        switch status {
        case .granted:
          return true
        case .denied:
          print(
            "Microphone access denied. Please enable in System Settings > Privacy & Security > Microphone"
          )
          return false
        case .undetermined:
          return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
              print("Permission request result: \(granted)")
              continuation.resume(returning: granted)
            }
          }
        @unknown default:
          return false
        }
      } else {
        // Fallback for older macCatalyst versions
        let status = AVAudioSession.sharedInstance().recordPermission
        print("Current permission status (legacy): \(status.rawValue)")

        switch status {
        case .granted:
          return true
        case .denied:
          print(
            "Microphone access denied. Please enable in System Settings > Privacy & Security > Microphone"
          )
          return false
        case .undetermined:
          return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
              print("Permission request result: \(granted)")
              continuation.resume(returning: granted)
            }
          }
        @unknown default:
          return false
        }
      }
    #else
      // iOS/iPadOS
      let status = AVAudioSession.sharedInstance().recordPermission
      print("Current iOS permission status: \(status.rawValue)")

      switch status {
      case .granted:
        return true
      case .denied:
        print("Microphone access denied. Please enable in Settings > Privacy > Microphone")
        return false
      case .undetermined:
        return await withCheckedContinuation { continuation in
          AVAudioSession.sharedInstance().requestRecordPermission { granted in
            print("Permission request result: \(granted)")
            continuation.resume(returning: granted)
          }
        }
      @unknown default:
        return false
      }
    #endif
  }

  @discardableResult
  @MainActor
  private func setupAudioEngine() -> Bool {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.record, mode: .measurement, options: [.allowBluetoothHFP])
      try session.setActive(true, options: .notifyOthersOnDeactivation)

      if let availableInputs = session.availableInputs, !availableInputs.isEmpty {
        let routeInputs: [AVAudioSessionPortDescription] = session.currentRoute.inputs
        let hasValidRoute: Bool = routeInputs.contains { (port: AVAudioSessionPortDescription) -> Bool in
          return (port.channels?.count ?? 0) > 0
        }
        if !hasValidRoute {
          if let preferredBuiltIn = availableInputs.first(where: { $0.portType == .builtInMic })
            ?? availableInputs.first
          {
            try? session.setPreferredInput(preferredBuiltIn)
            print("Selected audio input: \(preferredBuiltIn.portName)")
          }
        }
      } else {
        print("No available audio inputs reported by AVAudioSession")
      }

      if isListening {
        return true
      }

      audioEngine = AVAudioEngine()
      guard let audioEngine = audioEngine else {
        print("Failed to create audio engine")
        return false
      }

      inputNode = audioEngine.inputNode
      print("Input node created: \(inputNode != nil)")

      guard let inputNode = inputNode else {
        print("No input node available")
        return false
      }

      // Get the input format from the input node.
      // Using inputFormat tells us what the hardware can provide
      let inputFormat = inputNode.inputFormat(forBus: 0)
      print("Hardware input format: \(inputFormat)")
      print("Sample rate: \(inputFormat.sampleRate), Channels: \(inputFormat.channelCount)")

      if inputFormat.channelCount == 0 || inputFormat.sampleRate == 0 {
        let sessionChannels = Int(session.inputNumberOfChannels)
        let sessionSampleRate = session.sampleRate
        print("Session reported channels: \(sessionChannels), sample rate: \(sessionSampleRate)")

        if sessionChannels == 0 || sessionSampleRate == 0 {
          print("Input format invalid after session configuration; no usable microphone route")
          stopAudioEngine()
          return false
        }
      }

      // Create a format for our tap - use standard PCM format
      guard let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: max(inputFormat.sampleRate, session.sampleRate),
        channels: max(inputFormat.channelCount, UInt32(session.inputNumberOfChannels)),
        interleaved: false
      ), format.channelCount > 0, format.sampleRate > 0 else {
        print("Failed to derive a valid tap format")
        stopAudioEngine()
        return false
      }

      print("Installing tap with format: \(format)")

      // Install tap BEFORE starting the engine
      inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
        self?.analyzeAudioBuffer(buffer)
      }

      // Now start the engine
      try audioEngine.start()

      isListening = true
      print("Audio engine started successfully")
      return true
    } catch {
      print("Failed to start audio engine: \(error.localizedDescription)")
      print("Error details: \(error)")
      stopAudioEngine()
      return false
    }
  }

  @MainActor
  private func stopAudioEngine() {
    inputNode?.removeTap(onBus: 0)
    audioEngine?.stop()
    isListening = false
    inputNode = nil
    audioEngine = nil

    #if !targetEnvironment(macCatalyst)
      try? AVAudioSession.sharedInstance().setActive(false)
    #endif

    print("Audio engine stopped")
  }

  @MainActor
  private func getAudioLevel() -> AudioLevel? {
    guard isListening else { return nil }

    // Return the analyzed values
    return AudioLevel(amplitude: currentAmplitude, frequency: currentFrequency)
  }

  // Analyze audio buffer for amplitude and rough frequency
  private func analyzeAudioBuffer(_ buffer: AVAudioPCMBuffer) {
    guard let channelData = buffer.floatChannelData else { return }

    let channelDataValue = channelData.pointee
    let frameLength = Int(buffer.frameLength)

    // Calculate RMS (Root Mean Square) for amplitude
    var sum: Float = 0.0
    for i in 0..<frameLength {
      let sample = channelDataValue[i]
      sum += sample * sample
    }

    let rms = sqrt(sum / Float(frameLength))
    let amplitude = Double(min(rms * 10, 1.0))  // Scale and clamp to 0-1

    // Simple zero-crossing rate for rough frequency estimation
    var zeroCrossings = 0
    for i in 1..<frameLength {
      if (channelDataValue[i] >= 0 && channelDataValue[i - 1] < 0)
        || (channelDataValue[i] < 0 && channelDataValue[i - 1] >= 0)
      {
        zeroCrossings += 1
      }
    }

    // Normalize frequency (more crossings = higher frequency)
    let frequency = Double(zeroCrossings) / Double(frameLength)

    // Update stored values
    Task { @MainActor in
      self.currentAmplitude = amplitude
      self.currentFrequency = frequency
    }
  }

  // MARK: - Color Calculation

  private func calculateColor(
    theme: Theme,
    amplitude: Double,
    frequency: Double,
    lightIndex: Int,
    totalLights: Int,
    position: CGPoint
  ) -> HSBColor {
    switch theme {
    case .spectrum:
      // Map frequency to hue (low freq = red, high freq = blue)
      let hue = frequency * 300  // 0-300 degree range
      let brightness = max(20, amplitude * 100)
      return HSBColor(hue: hue, saturation: 90, brightness: brightness)

    case .pulse:
      // All lights same color, brightness varies with amplitude
      let brightness = max(10, amplitude * 100)
      return HSBColor(hue: 280, saturation: 80, brightness: brightness)  // Purple

    case .wave:
      // Color wave based on position and amplitude
      let normalizedIndex = Double(lightIndex) / Double(max(1, totalLights - 1))
      let phase = (normalizedIndex + amplitude) * 360
      let hue = phase.truncatingRemainder(dividingBy: 360)
      let brightness = max(30, 50 + (amplitude * 50))
      return HSBColor(hue: hue, saturation: 100, brightness: brightness)

    case .energy:
      // Hot colors for loud sounds, cool for quiet
      let hue: Double
      if amplitude > 0.7 {
        hue = Double.random(in: 0...30)  // Red/orange
      } else if amplitude > 0.4 {
        hue = Double.random(in: 30...60)  // Orange/yellow
      } else {
        hue = 240  // Blue when quiet
      }
      let brightness = max(20, amplitude * 100)
      return HSBColor(hue: hue, saturation: 100, brightness: brightness)
    }
  }
}

