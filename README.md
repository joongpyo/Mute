---

### 📖 상세 가이드 및 기획 문서
프로젝트의 상세한 설계 구조와 기획 의도는 아래 노션 페이지에서 확인하실 수 있습니다.

> [!TIP]
> **[Mute: The Noise Archive 노션 바로가기 🔗](https://www.notion.so/PROJECT-Mute-The-Noise-Archive-30c273faf4e780a593bedff7be8d8a80?source=copy_link)**

---

# PROJECT: Mute (The Noise Archive)
 
 ## 1. 프로젝트 개요 (Overview)
 'Mute'는 단순한 녹음기를 넘어, 우리 주변의 다양한 '소음'을 수집하고 아카이빙하는 도구입니다.
 이 앱은 현대적인 iOS 개발 스택인 SwiftUI와 SwiftData를 활용하여, 비동기적인 하드웨어 제어(오디오)와
 영속적인 데이터 관리(DB)가 어떻게 안전하게 상호작용하는지 보여주는 레퍼런스 프로젝트입니다.
 
 ## 2. 아키텍처 설계 (The Architecture)
 이 프로젝트는 **MVVM (Model - View - ViewModel)** 패턴을 엄격히 따릅니다.
 
 ### [Model] SoundRecord.swift
 - 앱의 '기록물' 그 자체를 정의합니다.
 - `@Model` 키워드를 통해 SwiftData와 연결되며, 고유 식별자(ID)를 통해 각 소음을 구분합니다.
 - 실제 소리 데이터는 용량 문제로 DB에 직접 넣지 않고, '파일명'이라는 주소값만 저장합니다.
 
 ### [View] ContentView.swift
 - 유저의 눈에 보이는 '인테리어'와 '로비' 역할을 합니다.
 - **[연동: Manager -> View]**: Manager가 방송(@Published)하는 상태를 실시간 구독하여 버튼 색상 등을 변경합니다.
 - **[연동: DB -> View]**: @Query를 통해 장부를 계속 감시하며, 새로운 기록이 생기면 리스트에 즉시 노출합니다.
 
 ### [ViewModel] AudioManager.swift
 - 마이크와 스피커를 다루는 '전문 비서'입니다.
 - 실제 소리 파일을 물리적인 경로에 생성하고 관리합니다.
 - 상태 변화(녹음 시작/끝, 재생 중 ID)를 관리하여 View에게 실시간으로 알려줍니다.
 
 ---
 
 ## 3. 핵심 연동 매커니즘 (Key Integration Points)
 
 

 ### A. 녹음 및 데이터 조립 (The Recording Loop)
 1. [유저 클릭]: ContentView에서 버튼을 누릅니다.
 2. [명령 전달]: **(View -> Manager)** `startRecordingProcess()` 호출.
 3. [재료 생성]: Manager가 유니크한 파일명을 생성하고 방송국(`currentFileName`)에 공지합니다.
 4. [캡처 및 저장]: 녹음이 끝나면 View는 Manager로부터 파일명을 받아와서 유저가 쓴 제목과 함께 합칩니다.
 5. [DB 기록]: **(View -> SwiftData)** 최종 합쳐진 모델을 `modelContext.insert()`로 장부에 적습니다.
 
 ### B. 스마트 강조 시스템 (The Playback Highlighting)
 1. [재생 명령]: **(View -> Manager)** 리스트 항목을 누르면 `startPlayer(record:)`로 데이터 통째로 전달.
 2. [상태 방송]: **(Manager -> View)** 재생이 시작되면 `playingRecordID`에 해당 데이터의 주민번호(ID)를 넣습니다.
 3. [UI 반응]: ContentView는 리스트를 그리다가 "어? 내 ID가 Manager가 말한 재생 중 ID랑 같네?"라고 판단하면 글자색을 주황색으로 바꿉니다.
 4. [자동 해제]: 재생이 끝나면 Manager가 ID를 비우고(@Published = nil), 뷰는 다시 원래 색으로 돌아옵니다.
 
 ---
 
 ## 4. 기술적 도전 과제 (Technical Challenges)
 - **파일 경로 관리**: 시뮬레이터와 실제 기기의 샌드박스 경로 차이를 해결하기 위해 조건부 컴파일(#if simulator)을 사용했습니다.
 - **스레드 안전성**: UI 업데이트는 항상 메인 스레드(DispatchQueue.main)에서 처리하여 앱의 안정성을 확보했습니다.
 - **상태 바인딩**: ObservableObject와 @Published를 통해 복잡한 오디오 상태를 SwiftUI의 선언적 UI와 완벽하게 동기화했습니다.
 */



