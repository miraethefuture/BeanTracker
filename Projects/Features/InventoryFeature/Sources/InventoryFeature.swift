import CoffeeDomain
import ComposableArchitecture
import DatabaseClient
import SwiftUI

@Reducer
public struct InventoryFeature {
    public struct State: Equatable {
        public var activeBeans: [Bean]
        public var exhaustedBeans: [Bean]
        public var beanName: String
        public var roaster: String
        public var totalWeight: String
        public var price: String
        public var purchaseDate: Date

        public init(
            activeBeans: [Bean] = [],
            exhaustedBeans: [Bean] = [],
            beanName: String = "",
            roaster: String = "",
            totalWeight: String = "",
            price: String = "",
            purchaseDate: Date = .now
        ) {
            self.activeBeans = activeBeans
            self.exhaustedBeans = exhaustedBeans
            self.beanName = beanName
            self.roaster = roaster
            self.totalWeight = totalWeight
            self.price = price
            self.purchaseDate = purchaseDate
        }
    }

    public enum Action: Equatable {
        case task
        case inventoryResponse(InventorySnapshot)
        case beanNameChanged(String)
        case roasterChanged(String)
        case totalWeightChanged(String)
        case priceChanged(String)
        case purchaseDateChanged(Date)
        case saveBeanButtonTapped
        case deleteBeanButtonTapped(UUID)
        case setBeanExhausted(UUID, Bool)
        case delegate(Delegate)
    }

    public enum Delegate: Equatable {
        case didChangeInventory
    }

    @Dependency(\.databaseClient) var databaseClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                let databaseClient = self.databaseClient
                return .run { send in
                    let snapshot = try await databaseClient.fetchInventory()
                    await send(.inventoryResponse(snapshot))
                }

            case let .inventoryResponse(snapshot):
                state.activeBeans = snapshot.activeBeans
                state.exhaustedBeans = snapshot.exhaustedBeans
                return .none

            case let .beanNameChanged(value):
                state.beanName = value
                return .none

            case let .roasterChanged(value):
                state.roaster = value
                return .none

            case let .totalWeightChanged(value):
                state.totalWeight = value
                return .none

            case let .priceChanged(value):
                state.price = value
                return .none

            case let .purchaseDateChanged(value):
                state.purchaseDate = value
                return .none

            case .saveBeanButtonTapped:
                guard
                    !state.beanName.isEmpty,
                    !state.roaster.isEmpty,
                    let totalWeight = Double(state.totalWeight),
                    let price = Int(state.price)
                else {
                    return .none
                }

                let bean = Bean(
                    name: state.beanName,
                    roaster: state.roaster,
                    totalWeight: totalWeight,
                    price: price,
                    purchaseDate: state.purchaseDate
                )

                state.beanName = ""
                state.roaster = ""
                state.totalWeight = ""
                state.price = ""
                let databaseClient = self.databaseClient

                return .run { send in
                    try await databaseClient.saveBean(bean)
                    await send(.delegate(.didChangeInventory))
                }

            case let .deleteBeanButtonTapped(beanID):
                let databaseClient = self.databaseClient
                return .run { send in
                    try await databaseClient.deleteBean(beanID)
                    await send(.delegate(.didChangeInventory))
                }

            case let .setBeanExhausted(beanID, isExhausted):
                let databaseClient = self.databaseClient
                return .run { send in
                    try await databaseClient.setBeanExhausted(beanID, isExhausted)
                    await send(.delegate(.didChangeInventory))
                }

            case .delegate:
                return .none
            }
        }
    }
}

public struct InventoryView: View {
    let store: StoreOf<InventoryFeature>

    public init(store: StoreOf<InventoryFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section("새 원두 등록") {
                    TextField(
                        "원두 이름",
                        text: viewStore.binding(
                            get: \.beanName,
                            send: InventoryFeature.Action.beanNameChanged
                        )
                    )
                    TextField(
                        "로스터리",
                        text: viewStore.binding(
                            get: \.roaster,
                            send: InventoryFeature.Action.roasterChanged
                        )
                    )
                    TextField(
                        "총중량(g)",
                        text: viewStore.binding(
                            get: \.totalWeight,
                            send: InventoryFeature.Action.totalWeightChanged
                        )
                    )
                    TextField(
                        "가격(원)",
                        text: viewStore.binding(
                            get: \.price,
                            send: InventoryFeature.Action.priceChanged
                        )
                    )
                    DatePicker(
                        "구매일",
                        selection: viewStore.binding(
                            get: \.purchaseDate,
                            send: InventoryFeature.Action.purchaseDateChanged
                        ),
                        displayedComponents: .date
                    )

                    Button("원두 저장") {
                        viewStore.send(.saveBeanButtonTapped)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("재고 있음") {
                    if viewStore.activeBeans.isEmpty {
                        Text("등록된 활성 원두가 없습니다.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewStore.activeBeans) { bean in
                            beanRow(
                                bean: bean,
                                actionTitle: "다 마심 처리",
                                action: {
                                    viewStore.send(.setBeanExhausted(bean.id, true))
                                },
                                delete: {
                                    viewStore.send(.deleteBeanButtonTapped(bean.id))
                                }
                            )
                        }
                    }
                }

                Section("다 마심") {
                    if viewStore.exhaustedBeans.isEmpty {
                        Text("소진 처리한 원두가 없습니다.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewStore.exhaustedBeans) { bean in
                            beanRow(
                                bean: bean,
                                actionTitle: "재고로 되돌리기",
                                action: {
                                    viewStore.send(.setBeanExhausted(bean.id, false))
                                },
                                delete: {
                                    viewStore.send(.deleteBeanButtonTapped(bean.id))
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("원두 창고")
            .task {
                await viewStore.send(.task).finish()
            }
        }
    }

    private func beanRow(
        bean: Bean,
        actionTitle: String,
        action: @escaping () -> Void,
        delete: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bean.name)
                .font(.headline)
            Text("\(bean.roaster) · \(bean.totalWeight, specifier: "%.0f")g · \(bean.price.formatted())원")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Button(actionTitle, action: action)
                Button("삭제", role: .destructive, action: delete)
            }
            .buttonStyle(.borderless)
        }
    }
}
