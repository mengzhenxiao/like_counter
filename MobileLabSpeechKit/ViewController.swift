//
//  ViewController.swift
//  MobileLabSpeechKit
//
//  Created by Nien Lam on 12/31/17.
//  Copyright © 2017 Mobile Lab. All rights reserved.
//
//  Description:
//  View controller for speech recognition demo.

import UIKit
import Speech
import SwiftSiriWaveformView

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioRecorderDelegate {

    var timer: Timer?
    var change: CGFloat = 0.01
    var counter: Int = 0
    var counterColor: Double = 1.00
    let soundArray = ["no"]
    var player: AVAudioPlayer?

    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var recorder: AVAudioRecorder!

    // View for audio wave form feedback.
    @IBOutlet weak var audioWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var detectedTextLabel: UILabel!
    
    var mostRecentlyProcessedSegmentDuration: TimeInterval = 0
    
    var lastBestString = ""
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        

        self.requestSpeechAuthorization()
        
        self.audioWaveView.density = 1.0
        self.audioWaveView.waveColor = UIColor.purple

        if self.recorder != nil {
            return
        }
    
        let url: NSURL = NSURL(fileURLWithPath: "/dev/null")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            self.recorder = try AVAudioRecorder(url: url as URL, settings: settings )
            self.recorder.delegate = self
            self.recorder.isMeteringEnabled = true
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.record)))
            
            self.recorder.record()
            
            timer = Timer.scheduledTimer(timeInterval: 0.009, target: self, selector: #selector(refreshAudioView(_:)), userInfo: nil, repeats: true)
        } catch {
            print("Fail to record.")
        }
    }

    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("authorized")
                    self.recordAndRecognizeSpeech()
                case .denied:
                    print("denied")
                case .restricted:
                    print("restricted")
                case .notDetermined:
                    print("notDetermined")
                @unknown default:
                    return
                }
            }
        }
    }
    
    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode

        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                //self.detectedTextLabel.text = bestString
                //print(bestString)

                if let lastSegment = result.bestTranscription.segments.last,
                    lastSegment.duration > self.mostRecentlyProcessedSegmentDuration {
                    self.mostRecentlyProcessedSegmentDuration = lastSegment.duration

                    /////////////////////////////////////////////////////////////////////
                    // Get last spoken word.
                    // Process request here.
                    
                    let string = lastSegment.substring
                    print(string)
                    
                    if string.lowercased() == "like" {
                        //self.view.backgroundColor = .green
                        self.counter+=1
                        self.counterColor-=0.06
                        self.detectedTextLabel.text = String(self.counter)
                        self.view.backgroundColor = UIColor(white: 1, alpha: CGFloat(self.counterColor))
                        if self.counter >= 10 {
                            self.playSoundMP3(filename: self.soundArray[0])
                            let alert = UIAlertController(title: "No More LIKE!", message: nil, preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "🤐", style: UIAlertAction.Style.default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    /////////////////////////////////////////////////////////////////////
                }

            } else if let error = error {
                self.sendAlert(message: "There has been a speech recognition error.")
                print(error)
            }

        })
    }
    
    func sendAlert(message: String) {
        let alert = UIAlertController(title: "Speech Recognizer Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc internal func refreshAudioView(_: Timer) {
        // Simply set the amplitude to whatever you need and the view will update itself.
        self.audioWaveView.amplitude = 0.5

        recorder.updateMeters()
        
        let normalizedValue:CGFloat = pow(10, CGFloat(recorder.averagePower(forChannel: 0))/20)
        self.audioWaveView.amplitude = normalizedValue
    }
    
    func playSoundMP3(filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)), mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
