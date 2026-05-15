import Charts
import CoffeeDomain
import ComposableArchitecture
import DatabaseClient
import Foundation
import SwiftUI

@Reducer
public struct DashboardFeature {
    public struct State: Equatable {
        public var selectedMonth: Date
        public var snapshot: DashboardSnapshot
        public var isLoading: Bool

        public init(
            selectedMonth: Date = .now,
            snapshot: DashboardSnapshot = CoffeeFixtures.sampleDashboardSnapshot(),
            isLoading: Bool = false
        ) {
            self.selectedMonth = selectedMonth
            self.snapshot = snapshot
            self.isLoading = isLoading
        }
    }

    public enum Action: Equatable {
        case task
        case previousMonthTapped
        case nextMonthTapped
        case snapshotResponse(DashboardSnapshot)
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.databaseClient) var databaseClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                let month = state.selectedMonth
                let databaseClient = self.databaseClient

                return .run { send in
                    let snapshot = try await databaseClient.fetchDashboard(month)
                    await send(.snapshotResponse(snapshot))
                }

            case .previousMonthTapped:
                state.selectedMonth = calendar.date(byAdding: .month, value: -1, to: state.selectedMonth) ?? state.selectedMonth
                return .send(.task)

            case .nextMonthTapped:
                state.selectedMonth = calendar.date(byAdding: .month, value: 1, to: state.selectedMonth) ?? state.selectedMonth
                return .send(.task)

            case let .snapshotResponse(snapshot):
                state.snapshot = snapshot
                state.isLoading = false
                return .none
            }
        }
    }
}

public struct DashboardView: View {
    let store: StoreOf<DashboardFeature>

    public init(store: StoreOf<DashboardFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        if let currentBeanSummary = viewStore.snapshot.currentBeanSummary {
                            Text(currentBeanSummary.beanName)
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            if currentBeanSummary.cupCount > 0 {
                                Text("\(currentBeanSummary.cupCount)잔")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))

                                Text("이 원두로 지금까지 기록한 누적 잔 수예요.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("아직 첫 잔을 마시지 않았어요")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))

                                Text("이 원두로 첫 추출을 기록하면 여기서 누적 잔 수를 바로 확인할 수 있어요.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("활성 원두가 없어요")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text("원두를 등록해 보세요")
                                .font(.system(size: 32, weight: .bold, design: .rounded))

                            Text("등록 후 추출을 기록하면 현재 마시는 원두의 누적 잔 수가 여기에 표시됩니다.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Button(action: { viewStore.send(.previousMonthTapped) }) {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Text(viewStore.snapshot.monthLabel)
                            .font(.headline)

                        Spacer()

                        Button(action: { viewStore.send(.nextMonthTapped) }) {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.bordered)
                    }

                    Chart(viewStore.snapshot.chartEntries) { entry in
                        BarMark(
                            x: .value("월", entry.month, unit: .month),
                            y: .value("잔 수", entry.cupCount)
                        )
                        .foregroundStyle(.tint)
                    }
                    .frame(height: 220)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("월 상세 통계")
                            .font(.headline)

                        statRow(title: "월 총 잔 수", value: "\(viewStore.snapshot.monthlyCupCount)잔")
                        statRow(title: "월 원두 소비량", value: "\(Int(viewStore.snapshot.monthlyBeanUsage.rounded()))g")
                        statRow(title: "월 원두 구매 비용", value: currencyText(viewStore.snapshot.monthlyPurchaseCost))
                    }

                    if let currentBeanStatus = viewStore.snapshot.currentBeanStatus {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("현재 원두 상태")
                                .font(.headline)

                            statRow(title: "원두", value: currentBeanStatus.beanName)
                            statRow(
                                title: "남은 원두량",
                                value: "\(Int(currentBeanStatus.remainingWeight.rounded()))g"
                            )
                            statRow(
                                title: "예상 남은 잔 수",
                                value: currentBeanStatus.expectedRemainingCups.map { String(Int($0.rounded(.down))) } ?? "-"
                            )
                            statRow(
                                title: "소진 예상",
                                value: currentBeanStatus.isExhaustionWarning ? "예" : "아니오"
                            )
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("대시보드")
            .overlay {
                if viewStore.isLoading {
                    ProgressView()
                }
            }
            .task {
                await viewStore.send(.task).finish()
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func currencyText(_ value: Int) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "KRW"))
    }
}
