# BeanTracker

BeanTracker는 홈카페 사용자가 원두 소비를 최소 입력으로 기록하고, 집에서 커피를 내려 마시며 절약한 금액을 월 단위로 확인할 수 있게 해주는 개인 대시보드 앱입니다.

## Codex-First Guide

- Codex와 사람이 함께 보는 짧은 진입점은 [`AGENTS.md`](AGENTS.md)입니다.
- 이 저장소의 source of truth는 [`docs/`](docs/index.md)입니다.
- `wiki/`는 외부 공유용 요약 레이어이며 정본이 아닙니다.

## 표준 명령

1. `scripts/check-harness`
2. `scripts/bootstrap`
3. `scripts/test-domain`
4. `scripts/build-app`

프로젝트 그래프가 바뀌면 `scripts/generate`를 사용합니다.

## 문서 맵

- [`docs/index.md`](docs/index.md): 문서 인덱스
- [`docs/architecture.md`](docs/architecture.md): 현재 아키텍처와 경계
- [`docs/PRD-v2.md`](docs/PRD-v2.md): 제품 요구사항 정본
- [`docs/Tech-Spec-v2.md`](docs/Tech-Spec-v2.md): 기술 설계 정본
- [`docs/quality-score.md`](docs/quality-score.md): 현재 품질 상태와 우선 과제
- [`docs/references/language-policy.md`](docs/references/language-policy.md): 문서 언어 기준선
- [`docs/references/commands.md`](docs/references/commands.md): 반복 가능한 로컬 명령

## 현재 프로젝트 구조

- `Workspace.swift`: 전체 워크스페이스 정의
- `Tuist/Package.swift`: 외부 패키지 의존성 정의
- `Projects/App`: 앱 타깃과 루트 TCA 구성
- `Projects/Features/*`: 대시보드, 추출 기록, 원두 창고, 온보딩, 설정
- `Projects/Domain/CoffeeDomain`: 순수 모델, 계산 로직, fixtures, domain tests
- `Projects/Core/DatabaseClient`: 의존성 클라이언트와 현재 인메모리 구현

## 현재 상태 메모

- 핵심 지표: 이번 달 절약액
- 핵심 경험: 원두 등록 -> 추출 기록 -> 절약액 증가 확인 -> 월말 리뷰
- 기술 스택 목표: SwiftUI, TCA, Tuist, SwiftData, CloudKit
- 현재 `DatabaseClient.liveValue`는 아직 SwiftData/CloudKit이 아니라 인메모리 구현입니다.
- 현재 자동화 테스트는 `CoffeeDomain` 중심으로만 존재합니다.
