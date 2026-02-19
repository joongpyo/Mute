//
//  MuteApp.swift
//  Mute
//
//  Created by JP on 2/19/26.
//
// 앱의 시작점이자 심장. 외장 SSD 연결 설정을 여기서 담당 (건물의 중앙 제어실)


import SwiftUI
import SwiftData

@main
struct MuteApp: App {
    // 1. 앱 전체에서 사용할 저장소(Container) 변수 선언
    var sharedModelContainer: ModelContainer
    
//    init() {
//        do {
//            // 1. 외장 SSD 내 경로 지정 (가상 디스크 이름 반영)
//            //  본인의 실제 볼륨 이름이 'Xcode_Drive'인지 다시 한번 확인
//            let ssdURL = URL(fileURLWithPath: "/Volumes/Xcode_Drive/Mute_DB")
//            
//            // 폴더가 없으면 생성 (폴더가 이미 있으면 그냥 지나감)
//            try FileManager.default.createDirectory(at: ssdURL, withIntermediateDirectories: true)
//            
//            // 2. 실제 데이터베이스 파일명 설정 (Mute 전용 이름으로)
//            let storeURL = ssdURL.appendingPathComponent("MuteRecords.store")
//            
//            // 3. 구성 설정
//            let config = ModelConfiguration(url: storeURL)
//            
//            // 4. 컨테이너 초기화
//            //  여기서 SoundRecord.self를 넣어줘야 우리가 만든 모델을 저장할 수 있습니다.
//            sharedModelContainer = try ModelContainer(for: SoundRecord.self, configurations: config)
//            
//            print(" Mute 데이터베이스가 외장 SSD에 연결되었습니다: \(storeURL.path)")
//        } catch {
//            // 외장 SSD가 연결되지 않았거나 문제가 생겼을 때 앱이 안전하게 종료되도록 합니다.
//            fatalError("외장 SSD 저장소 설정 실패: \(error.localizedDescription)")
//        }
//    }
    
    init() {
        do {
            let storeURL: URL
            
            #if targetEnvironment(simulator)
            // 1. 시뮬레이터: 기존처럼 외장 SSD 경로 사용 (맥북 자원 활용)
            let ssdURL = URL(fileURLWithPath: "/Volumes/Xcode_Drive/Mute_DB")
            try FileManager.default.createDirectory(at: ssdURL, withIntermediateDirectories: true)
            storeURL = ssdURL.appendingPathComponent("MuteRecords.sqlite")
            print("✅ 시뮬레이터 모드: 외장 SSD에 연결됨")
            
            #else
            // 2. 실제 아이폰: 앱 내부의 전용 문서(Documents) 폴더 사용
            // 아이폰은 외부 경로(/Volumes/...)에 접근할 권한이 아예 없습니다.
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            storeURL = documentsURL.appendingPathComponent("MuteRecords.sqlite")
            print("📲 실기기 모드: 아이폰 내부 저장소에 연결됨")
            #endif
            
            let config = ModelConfiguration(url: storeURL)
            sharedModelContainer = try ModelContainer(for: SoundRecord.self, configurations: config)
            
        } catch {
            fatalError("저장소 설정 실패: \(error.localizedDescription)")
        }
    }
        
        var body: some Scene {
            WindowGroup {
                ContentView()
            }
            // 7. 앱 전체 화면에 우리가 만든 SSD 전용 컨테이너 주입
            .modelContainer(sharedModelContainer)
        }
    }


