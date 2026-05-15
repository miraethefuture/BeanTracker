import ComposableArchitecture
import SwiftUI

@Reducer
public struct SettingsFeature {
    public struct State: Equatable {
        public init() {}
    }

    public enum Action: Equatable {
        case none
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .none:
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
                Section("앱 정보") {
                    Text("현재 단계에서는 원두별 잔 수 추적과 홈카페 루틴 기록 경험을 우선 정리하고 있습니다.")
                        .foregroundStyle(.secondary)
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
