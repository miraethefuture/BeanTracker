import BrewingLogFeature
import ComposableArchitecture
import DashboardFeature
import InventoryFeature
import OnboardingFeature
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Group {
                if viewStore.isBootstrapping {
                    ProgressView("BeanTracker 준비 중")
                } else if viewStore.hasCompletedOnboarding {
                    TabView(
                        selection: viewStore.binding(
                            get: \.selectedTab,
                            send: AppFeature.Action.selectedTabChanged
                        )
                    ) {
                        NavigationStack {
                            DashboardView(
                                store: store.scope(state: \.dashboard, action: \.dashboard)
                            )
                        }
                        .tag(AppFeature.Tab.dashboard)
                        .tabItem {
                            Label("대시보드", systemImage: "chart.bar.xaxis")
                        }

                        NavigationStack {
                            BrewingLogView(
                                store: store.scope(state: \.brewingLog, action: \.brewingLog)
                            )
                        }
                        .tag(AppFeature.Tab.brewing)
                        .tabItem {
                            Label("커피 내리기", systemImage: "cup.and.saucer")
                        }

                        NavigationStack {
                            InventoryView(
                                store: store.scope(state: \.inventory, action: \.inventory)
                            )
                        }
                        .tag(AppFeature.Tab.inventory)
                        .tabItem {
                            Label("원두 창고", systemImage: "shippingbox")
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
            .onOpenURL { url in
                viewStore.send(.openURL(url))
            }
        }
    }
}
