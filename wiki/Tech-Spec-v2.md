# Tech Spec v2

이 문서는 위키용 요약본이다.

정본 기술 문서는 [`docs/Tech-Spec-v2.md`](../docs/Tech-Spec-v2.md)다.

## 요약

- 아키텍처 목표는 `Feature -> Domain -> Core` 구조 유지다.
- 저장소 접근은 `DatabaseClient`를 통해 캡슐화한다.
- 계산 로직은 `CoffeeDomain`에 둔다.
- 상세 Preview 전략, 테스트 전략, SwiftData/CloudKit 계획은 정본 Tech Spec을 따른다.

- Dashboard Hero는 이번 달 절약액
- 빠른 추출 기록 기본값 로직
- 월별 차트와 집계
- 같은 Apple ID 기준 CloudKit 동기화
- 소형 위젯에서 추출 기록 화면 딥링크
