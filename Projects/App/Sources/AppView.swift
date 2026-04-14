import BrewingLogFeature
import ComposableArchitecture
import DashboardFeature
import InventoryFeature
import OnboardingFeature
import SettingsFeature
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { ViewState(state: $0) }) { viewStore in
            Group {
                if viewStore.isBootstrapping {
                    ProgressView("BeanTracker 준비 중")
                } else if viewStore.hasCompletedOnboarding {
                    TabView {
                        NavigationStack {
                            DashboardView(
                                store: store.scope(state: \.dashboard, action: \.dashboard)
                            )
                        }
                        .tabItem {
                            Label("대시보드", systemImage: "chart.bar.xaxis")
                        }

                        NavigationStack {
                            BrewingLogView(
                                store: store.scope(state: \.brewingLog, action: \.brewingLog)
                            )
                        }
                        .tabItem {
                            Label("커피 내리기", systemImage: "cup.and.saucer")
                        }

                        NavigationStack {
                            InventoryView(
                                store: store.scope(state: \.inventory, action: \.inventory)
                            )
                        }
                        .tabItem {
                            Label("원두 창고", systemImage: "shippingbox")
                        }

                        NavigationStack {
                            SettingsView(
                                store: store.scope(state: \.settings, action: \.settings)
                            )
                        }
                        .tabItem {
                            Label("설정", systemImage: "gearshape")
                        }
                    }
                } else {
                    NavigationStack {
                        OnboardingView(
                            store: store.scope(state: \.onboarding, action: \.onboarding)
                        )
                    }
                }
            }
            .task {
                await viewStore.send(.task).finish()
            }
        }
    }
}

private struct ViewState: Equatable {
    let isBootstrapping: Bool
    let hasCompletedOnboarding: Bool

    init(state: AppFeature.State) {
        self.isBootstrapping = state.isBootstrapping
        self.hasCompletedOnboarding = state.hasCompletedOnboarding
    }
}
