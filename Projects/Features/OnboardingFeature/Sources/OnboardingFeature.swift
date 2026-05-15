import ComposableArchitecture
import SwiftUI

@Reducer
public struct OnboardingFeature {
    public struct State: Equatable {
        public init() {}
    }

    public enum Action: Equatable {
        case continueButtonTapped
        case delegate(Delegate)
    }

    public enum Delegate: Equatable {
        case didFinishOnboarding
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .continueButtonTapped:
                return .send(.delegate(.didFinishOnboarding))

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
                    Text("BeanTracker는 원두별 소비를 기록하고, 각 원두로 몇 잔을 마셨는지 보여주는 앱입니다.")
                    Text("먼저 첫 원두를 등록하고 추출 기록을 시작해 보세요.")
                        .foregroundStyle(.secondary)
                }

                Section("시작하기") {
                    Button(action: { viewStore.send(.continueButtonTapped) }) {
                        Text("첫 원두 등록하러 가기")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("환영합니다")
        }
    }
}
