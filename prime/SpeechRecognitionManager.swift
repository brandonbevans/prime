//
//  SpeechRecognitionManager.swift
//  prime
//
//  Created by Assistant on 11/17/25.
//

import AVFoundation
import Speech
import Foundation
import Combine

final class SpeechRecognitionManager: NSObject, ObservableObject {
  @Published var isRecording: Bool = false
  @Published var transcribedText: String = ""
  @Published var isAuthorized: Bool = false
  
  private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private let audioEngine = AVAudioEngine()
  
  override init() {
    super.init()
    requestAuthorization()
  }
  
  private func requestAuthorization() {
    SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
      DispatchQueue.main.async {
        switch authStatus {
        case .authorized:
          self?.isAuthorized = true
        case .denied, .restricted, .notDetermined:
          self?.isAuthorized = false
        @unknown default:
          self?.isAuthorized = false
        }
      }
    }
    
    // Request microphone permission
    AVAudioApplication.requestRecordPermission { [weak self] granted in
      DispatchQueue.main.async {
        if !granted {
          self?.isAuthorized = false
        }
      }
    }
  }
  
  func startRecording() {
    // Stop any ongoing task
    if recognitionTask != nil {
      recognitionTask?.cancel()
      recognitionTask = nil
    }
    
    // Configure audio session
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("Failed to set up audio session: \(error)")
      return
    }
    
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
    let inputNode = audioEngine.inputNode
    
    guard let recognitionRequest = recognitionRequest else {
      print("Unable to create recognition request")
      return
    }
    
    recognitionRequest.shouldReportPartialResults = true
    recognitionRequest.requiresOnDeviceRecognition = false
    
    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
      var isFinal = false
      
      if let result = result {
        // Stream the transcription as it comes in
        DispatchQueue.main.async {
          self?.transcribedText = result.bestTranscription.formattedString
        }
        isFinal = result.isFinal
      }
      
      if error != nil || isFinal {
        self?.audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        self?.recognitionRequest = nil
        self?.recognitionTask = nil
        self?.isRecording = false
      }
    }
    
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
      self.recognitionRequest?.append(buffer)
    }
    
    audioEngine.prepare()
    
    do {
      try audioEngine.start()
      isRecording = true
    } catch {
      print("Could not start audio engine: \(error)")
    }
  }
  
  func stopRecording() {
    if audioEngine.isRunning {
      audioEngine.stop()
      recognitionRequest?.endAudio()
      isRecording = false
    }
  }
  
  func toggleRecording() {
    if isRecording {
      stopRecording()
    } else {
      startRecording()
    }
  }
  
  func clearTranscription() {
    transcribedText = ""
  }
}
