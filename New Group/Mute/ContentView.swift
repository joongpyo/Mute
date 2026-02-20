//
//  ContentView.swift
//  Mute
//
//  Created by JP on 2/19/26.
//
// 유저가 보는 화면. 버튼을 누르고 리스트를 보는곳 (건물의 인테리어, 로비)

import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: - 1. 저장소(SwiftData) 연동
    // 관리자(AudioManager)가 만든 데이터를 실제로 DB에 쓰고 지우는 '입출력 장치'입니다.
    @Environment(\.modelContext) private var modelContext
    
    // DB의 'SoundRecord' 테이블을 실시간 감시합니다. 데이터가 추가/삭제되면 리스트를 즉시 갱신합니다.
    @Query(sort: \SoundRecord.createdAt, order: .reverse) private var records: [SoundRecord]
    
    // MARK: - 2. 사용자 입력 및 임시 데이터 (UI State)
    @State private var showTitleAlert = false  // 알림창 제어 (입력 흐름의 중간 다리)
    @State private var newTitle = ""           // 유저가 입력한 제목 (UI -> DB)
    @State private var lastFileName = ""       // 매니저가 준 파일명 보관 (Logic -> UI)
    
    // MARK: - 3. 로직 관리자(AudioManager) 연동
    // 실제 녹음/재생 장치를 다룹니다. @Published 상태를 통해 뷰에 하드웨어 상황을 중계합니다.
    @StateObject private var audioManager = AudioManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // MARK: - 목록 렌더링 (데이터 시각화)
                if records.isEmpty {
                    ContentUnavailableView("수집된 소음이 없습니다", systemImage: "waveform", description: Text("하단의 버튼을 눌러 첫 소음을 기록해보세요."))
                } else {
                    List {
                        ForEach(records) { record in
                            Button(action: {
                                // [연동: View -> Manager] 재생할 데이터 모델을 매니저에게 전달
                                audioManager.startPlayer(record: record)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }) {
                                VStack(alignment: .leading) {
                                    Text(record.title)
                                        .font(.headline)
                                        // [연동: Manager -> View] 매니저의 재생 상태(playingRecordID)와
                                        // 현재 행의 ID가 같으면 주황색으로 강조
                                        .foregroundStyle(audioManager.playingRecordID == record.id ? .orange : .primary)
                                    
                                    Text(record.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteRecords) // [연동: View -> SwiftData] 삭제 실행
                    }
                }
                
                Spacer()
                
                // MARK: - 제어부 (녹음 인터페이스)
                Button(action: {
                    if audioManager.isRecording {
                        // [연동: View -> Manager] 녹음 중지 명령
                        audioManager.stopRecording()
                        
                        // [연동: Manager -> View] 매니저가 방금 생성한 파일 이름을 뷰의 변수에 복사 (데이터 캡처)
                        self.lastFileName = audioManager.currentFileName
                        
                        // 제목 입력을 위한 다음 단계(Alert)로 진입
                        self.showTitleAlert = true
                    } else {
                        // [연동: View -> Manager] 녹음 시작 명령 (내부적으로 파일명 생성됨)
                        audioManager.startRecordingProcess()
                    }
                }) {
                    ZStack {
                        Circle()
                            // [연동: Manager -> View] 매니저의 녹음 상태에 따라 실시간 색상 변경
                            .fill(audioManager.isRecording ? .orange : .red)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    }
                }
                // MARK: - 데이터 조립 및 확정 (Alert)
                .alert("소음 기록 완료", isPresented: $showTitleAlert) {
                    TextField("소음의 제목을 입력하세요", text: $newTitle)
                    
                    Button("저장") {
                        // [데이터 조립] 유저 제목 + 매니저 파일명 결합
                        let finalTitle = newTitle.isEmpty ? "무제 소음" : newTitle
                        
                        // [연동: View -> Model] 새로운 SoundRecord 인스턴스 생성
                        let newRecord = SoundRecord(title: finalTitle, audioFileName: lastFileName)
                        
                        // [연동: View -> SwiftData] 최종 데이터를 DB에 등록
                        modelContext.insert(newRecord)
                        
                        // 초기화
                        newTitle = ""
                    }
                    Button("취소", role: .cancel) { newTitle = "" }
                } message: {
                    Text("이 소음을 무엇이라 부를까요?")
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Mute")
            .toolbar { EditButton() }
        }
    }

    // MARK: - 삭제 로직
    private func deleteRecords(offsets: IndexSet) {
        for index in offsets {
            // [연동: View -> SwiftData] 특정 인덱스의 모델 객체를 DB에서 제거
            modelContext.delete(records[index])
        }
    }
}
