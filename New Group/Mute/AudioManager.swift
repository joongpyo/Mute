//
//  Untitled.swift
//  Mute
//
//  Created by JP on 2/19/26.
//

import Foundation
import AVFoundation
import SwiftData
import Combine

/// [역할] 오디오 하드웨어 제어 및 상태 중계기
/// 이 클래스는 ContentView의 명령을 수행하고, 하드웨어의 상태를 다시 View로 방송합니다.
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    // MARK: - 1. 오디오 엔진 (도구함)
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    // MARK: - 2. 실시간 상태 방송 (@Published)
    
    // [연동: Manager -> View] 현재 녹음 중인지 여부. ContentView의 버튼 색상과 아이콘을 실시간으로 바꿉니다.
    @Published var isRecording: Bool = false
    
    // [연동: Manager -> View] 현재 재생 중인 SoundRecord의 ID. 리스트에서 어떤 항목이 재생 중인지 주황색으로 강조할 때 사용합니다.
    @Published var playingRecordID: PersistentIdentifier?
    
    // [연동: Manager -> View] 녹음 프로세스에서 생성된 파일명. 녹음 종료 후 ContentView가 DB에 저장할 때 이 이름을 가져갑니다.
    @Published var currentFileName: String = ""

    // MARK: - 3. 녹음 로직 (Recording)
    
    /// [연동: View -> Manager] ContentView에서 녹음 버튼을 눌러 시작할 때 실행됩니다.
    func startRecordingProcess() {
        // 1. 고유 파일명 생성 (파일명에 타임스탬프를 넣어 중복 방지)
        let fileName = "Mute_\(Int(Date().timeIntervalSince1970)).m4a"
        
        // 2. [데이터 연동] 생성된 파일명을 매니저 변수에 보관 (나중에 View가 읽어감)
        self.currentFileName = fileName
        
        let url: URL
        // 3. 경로 결정 (시뮬레이터와 실제 기기의 저장 경로 분기)
        #if targetEnvironment(simulator)
        url = URL(fileURLWithPath: "/Volumes/Xcode_Drive/Mute_DB/\(fileName)")
        // 시뮬레이터 환경에서 폴더가 없을 경우 자동 생성
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        #else
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = documentsURL.appendingPathComponent(fileName)
        #endif
        
        // 4. 내부 녹음 함수 실행
        startRecording(url: url)
    }
    
    /// [연동: View -> Manager] 녹음 중지 버튼 클릭 시 실행됩니다.
    func stopRecording() {
        audioRecorder?.stop()
        DispatchQueue.main.async {
            // [연동: Manager -> View] 녹음 상태 종료를 알려 UI 업데이트 유도
            self.isRecording = false
        }
        print("⏹️ 녹음 중단 완료 (저장 대기 파일: \(currentFileName))")
    }

    // MARK: - 4. 재생 로직 (Playback)

    /// [연동: View -> Manager] 리스트에서 특정 항목을 탭했을 때 실행됩니다.
    /// - Parameter record: [연동: Model -> Manager] SwiftData에서 가져온 실제 데이터 객체
    func startPlayer(record: SoundRecord) {
        // 1. [데이터 연동] 저장된 모델에서 파일명을 꺼내 경로를 재구성
        let fileName = record.audioFileName
        let url: URL
        
        #if targetEnvironment(simulator)
        url = URL(fileURLWithPath: "/Volumes/Xcode_Drive/Mute_DB/\(fileName)")
        #else
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = documentsURL.appendingPathComponent(fileName)
        #endif
        
        do {
            // 오디오 세션 설정: 다른 음악을 끊고 이 소리만 나오게 설정
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self // [연동: Hardware -> Manager] 재생 종료를 알기 위한 대리자 설정
            audioPlayer?.play()
            
            DispatchQueue.main.async {
                // 2. [연동: Manager -> View] 재생 중인 ID를 기록하여 리스트 강조 활성화
                self.playingRecordID = record.id
            }
            print("✅ 재생 시작 :: \(fileName)")
        } catch {
            print("❌ 재생 실패: \(error.localizedDescription)")
        }
    }
    
    /// [연동: Hardware -> Manager] 오디오 재생이 물리적으로 끝났을 때 자동 실행되는 함수 (Delegate)
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            // 3. [연동: Manager -> View] 재생 종료를 알려 리스트 강조를 해제
            self.playingRecordID = nil
        }
    }
    
    // MARK: - 5. 내부 보조 로직 (Private)
    
    private func startRecording(url: URL) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            
            // AAC 포맷 설정 (고품질, 적은 용량)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            
            DispatchQueue.main.async {
                // [연동: Manager -> View] 녹음 진행 상태를 알려 UI(버튼 색상) 업데이트 유도
                self.isRecording = true
            }
            print("🎙️ 녹음 중... 경로: \(url.path)")
        } catch {
            print("❌ 녹음 설정 실패: \(error.localizedDescription)")
        }
    }
}
