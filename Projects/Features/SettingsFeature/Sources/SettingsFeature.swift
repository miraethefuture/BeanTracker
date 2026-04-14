import ComposableArchitecture
import DatabaseClient
import SwiftUI

@Reducer
public struct SettingsFeature {
    public struct State: Equatable {
        public var standardCafePrice: String
        public var isSaving: Bool

        public init(standardCafePrice: String = "4500", isSaving: Bool = false) {
            self.standardCafePrice = standardCafePrice
            self.isSaving = isSaving
        }
    }

    public enum Action: Equatable {
        case standardCafePriceChanged(String)
        case saveButtonTapped
        case saveCompleted(Int)
        case delegate(Delegate)
    }

    public enum Delegate: Equatable {
        case didUpdatePreference(Int)
    }

    @Dependency(\.databaseClient) var databaseClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .standardCafePriceChanged(value):
                state.standardCafePrice = value
                return .none

            case .saveButtonTapped:
                guard let price = Int(state.standardCafePrice) else { return .none }
                state.isSaving = true
                let databaseClient = self.databaseClient

                return .run { send in
                    try await databaseClient.saveUserPreference(price)
                    await send(.saveCompleted(price))
                }

            case let .saveCompleted(price):
                state.isSaving = false
                return .send(.delegate(.didUpdatePreference(price)))

            case .delegate:
                return .none
            }
        }
    }
}

public struct SettingsView: View {
    let store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section("기준 카페 가격") {
                    TextField(
                        "예: 4500",
                        text: viewStore.binding(
                            get: \.standardCafePrice,
                            send: SettingsFeature.Action.standardCafePriceChanged
                        )
                    )

                    Button(action: { viewStore.send(.saveButtonTapped) }) {
                        if viewStore.isSaving {
                            ProgressView()
                        } else {
                            Text("저장")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("구현 메모") {
                    Text("현재 단계에서는 Tuist 멀티 모듈 구조와 TCA 흐름을 우선 정리했습니다.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("설정")
        }
    }
}
