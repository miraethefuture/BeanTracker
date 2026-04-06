# Tech Spec v2

## 기술 목표

- Preview가 빠른 구조를 유지한다.
- Tuist 기반 모듈 아키텍처를 명확히 드러낸다.
- TCA로 Feature 상태를 분리한다.
- SwiftData와 CloudKit으로 로컬 우선 저장과 기기 간 동기화를 제공한다.

## 고정 스택

- SwiftUI
- TCA
- Tuist
- SwiftData
- CloudKit
- Swift Charts
- WidgetKit

## 모듈 계층

`Feature -> Domain -> Core`

- App: `BeanTrackerApp`
- Feature: `DashboardFeature`, `BrewingLogFeature`, `InventoryFeature`, `OnboardingFeature`, `SettingsFeature`
- Domain: `CoffeeDomain`
- Core: `DatabaseClient`

## 핵심 규칙

- Feature는 `ModelContext`에 직접 접근하지 않는다.
- 저장/조회는 모두 `DatabaseClient`를 거친다.
- 계산 로직은 `CoffeeDomain`에 둔다.
- Preview는 항상 mock dependency를 사용한다.

## 1.0 구현 포인트

- Dashboard Hero는 이번 달 절약액
- 빠른 추출 기록 기본값 로직
- 월별 차트와 집계
- 같은 Apple ID 기준 CloudKit 동기화
- 소형 위젯에서 추출 기록 화면 딥링크
