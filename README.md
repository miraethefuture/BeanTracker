# BeanTracker

BeanTracker는 홈카페 사용자가 원두 소비를 최소 입력으로 기록하고, 집에서 커피를 내려 마시며 절약한 금액을 월 단위로 명확하게 확인할 수 있게 해주는 개인 대시보드 앱입니다.

## 문서

- [Wiki Home](https://github.com/miraethefuture/BeanTracker/wiki)

## 제품 방향

- 핵심 지표: 이번 달 절약액
- 핵심 경험: 원두 등록 → 추출 기록 → 절약액 증가 확인 → 월말 리뷰
- 출시 목표: App Store 배포 가능한 1.0
- 플랫폼: iPhone, iPad, macOS
- 언어: 한국어, 영어
- 기술 스택: SwiftUI, TCA, Tuist, SwiftData, CloudKit

## 현재 프로젝트 구조

- `Workspace.swift`: 전체 워크스페이스 정의
- `Tuist/Package.swift`: 외부 패키지 의존성 정의
- `Projects/App`: 앱 타깃과 루트 TCA 구성
- `Projects/Features/*`: 대시보드, 추출 기록, 원두 창고, 온보딩, 설정
- `Projects/Domain/CoffeeDomain`: 순수 모델과 계산 로직
- `Projects/Core/DatabaseClient`: 의존성 클라이언트와 인메모리 구현

## Tuist 시작 방법

1. Tuist CLI 설치
2. `tuist install`
3. `tuist generate`
4. 생성된 워크스페이스 열기

현재 `DatabaseClient.liveValue`는 SwiftData/CloudKit 대신 인메모리 구현으로 연결되어 있습니다. 다음 단계에서 실제 persistence 계층으로 교체하면 됩니다.

## 저장소 메모

`wiki/` 디렉터리는 GitHub Wiki로 옮기기 쉬운 Markdown 초안을 담고 있습니다.
