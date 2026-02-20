//
//  SoundRecord.swift
//  Mute
//
//  Created by JP on 2/19/26.
//
// 데이터의 설계도. 어떤 항목을 저장할지 정의

import Foundation //애플의 모든 운영체제(iOS, macOS 등)에서 공통적으로 사용하는 기본 데이터 타입과 핵심 기능을 모아놓은 라이브러리
import SwiftData //Apple의 최신 데이터 저장 도구인 SwiftData 기능을 이 파일에서 사용하겠다

@Model //이 클래스가 단순히 메모리에 머물다 사라지는 게 아니라, DB(외장 SSD의 .store 파일)에 영구적으로 저장될 '모델'
//이 클래스를 다른 클래스가 상속(복사/변형)해서 쓰지 못하게 하겠다라는 보안 성능 최적화용 키워드 (보통 데이터 모델은 안전을 위해 final을 붙이는게 관례.
final class SoundRecord {
    var title: String
    var audioFileName : String
    var createdAt : Date
    
    //위에서 배운 대로 이 클래스가 '탄생'할 때 실행되는 초기화 함수
    init(title: String, audioFileName: String){
        self.title = title //방금 사용자가 입력한 제목을 이 상자(self)에 넣어줘
        self.audioFileName = audioFileName
        self.createdAt = Date() //사용자가 입력하지 않아도, 탄생하는 그 시점의 현재 시각(Date())을 자동으로 기록하라는 아주 똑똑한 코드
    }
}
