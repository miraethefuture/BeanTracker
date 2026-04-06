# BeanTracker Tech Spec v2

## 1. 문서 목적

이 문서는 BeanTracker 1.0을 실제 개발 가능한 수준으로 구체화하기 위한 기술 기준 문서다. 구현 과정에서 아키텍처, 모듈 경계, 데이터 저장 방식, 상태 관리, Preview 전략, 테스트 기준을 명확하게 정의한다.

## 2. 기술 목표

- App Store 배포 가능한 멀티플랫폼 앱을 구축한다.
- Tuist 기반 모듈 구조로 빌드와 Preview 피드백 속도를 관리한다.
- TCA로 기능별 상태와 액션을 분리한다.
- SwiftData와 CloudKit을 통해 로컬 우선 저장과 동일 Apple ID 간 동기화를 제공한다.
- Preview에서는 실제 저장소에 의존하지 않고 즉시 렌더링되어야 한다.

## 3. 고정 기술 스택

- UI: SwiftUI
- 상태 관리/아키텍처: The Composable Architecture
- 프로젝트 구성: Tuist
- 영속성: SwiftData
- 동기화: CloudKit
- 차트: Swift Charts
- 위젯: WidgetKit
- 최소 지원 OS:
  - iOS 17 이상
  - iPadOS 17 이상
  - macOS 14 이상

## 4. 아키텍처 원칙

- 의존성 방향은 반드시 `Feature -> Domain -> Core`를 유지한다.
- Feature는 `ModelContext` 또는 SwiftData 모델에 직접 의존하지 않는다.
- 모든 저장/조회 동작은 `DatabaseClient`를 통해 수행한다.
- 순수 계산 로직은 `CoffeeDomain`에 둔다.
- Preview는 항상 mock dependency를 사용한다.
- 플랫폼 차이는 UI 계층에서 흡수하고 핵심 비즈니스 로직은 공유한다.

## 5. 모듈 구조

### 5.1 App Layer

- `BeanTrackerApp`
  - 앱 진입점
  - 루트 탭 구성
  - 루트 Reducer 조합
  - 딥링크 라우팅
  - 공통 dependency 주입

### 5.2 Feature Layer

- `DashboardFeature`
  - 이번 달 절약액 표시
  - 월별 차트
  - 현재 원두 상태 카드
- `BrewingLogFeature`
  - 빠른 추출 기록
  - 최근 원두/최근 사용량 기본값 로직
- `InventoryFeature`
  - 원두 등록
  - 활성/소진 목록
  - 삭제 및 소진 상태 전환
- `OnboardingFeature`
  - 기준 카페 가격 입력
  - 첫 등록/첫 기록 유도
- `SettingsFeature`
  - 기준 카페 가격 변경
  - 기타 앱 설정 진입점

### 5.3 Domain Layer

- `CoffeeDomain`
  - 도메인 엔티티
  - 절약액 계산
  - 월별 집계 계산
  - 현재 원두 상태 계산
  - 소진 예상 판단

### 5.4 Core Layer

- `DatabaseClient`
  - SwiftData CRUD 추상화
  - CloudKit 동기화 포함 Live 구현
  - Preview/Test용 Mock 구현
- 필요 시 보조 모듈
  - `WidgetSupport`
  - `LocalizationSupport`

## 6. 데이터 모델 설계

Feature가 직접 SwiftData 모델을 다루지 않도록, 저장 모델과 도메인 모델의 경계가 필요하다.  
초기 1.0에서는 복잡한 관계보다 단순하고 안정적인 식별자 중심 모델을 사용한다.

### 6.1 Bean

권장 필드:

- `id: UUID`
- `name: String`
- `roaster: String`
- `totalWeight: Double`
- `price: Int`
- `purchaseDate: Date`
- `isExhausted: Bool`
- `createdAt: Date`

규칙:

- 생성 후 수정 불가
- 삭제 가능
- `isExhausted`만 변경 가능
- 활성 원두는 여러 개 허용

### 6.2 BrewLog

권장 필드:

- `id: UUID`
- `beanId: UUID`
- `usedWeight: Double`
- `date: Date`
- `createdAt: Date`

규칙:

- 1개 로그는 1잔
- 생성 후 수정 불가
- 삭제 가능

### 6.3 UserPreference

권장 필드:

- `id: UUID`
- `standardCafePrice: Int`
- `createdAt: Date`
- `updatedAt: Date`

규칙:

- 앱 사용자 기준 단일 레코드
- 기준 카페 가격 변경 가능

## 7. 도메인 로직

### 7.1 순수 계산 함수

`CoffeeDomain`에 다음과 같은 순수 계산 함수를 둔다.

- `brewCost(beanPrice:totalWeight:usedWeight:) -> Decimal`
- `brewSavings(standardCafePrice:brewCost:) -> Decimal`
- `monthlySavings(month:brewLogs:beans:standardCafePrice:) -> Decimal`
- `monthlyBeanUsage(month:brewLogs:) -> Double`
- `monthlyBeanPurchaseCost(month:beans:) -> Int`
- `remainingWeight(totalWeight:usedWeightSum:) -> Double`
- `expectedRemainingCups(remainingWeight:lastUsedWeight:) -> Double?`
- `isExhaustionWarning(totalWeight:usedWeightSum:) -> Bool`

### 7.2 도메인 출력 모델

Feature에 바로 전달하기 좋은 값 객체를 둔다.

- `MonthlySavingsSummary`
- `CurrentBeanStatus`
- `DashboardChartEntry`
- `BrewDefaults`

이 값들은 SwiftData와 분리된 순수 타입이어야 한다.

## 8. TCA 설계 방향

### 8.1 루트 구성

루트 Reducer는 다음 흐름을 조합한다.

- 온보딩 완료 여부 판단
- 탭 네비게이션
- 각 Feature Reducer
- 공통 데이터 갱신 트리거
- 위젯/딥링크 진입 처리

### 8.2 Feature별 상태 예시

`DashboardFeature.State`

- 선택된 월
- 월별 요약 정보
- 차트 데이터
- 현재 원두 상태
- 로딩 상태

`BrewingLogFeature.State`

- 활성 원두 목록
- 선택된 원두 ID
- 현재 사용량
- 저장 진행 상태

`InventoryFeature.State`

- 활성 원두 목록
- 소진 원두 목록
- 원두 등록 폼 상태

`OnboardingFeature.State`

- 기준 카페 가격 입력값
- 완료 여부

`SettingsFeature.State`

- 기준 카페 가격
- 저장 상태

### 8.3 의존성 규칙

- Reducer는 `@Dependency(\.databaseClient)`를 통해서만 저장소에 접근한다.
- `Date`, `UUID`, `Calendar`, `Locale`도 가능하면 dependency로 관리해 테스트 가능성을 높인다.

## 9. DatabaseClient 계약

초기 계약 예시는 다음과 같다.

```swift
@DependencyClient
struct DatabaseClient {
    var fetchBeans: @Sendable () async throws -> [BeanRecord]
    var fetchActiveBeans: @Sendable () async throws -> [BeanRecord]
    var fetchBrewLogs: @Sendable (_ month: DateInterval?) async throws -> [BrewLogRecord]
    var fetchUserPreference: @Sendable () async throws -> UserPreferenceRecord?
    var saveBean: @Sendable (_ bean: BeanRecord) async throws -> Void
    var saveBrewLog: @Sendable (_ brewLog: BrewLogRecord) async throws -> Void
    var saveUserPreference: @Sendable (_ preference: UserPreferenceRecord) async throws -> Void
    var deleteBean: @Sendable (_ id: UUID) async throws -> Void
    var deleteBrewLog: @Sendable (_ id: UUID) async throws -> Void
    var setBeanExhausted: @Sendable (_ id: UUID, _ isExhausted: Bool) async throws -> Void
}
```

설계 원칙:

- Feature가 필요한 작업 단위 중심 인터페이스를 유지한다.
- 저장소 구현 세부사항은 client 뒤로 숨긴다.
- Preview/Test 구현도 동일한 인터페이스를 따른다.

## 10. SwiftData + CloudKit 전략

### 10.1 저장 전략

- 로컬 우선 저장은 SwiftData로 처리한다.
- 같은 Apple ID 환경의 기기 간 동기화는 CloudKit으로 제공한다.
- 오프라인에서도 기본 기능은 동작해야 한다.

### 10.2 동기화 기대 수준

- 1.0에서는 동일 사용자 기기 간 동기화가 안정적으로 되면 충분하다.
- 복잡한 협업 충돌 해결은 범위 밖이다.
- 동기화 지연이 있더라도 앱은 로컬 기준으로 계속 사용할 수 있어야 한다.

### 10.3 모델링 주의점

- CloudKit 호환을 위해 모델 구조를 단순하게 유지한다.
- 관계는 최소화하고 명시적 식별자를 활용한다.
- 삭제와 집계 로직이 단순하도록 설계한다.

## 11. Preview 전략

Preview 속도는 이 프로젝트의 핵심 설계 목표다.

### 11.1 원칙

- 모든 Feature Preview는 mock dependency를 사용한다.
- Preview에서 live `ModelContainer` 초기화를 요구하지 않는다.
- mock 데이터는 즉시 반환되어야 한다.
- 빈 상태, 일반 상태, 소진 예상 상태 등 주요 UI 상태를 각각 Preview로 제공한다.

### 11.2 구현 권장안

- `DatabaseClient.previewValue`
- `DatabaseClient.testValue`
- Fixture 빌더
- Feature별 대표 Preview 세트
  - 대시보드 일반 상태
  - 대시보드 빈 상태
  - 복수 활성 원두 상태
  - 소진 예상 상태
  - 추출 기록 기본값 상태

## 12. 위젯 설계

### 12.1 1.0 범위

- 소형 위젯 1종
- 빠른 기록 진입 버튼
- 앱의 추출 기록 화면 딥링크 연결

### 12.2 구현 메모

- App Intents 또는 딥링크 방식 중 플랫폼 적합성이 높은 방식을 사용한다.
- 위젯은 기록 시작 마찰 감소에 집중한다.
- 대시보드 계산 로직을 위젯에 중복 구현하지 않는다.

## 13. 플랫폼 대응 전략

### 13.1 공통화 대상

- 도메인 계산
- Reducer
- Dependency 계약
- 대부분의 화면 로직

### 13.2 플랫폼별 조정 허용 범위

- 네비게이션 컨테이너
- 툴바 배치
- 패널/시트 표현 방식
- 여백과 레이아웃 밀도

목표는 픽셀 단위 동일 UI가 아니라, 핵심 기능의 동일 제공이다.

## 14. 현지화 전략

- 1.0에서 한국어/영어 동시 지원
- 사용자 노출 문자열은 중앙 관리
- 숫자, 통화, 날짜 포맷은 locale 기반 처리
- 차트 축과 월 표기도 지역화 필요

## 15. 테스트 전략

### 15.1 우선 테스트 대상

- 절약액 계산
- 월별 구매 비용 계산
- 남은 원두량과 소진 예상 판단
- 최근 원두/최근 사용량 기본값 로직
- 삭제 플로우

### 15.2 테스트 종류

- `CoffeeDomain` 단위 테스트
- TCA Reducer 테스트
- 필요 최소한의 persistence adapter 통합 테스트

## 16. 현재 템플릿에서의 전환 순서

현재 프로젝트는 기본 SwiftData 템플릿 상태다. 권장 전환 순서는 다음과 같다.

1. Tuist 구조 도입
2. `CoffeeDomain` 분리
3. `DatabaseClient` 도입
4. 기본 `Item` 모델 제거 및 실제 모델 반영
5. 온보딩/원두/추출/대시보드 Feature 구현
6. 위젯, 다국어, CloudKit 검증

## 17. 1.0 완료 기준

- iPhone, iPad, macOS에서 핵심 기능이 동작한다.
- 각 Feature Preview가 mock dependency로 즉시 열린다.
- PRD에 정의된 계산 규칙과 실제 앱 동작이 일치한다.
- 같은 Apple ID 기준 동기화가 동작한다.
- 위젯이 추출 기록 화면으로 진입한다.
- 한국어/영어 UI가 정상 동작한다.
- 코드베이스가 모듈 아키텍처를 설명 가능한 수준으로 정리되어 있다.
