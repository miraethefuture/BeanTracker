import CoffeeDomain
import ComposableArchitecture
import DatabaseClient
import SwiftUI

@Reducer
public struct InventoryFeature {
    public struct State: Equatable {
        public var activeBeans: [InventoryBeanSummary]
        public var exhaustedBeans: [InventoryBeanSummary]
        public var beanName: String
        public var roaster: String
        public var totalWeight: String
        public var price: String
        public var purchaseDate: Date
        public var pendingDeleteBeanID: UUID?

        public init(
            activeBeans: [InventoryBeanSummary] = [],
            exhaustedBeans: [InventoryBeanSummary] = [],
            beanName: String = "",
            roaster: String = "",
            totalWeight: String = "",
            price: String = "",
            purchaseDate: Date = .now,
            pendingDeleteBeanID: UUID? = nil
        ) {
            self.activeBeans = activeBeans
            self.exhaustedBeans = exhaustedBeans
            self.beanName = beanName
            self.roaster = roaster
            self.totalWeight = totalWeight
            self.price = price
            self.purchaseDate = purchaseDate
            self.pendingDeleteBeanID = pendingDeleteBeanID
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
        case confirmDeleteBean
        case deleteCancelled
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
                state.pendingDeleteBeanID = beanID
                return .none

            case .confirmDeleteBean:
                guard let beanID = state.pendingDeleteBeanID else { return .none }
                state.pendingDeleteBeanID = nil
                let databaseClient = self.databaseClient
                return .run { send in
                    try await databaseClient.deleteBean(beanID)
                    await send(.delegate(.didChangeInventory))
                }

            case .deleteCancelled:
                state.pendingDeleteBeanID = nil
                return .none

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
                                beanSummary: bean,
                                cupCountLabel: "현재까지 \(bean.cupCount)잔",
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
                                beanSummary: bean,
                                cupCountLabel: "총 \(bean.cupCount)잔",
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
            .confirmationDialog(
                "원두를 삭제할까요?",
                isPresented: Binding(
                    get: { viewStore.pendingDeleteBeanID != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewStore.send(.deleteCancelled)
                        }
                    }
                )
            ) {
                Button("삭제", role: .destructive) {
                    viewStore.send(.confirmDeleteBean)
                }
                Button("취소", role: .cancel) {
                    viewStore.send(.deleteCancelled)
                }
            } message: {
                Text("삭제하면 이 원두와 연결된 추출 기록도 함께 사라집니다. 다 마신 원두라면 삭제 대신 소진 처리를 고려해 보세요.")
            }
            .task {
                await viewStore.send(.task).finish()
            }
        }
    }
 
    @ViewBuilder
    private func beanRow(
        beanSummary: InventoryBeanSummary,
        cupCountLabel: String,
        actionTitle: String,
        action: @escaping () -> Void,
        delete: @escaping () -> Void
    ) -> some View {
        let bean = beanSummary.bean

        VStack(alignment: .leading, spacing: 8) {
            Text(bean.name)
                .font(.headline)
            Text("\(bean.roaster) · \(bean.totalWeight, specifier: "%.0f")g · \(bean.price.formatted())원")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(cupCountLabel)
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
