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
                        Text("이번 달 절약액")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(currencyText(viewStore.snapshot.monthlySavings))
                            .font(.system(size: 40, weight: .bold, design: .rounded))

                        Text("기준 카페 가격과 원두 사용량을 바탕으로 계산한 이번 달 누적 절약액입니다.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                            y: .value("절약액", entry.savings)
                        )
                        .foregroundStyle(.tint)
                    }
                    .frame(height: 220)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("월 상세 통계")
                            .font(.headline)

                        statRow(title: "월 절약액", value: currencyText(viewStore.snapshot.monthlySavings))
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
