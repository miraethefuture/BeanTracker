import ComposableArchitecture
import DatabaseClient
import SwiftUI

@Reducer
public struct OnboardingFeature {
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
        case didSavePreference(Int)
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
                return .send(.delegate(.didSavePreference(price)))

            case .delegate:
                return .none
            }
        }
    }
}

public struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    Text("BeanTracker는 홈카페 절약액을 월 단위로 보여주는 앱입니다.")
                    Text("먼저 자주 가는 카페의 커피 한 잔 가격을 입력해 주세요.")
                        .foregroundStyle(.secondary)
                }

                Section("기준 카페 가격") {
                    TextField(
                        "예: 4500",
                        text: viewStore.binding(
                            get: \.standardCafePrice,
                            send: OnboardingFeature.Action.standardCafePriceChanged
                        )
                    )

                    Button(action: { viewStore.send(.saveButtonTapped) }) {
                        if viewStore.isSaving {
                            ProgressView()
                        } else {
                            Text("시작하기")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("환영합니다")
        }
    }
}
