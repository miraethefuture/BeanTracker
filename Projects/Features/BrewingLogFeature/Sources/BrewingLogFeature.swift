import CoffeeDomain
import ComposableArchitecture
import DatabaseClient
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
        case saveCompleted
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
                    try await databaseClient.addBrewLog(
                        BrewLog(
                            beanId: selectedBeanID,
                            usedWeight: usedWeight,
                            date: .now
                        )
                    )
                    await send(.saveCompleted)
                }

            case .saveCompleted:
                state.isSaving = false
                state.saveMessage = "추출을 기록했어요."

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
            Form {
                Section("빠른 기록") {
                    if viewStore.beans.isEmpty {
                        Text("먼저 원두를 등록해 주세요.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(
                            "원두",
                            selection: viewStore.binding(
                                get: \.selectedBeanID,
                                send: BrewingLogFeature.Action.selectedBeanChanged
                            )
                        ) {
                            ForEach(viewStore.beans) { bean in
                                Text(bean.name)
                                    .tag(Optional(bean.id))
                            }
                        }

                        TextField(
                            "사용량(g)",
                            text: viewStore.binding(
                                get: \.usedWeight,
                                send: BrewingLogFeature.Action.usedWeightChanged
                            )
                        )

                        Button(action: { viewStore.send(.saveButtonTapped) }) {
                            if viewStore.isSaving {
                                ProgressView()
                            } else {
                                Text("추출 완료")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewStore.selectedBeanID == nil || viewStore.isSaving)
                    }
                }

                if let saveMessage = viewStore.saveMessage {
                    Section {
                        Text(saveMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("커피 내리기")
            .task {
                await viewStore.send(.task).finish()
            }
        }
    }
}
