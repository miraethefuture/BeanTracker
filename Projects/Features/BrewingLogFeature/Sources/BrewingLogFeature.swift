import CoffeeDomain
import ComposableArchitecture
import DatabaseClient
import Foundation
import SwiftUI

@Reducer
public struct BrewingLogFeature {
    public struct State: Equatable {
        public var beans: [Bean]
        public var selectedBeanID: UUID?
        public var usedWeight: String
        public var isSaving: Bool
        public var saveMessage: String?

        public init(
            beans: [Bean] = [],
            selectedBeanID: UUID? = nil,
            usedWeight: String = "20",
            isSaving: Bool = false,
            saveMessage: String? = nil
        ) {
            self.beans = beans
            self.selectedBeanID = selectedBeanID
            self.usedWeight = usedWeight
            self.isSaving = isSaving
            self.saveMessage = saveMessage
        }
    }

    public enum Action: Equatable {
        case task
        case defaultsResponse(BrewDefaults)
        case selectedBeanChanged(UUID?)
        case usedWeightChanged(String)
        case saveButtonTapped
        case saveCompleted(BrewSaveResult)
        case delegate(Delegate)
    }

    public enum Delegate: Equatable {
        case didSaveBrew
    }

    @Dependency(\.databaseClient) var databaseClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                let databaseClient = self.databaseClient
                return .run { send in
                    let defaults = try await databaseClient.fetchBrewingDefaults()
                    await send(.defaultsResponse(defaults))
                }

            case let .defaultsResponse(defaults):
                state.beans = defaults.activeBeans
                state.selectedBeanID = defaults.selectedBeanID
                state.usedWeight = String(Int(defaults.usedWeight.rounded()))
                return .none

            case let .selectedBeanChanged(beanID):
                state.selectedBeanID = beanID
                return .none

            case let .usedWeightChanged(value):
                state.usedWeight = value
                return .none

            case .saveButtonTapped:
                guard let selectedBeanID = state.selectedBeanID, let usedWeight = Double(state.usedWeight) else {
                    return .none
                }

                state.isSaving = true
                state.saveMessage = nil
                let databaseClient = self.databaseClient

                return .run { send in
                    let result = try await databaseClient.addBrewLog(
                        BrewLog(
                            beanId: selectedBeanID,
                            usedWeight: usedWeight,
                            date: .now
                        )
                    )
                    await send(.saveCompleted(result))
                }

            case let .saveCompleted(result):
                state.isSaving = false
                state.saveMessage = "\(result.beanName)로 \(result.cupCount)잔째예요."

                return .merge(
                    .send(.delegate(.didSaveBrew)),
                    .send(.task)
                )

            case .delegate:
                return .none
            }
        }
    }
}

public struct BrewingLogView: View {
    let store: StoreOf<BrewingLogFeature>

    public init(store: StoreOf<BrewingLogFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 46) {
                    header

                    if viewStore.beans.isEmpty {
                        emptyState
                    } else {
                        beanSelectionMenu(viewStore: viewStore)
                        usageControl(viewStore: viewStore)
                        recordButton(viewStore: viewStore)
                    }

                    if let saveMessage = viewStore.saveMessage {
                        saveMessageCard(saveMessage)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 34)
                .padding(.bottom, 32)
            }
            .background(BrewingLogStyle.background.ignoresSafeArea())
            .navigationTitle("새 브루잉")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewStore.send(.task).finish()
            }
        }
    }

    private var header: some View {
        Text("새 브루잉")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(BrewingLogStyle.espresso)
            .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cup.and.saucer")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(BrewingLogStyle.caramel)
                .frame(width: 64, height: 64)
                .background(.white, in: Circle())
                .overlay {
                    Circle()
                        .stroke(BrewingLogStyle.pearl, lineWidth: 1)
                }

            Text("먼저 원두를 등록해 주세요.")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(BrewingLogStyle.espresso)

            Text("활성 원두가 생기면 바로 사용량을 조절하고 기록할 수 있어요.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BrewingLogStyle.olive)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(BrewingLogStyle.pearl.opacity(0.75), lineWidth: 1)
        }
    }

    private func beanSelectionMenu(viewStore: ViewStore<BrewingLogFeature.State, BrewingLogFeature.Action>) -> some View {
        Menu {
            ForEach(viewStore.beans) { bean in
                Button {
                    viewStore.send(.selectedBeanChanged(bean.id))
                } label: {
                    if bean.id == viewStore.selectedBeanID {
                        Label(bean.name, systemImage: "checkmark")
                    } else {
                        Text(bean.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BrewingLogStyle.espresso)
                    .frame(width: 32, height: 32)
                    .background(BrewingLogStyle.pampas, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("선택된 원두")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(BrewingLogStyle.olive)

                    Text(selectedBeanName(viewStore: viewStore))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(BrewingLogStyle.espresso)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(BrewingLogStyle.olive)
            }
            .padding(.horizontal, 21)
            .padding(.vertical, 15)
            .frame(maxWidth: 260)
            .background(.white, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(BrewingLogStyle.pearl, lineWidth: 1)
            }
            .shadow(color: BrewingLogStyle.espresso.opacity(0.1), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func usageControl(viewStore: ViewStore<BrewingLogFeature.State, BrewingLogFeature.Action>) -> some View {
        VStack(spacing: 32) {
            Text("사용량 (g)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BrewingLogStyle.caramel)

            HStack(spacing: 16) {
                stepButton(systemName: "minus") {
                    adjustUsedWeight(by: -1, viewStore: viewStore)
                }

                TextField(
                    "0",
                    text: viewStore.binding(
                        get: \.usedWeight,
                        send: BrewingLogFeature.Action.usedWeightChanged
                    )
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 84, weight: .bold, design: .rounded))
                .foregroundStyle(BrewingLogStyle.espresso)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(minWidth: 72, maxWidth: 118)

                stepButton(systemName: "plus") {
                    adjustUsedWeight(by: 1, viewStore: viewStore)
                }
            }
        }
    }

    private func recordButton(viewStore: ViewStore<BrewingLogFeature.State, BrewingLogFeature.Action>) -> some View {
        Button {
            viewStore.send(.saveButtonTapped)
        } label: {
            HStack(spacing: 8) {
                if viewStore.isSaving {
                    ProgressView()
                        .tint(BrewingLogStyle.surface)
                } else {
                    Image(systemName: "drop")
                        .font(.system(size: 17, weight: .bold))
                    Text("기록하기")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .foregroundStyle(BrewingLogStyle.surface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(BrewingLogStyle.espresso, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: BrewingLogStyle.espresso.opacity(0.2), radius: 20, x: 0, y: 14)
        }
        .buttonStyle(.plain)
        .disabled(isRecordDisabled(viewStore: viewStore))
        .opacity(isRecordDisabled(viewStore: viewStore) ? 0.55 : 1)
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(BrewingLogStyle.espresso)
                .frame(width: 64, height: 64)
                .background(.white, in: Circle())
                .overlay {
                    Circle()
                        .stroke(BrewingLogStyle.pearl, lineWidth: 1)
                }
                .shadow(color: BrewingLogStyle.espresso.opacity(0.1), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func saveMessageCard(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .bold))
            Text(message)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(BrewingLogStyle.espresso)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BrewingLogStyle.caramel.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func selectedBeanName(viewStore: ViewStore<BrewingLogFeature.State, BrewingLogFeature.Action>) -> String {
        viewStore.beans.first { $0.id == viewStore.selectedBeanID }?.name ?? "원두를 선택해 주세요"
    }

    private func adjustUsedWeight(
        by delta: Double,
        viewStore: ViewStore<BrewingLogFeature.State, BrewingLogFeature.Action>
    ) {
        let currentWeight = Double(viewStore.usedWeight) ?? 0
        let nextWeight = max(1, currentWeight + delta)
        viewStore.send(.usedWeightChanged(weightText(nextWeight)))
    }

    private func weightText(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.001 {
            return String(Int(rounded))
        }
        return String(format: "%.1f", value)
    }

    private func isRecordDisabled(viewStore: ViewStore<BrewingLogFeature.State, BrewingLogFeature.Action>) -> Bool {
        viewStore.selectedBeanID == nil || viewStore.isSaving || (Double(viewStore.usedWeight) ?? 0) <= 0
    }
}

private enum BrewingLogStyle {
    static let espresso = Color(red: 0.212, green: 0.145, blue: 0.106)
    static let caramel = Color(red: 0.761, green: 0.498, blue: 0.361)
    static let pearl = Color(red: 0.91, green: 0.886, blue: 0.851)
    static let pampas = Color(red: 0.961, green: 0.949, blue: 0.933)
    static let surface = Color(red: 0.988, green: 0.98, blue: 0.973)
    static let background = Color(red: 0.988, green: 0.98, blue: 0.973)
    static let olive = Color(red: 0.451, green: 0.498, blue: 0.416)
}
