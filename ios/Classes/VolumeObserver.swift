//
//  VolumeObserver.swift
//  volume_controller
//
//  Created by Kurenai on 30/01/2021.
//

import Foundation
import AVFoundation
import MediaPlayer
import Flutter
import UIKit

public class VolumeObserver {
    public func getVolume() -> Float? {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
             try audioSession.setActive(true)
             return audioSession.outputVolume
        } catch {
             return nil
        }
    }

    public func setVolume(volume: Float, showSystemUI: Bool = false) {
        let volumeView = MPVolumeView()
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("No window to add the volume slider to")
            return
        }
        if !showSystemUI {
            volumeView.frame = CGRect(x: -1000, y: -1000, width: 1, height: 1)
            volumeView.showsVolumeSlider = false
            window.rootViewController!.view.addSubview(volumeView)
        }

        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
            volumeView.removeFromSuperview()
        }
    }
}

public class VolumeListener: NSObject, FlutterStreamHandler {
    private let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private let notification: NotificationCenter = NotificationCenter.default
    private var eventSink: FlutterEventSink?
    private var isObserving: Bool = false
    private let volumeKey: String = "outputVolume"

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        registerVolumeObserver()
        eventSink?(audioSession.outputVolume)

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        removeVolumeObserver()

        return nil
    }

    private func registerVolumeObserver() {
        audioSessionObserver()
        notification.addObserver(
            self,
            selector: #selector(audioSessionObserver),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }

    @objc func audioSessionObserver(){
        do {
            try audioSession.setCategory(.ambient, options: [.mixWithOthers])
            try audioSession.setActive(true)
            if !isObserving {
                audioSession.addObserver(self,
                                         forKeyPath: volumeKey,
                                         options: .new,
                                         context: nil)
                isObserving = true
            }
        } catch {
            print("Volume Controller Listener occurred error.")
        }
    }

    private func removeVolumeObserver() {
        audioSession.removeObserver(self,
                                    forKeyPath: volumeKey)
        notification.removeObserver(self,
                                    name: UIApplication.didBecomeActiveNotification,
                                    object: nil)
        isObserving = false
    }

    override public func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey: Any]?,
                                      context: UnsafeMutableRawPointer?) {
        if keyPath == volumeKey {
            eventSink?(audioSession.outputVolume)
        }
    }
}