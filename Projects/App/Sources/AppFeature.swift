import BrewingLogFeature
import ComposableArchitecture
import DashboardFeature
import DatabaseClient
import Foundation
import InventoryFeature
import OnboardingFeature

@Reducer
struct AppFeature {
    enum Tab: Hashable {
        case dashboard
        case brewing
        case inventory
    }

    enum DeepLink: Equatable {
        case brewing
    }

    struct State: Equatable {
        var isBootstrapping = true
        var hasCompletedOnboarding = false
        var selectedTab: Tab = .dashboard
        var pendingDeepLink: DeepLink?
        var dashboard = DashboardFeature.State()
        var brewingLog = BrewingLogFeature.State()
        var inventory = InventoryFeature.State()
        var onboarding = OnboardingFeature.State()
    }

    enum Action: Equatable {
        case task
        case bootstrapResponse(Bool)
        case openURL(URL)
        case selectedTabChanged(Tab)
        case dashboard(DashboardFeature.Action)
        case brewingLog(BrewingLogFeature.Action)
        case inventory(InventoryFeature.Action)
        case onboarding(OnboardingFeature.Action)
    }

    @Dependency(\.databaseClient) var databaseClient

    var body: some ReducerOf<Self> {
        Scope(state: \.dashboard, action: \.dashboard) {
            DashboardFeature()
        }
        Scope(state: \.brewingLog, action: \.brewingLog) {
            BrewingLogFeature()
        }
        Scope(state: \.inventory, action: \.inventory) {
            InventoryFeature()
        }
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Reduce { state, action in
            switch action {
            case .task:
                state.isBootstrapping = true
                let databaseClient = self.databaseClient

                return .run { send in
                    let hasCompletedOnboarding = try await databaseClient.fetchHasCompletedOnboarding()
                    await send(.bootstrapResponse(hasCompletedOnboarding))
                }

            case let .bootstrapResponse(hasCompletedOnboarding):
                state.isBootstrapping = false
                state.hasCompletedOnboarding = hasCompletedOnboarding
                if hasCompletedOnboarding {
                    Self.applyPendingDeepLink(to: &state)
                }

                return .merge(
                    .send(.dashboard(.task)),
                    .send(.brewingLog(.task)),
                    .send(.inventory(.task))
                )

            case let .openURL(url):
                guard let deepLink = Self.deepLink(from: url) else {
                    return .none
                }

                state.pendingDeepLink = deepLink
                guard state.hasCompletedOnboarding, !state.isBootstrapping else {
                    return .none
                }

                Self.applyPendingDeepLink(to: &state)
                switch deepLink {
                case .brewing:
                    return .send(.brewingLog(.task))
                }

            case .selectedTabChanged(let tab):
                state.selectedTab = tab
                return .none

            case .onboarding(.delegate(.didFinishOnboarding)):
                state.hasCompletedOnboarding = true
                Self.applyPendingDeepLink(to: &state, fallback: .inventory)
                let databaseClient = self.databaseClient

                return .run { send in
                    try await databaseClient.completeOnboarding()
                    await send(.dashboard(.task))
                    await send(.brewingLog(.task))
                    await send(.inventory(.task))
                }

            case .brewingLog(.delegate(.didSaveBrew)):
                return .merge(
                    .send(.dashboard(.task)),
                    .send(.inventory(.task))
                )

            case .inventory(.delegate(.didChangeInventory)):
                return .merge(
                    .send(.dashboard(.task)),
                    .send(.brewingLog(.task)),
                    .send(.inventory(.task))
                )

            case .dashboard, .brewingLog, .inventory, .onboarding:
                return .none
            }
        }
    }

    private static func deepLink(from url: URL) -> DeepLink? {
        guard url.scheme == "beantracker" else {
            return nil
        }

        if url.host == "brew" || url.path == "/brew" {
            return .brewing
        }

        return nil
    }

    private static func applyPendingDeepLink(to state: inout State, fallback: Tab? = nil) {
        guard let deepLink = state.pendingDeepLink else {
            if let fallback {
                state.selectedTab = fallback
            }
            return
        }

        switch deepLink {
        case .brewing:
            state.selectedTab = .brewing
        }
        state.pendingDeepLink = nil
    }
}
