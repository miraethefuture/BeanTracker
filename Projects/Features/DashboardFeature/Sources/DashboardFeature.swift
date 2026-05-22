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
                VStack(alignment: .leading, spacing: 20) {
                    header
                    heroCard(snapshot: viewStore.snapshot)
                    currentBeanCard(snapshot: viewStore.snapshot)
                    monthlyFlowCard(viewStore: viewStore)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(BeanTrackerHomeStyle.background.ignoresSafeArea())
            .navigationTitle("홈")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if viewStore.isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .padding(28)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .task {
                await viewStore.send(.task).finish()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("홈")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(BeanTrackerHomeStyle.espresso)

            Text("오늘도 향긋한 하루 되세요")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BeanTrackerHomeStyle.olive)
        }
        .padding(.bottom, 8)
    }

    private func heroCard(snapshot: DashboardSnapshot) -> some View {
        let cupCount = snapshot.currentBeanSummary?.cupCount
        let valueText = cupCount.map(String.init) ?? "준비"
        let message = heroMessage(for: snapshot)

        return ZStack(alignment: .topTrailing) {
            Circle()
                .fill(BeanTrackerHomeStyle.caramel.opacity(0.28))
                .frame(width: 160, height: 160)
                .blur(radius: 30)
                .offset(x: 42, y: -60)

            VStack(alignment: .leading, spacing: 6) {
                Text("이번 원두로 즐긴 커피")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BeanTrackerHomeStyle.pearl)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(valueText)
                        .font(.system(size: cupCount == nil ? 42 : 60, weight: .bold, design: .rounded))
                        .foregroundStyle(BeanTrackerHomeStyle.surface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    if cupCount != nil {
                        Text("잔")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(BeanTrackerHomeStyle.caramel)
                    }
                }
                .padding(.bottom, 12)

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    Text(message)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(BeanTrackerHomeStyle.surface)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(BeanTrackerHomeStyle.espresso, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: BeanTrackerHomeStyle.espresso.opacity(0.2), radius: 20, x: 0, y: 14)
    }

    @ViewBuilder
    private func currentBeanCard(snapshot: DashboardSnapshot) -> some View {
        if let currentBeanStatus = snapshot.currentBeanStatus {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CURRENT BEAN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(BeanTrackerHomeStyle.caramel)

                        Text(currentBeanStatus.beanName)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(BeanTrackerHomeStyle.espresso)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if let currentBeanSummary = snapshot.currentBeanSummary {
                            Text("\(currentBeanSummary.cupCount)잔째 함께하는 원두")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BeanTrackerHomeStyle.olive)
                        }
                    }

                    Spacer(minLength: 16)

                    Image(systemName: currentBeanStatus.isExhaustionWarning ? "flame" : "drop")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BeanTrackerHomeStyle.espresso)
                        .frame(width: 36, height: 36)
                        .background(BeanTrackerHomeStyle.background, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(BeanTrackerHomeStyle.pearl.opacity(0.75), lineWidth: 1)
                        }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("남은 원두")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BeanTrackerHomeStyle.espresso)

                        Spacer()

                        Text("\(Int(currentBeanStatus.remainingWeight.rounded()))g 남음")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BeanTrackerHomeStyle.espresso)
                    }

                    progressBar(fill: estimatedRemainingFraction(snapshot: snapshot))

                    HStack {
                        Text(expectedRemainingText(currentBeanStatus.expectedRemainingCups))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BeanTrackerHomeStyle.olive)

                        Spacer(minLength: 12)

                        if currentBeanStatus.isExhaustionWarning {
                            warningBadge
                        }
                    }
                    .padding(.top, 12)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(BeanTrackerHomeStyle.pampas)
                            .frame(height: 1)
                    }
                }
            }
            .padding(21)
            .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(BeanTrackerHomeStyle.pearl.opacity(0.6), lineWidth: 1)
            }
            .shadow(color: BeanTrackerHomeStyle.espresso.opacity(0.04), radius: 12, x: 0, y: 8)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("CURRENT BEAN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(BeanTrackerHomeStyle.caramel)
                Text("활성 원두가 없어요")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(BeanTrackerHomeStyle.espresso)
                Text("원두를 등록하면 현재 마시는 원두의 잔 수와 남은 양을 이곳에서 볼 수 있어요.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BeanTrackerHomeStyle.olive)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(21)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(BeanTrackerHomeStyle.pearl.opacity(0.6), lineWidth: 1)
            }
        }
    }

    private func monthlyFlowCard(viewStore: ViewStore<DashboardFeature.State, DashboardFeature.Action>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text("월간 브루잉 흐름")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(BeanTrackerHomeStyle.espresso)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: { viewStore.send(.previousMonthTapped) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                    }

                    Text(viewStore.snapshot.monthLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BeanTrackerHomeStyle.olive)
                        .lineLimit(1)

                    Button(action: { viewStore.send(.nextMonthTapped) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(BeanTrackerHomeStyle.espresso)
            }

            Chart(viewStore.snapshot.chartEntries) { entry in
                BarMark(
                    x: .value("월", entry.month, unit: .month),
                    y: .value("잔 수", entry.cupCount)
                )
                .foregroundStyle(BeanTrackerHomeStyle.caramel)
                .cornerRadius(5)
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel()
                        .foregroundStyle(BeanTrackerHomeStyle.olive)
                }
            }
            .frame(height: 100)

            VStack(spacing: 8) {
                statRow(title: "월 총 잔 수", value: "\(viewStore.snapshot.monthlyCupCount)잔")
                statRow(title: "월 원두 소비량", value: "\(Int(viewStore.snapshot.monthlyBeanUsage.rounded()))g")
                statRow(title: "월 원두 구매 비용", value: currencyText(viewStore.snapshot.monthlyPurchaseCost))
            }
        }
        .padding(21)
        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(BeanTrackerHomeStyle.pearl.opacity(0.6), lineWidth: 1)
        }
        .shadow(color: BeanTrackerHomeStyle.espresso.opacity(0.04), radius: 12, x: 0, y: 8)
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .fontWeight(.semibold)
                .foregroundStyle(BeanTrackerHomeStyle.espresso)
        }
    }

    private func currencyText(_ value: Int) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "KRW"))
    }

    private var warningBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 10, weight: .bold))
            Text("소진 임박")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(BeanTrackerHomeStyle.caramel)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(BeanTrackerHomeStyle.caramel.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func progressBar(fill: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(BeanTrackerHomeStyle.pampas)
                Capsule()
                    .fill(BeanTrackerHomeStyle.caramel)
                    .frame(width: max(8, proxy.size.width * fill))
            }
        }
        .frame(height: 10)
    }

    private func estimatedRemainingFraction(snapshot: DashboardSnapshot) -> CGFloat {
        guard
            let expectedRemainingCups = snapshot.currentBeanStatus?.expectedRemainingCups,
            let cupCount = snapshot.currentBeanSummary?.cupCount
        else {
            return snapshot.currentBeanStatus?.isExhaustionWarning == true ? 0.22 : 0.55
        }

        let totalCupEstimate = Double(cupCount) + expectedRemainingCups
        guard totalCupEstimate > 0 else { return 0.08 }

        return CGFloat(min(max(expectedRemainingCups / totalCupEstimate, 0.08), 1))
    }

    private func expectedRemainingText(_ cups: Double?) -> String {
        guard let cups else { return "최근 사용량을 기록하면 예상 잔 수가 보여요" }

        let roundedCups = Int(cups.rounded(.down))
        if roundedCups <= 0 {
            return "예상 1잔 미만 남음"
        }
        return "예상 \(roundedCups)잔 남음"
    }

    private func heroMessage(for snapshot: DashboardSnapshot) -> String {
        guard let currentBeanSummary = snapshot.currentBeanSummary else {
            return "첫 원두를 기다리고 있어요"
        }

        if currentBeanSummary.cupCount == 0 {
            return "첫 기록을 남겨볼까요?"
        }

        return "완벽한 한 잔이었길 바라요!"
    }
}

private enum BeanTrackerHomeStyle {
    static let espresso = Color(red: 0.212, green: 0.145, blue: 0.106)
    static let caramel = Color(red: 0.761, green: 0.498, blue: 0.361)
    static let pearl = Color(red: 0.91, green: 0.886, blue: 0.851)
    static let pampas = Color(red: 0.961, green: 0.949, blue: 0.933)
    static let surface = Color(red: 0.988, green: 0.98, blue: 0.973)
    static let background = Color(red: 0.988, green: 0.98, blue: 0.973)
    static let olive = Color(red: 0.451, green: 0.498, blue: 0.416)
}
