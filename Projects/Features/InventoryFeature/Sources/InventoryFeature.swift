import CoffeeDomain
import ComposableArchitecture
import DatabaseClient
import Foundation
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
    @State private var selectedTab: InventoryTab = .active
    @State private var isAddFormExpanded = false

    public init(store: StoreOf<InventoryFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    inventorySegmentedControl(viewStore: viewStore)
                    beanList(viewStore: viewStore)
                    addBeanCard(viewStore: viewStore)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(InventoryStyle.background.ignoresSafeArea())
            .navigationTitle("내 보관함")
            .navigationBarTitleDisplayMode(.inline)
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

    private var header: some View {
        Text("내 보관함")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(InventoryStyle.espresso)
    }

    private func inventorySegmentedControl(viewStore: ViewStore<InventoryFeature.State, InventoryFeature.Action>) -> some View {
        HStack(spacing: 0) {
            segmentButton(
                title: "사용 중 (\(viewStore.activeBeans.count))",
                tab: .active
            )
            segmentButton(
                title: "다 마심 (\(viewStore.exhaustedBeans.count))",
                tab: .exhausted
            )
        }
        .padding(4)
        .background(InventoryStyle.pampas, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func segmentButton(title: String, tab: InventoryTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(selectedTab == tab ? InventoryStyle.espresso : InventoryStyle.olive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white)
                            .shadow(color: InventoryStyle.espresso.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func beanList(viewStore: ViewStore<InventoryFeature.State, InventoryFeature.Action>) -> some View {
        let beans = selectedTab == .active ? viewStore.activeBeans : viewStore.exhaustedBeans

        if beans.isEmpty {
            emptyList
        } else {
            VStack(spacing: 16) {
                ForEach(beans) { bean in
                    beanCard(
                        beanSummary: bean,
                        tab: selectedTab,
                        viewStore: viewStore
                    )
                }
            }
        }
    }

    private var emptyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedTab == .active ? "사용 중인 원두가 없어요" : "다 마신 원두가 없어요")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(InventoryStyle.espresso)

            Text(selectedTab == .active ? "새 원두를 등록하면 보관함 카드로 관리할 수 있어요." : "원두를 다 마심 처리하면 완료된 기록이 이곳에 모입니다.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(InventoryStyle.olive)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(21)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(InventoryStyle.pearl.opacity(0.75), lineWidth: 1)
        }
    }

    private func beanCard(
        beanSummary: InventoryBeanSummary,
        tab: InventoryTab,
        viewStore: ViewStore<InventoryFeature.State, InventoryFeature.Action>
    ) -> some View {
        let bean = beanSummary.bean

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bean.roaster)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(tab == .active ? InventoryStyle.olive : InventoryStyle.muted)
                        .lineLimit(1)

                    Text(bean.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(tab == .active ? InventoryStyle.espresso : InventoryStyle.grayText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(tab == .active ? "현재까지 \(beanSummary.cupCount)잔" : "총 \(beanSummary.cupCount)잔")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(tab == .active ? InventoryStyle.caramel : InventoryStyle.muted)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 10) {
                    statusBadge(tab: tab, cupCount: beanSummary.cupCount)
                    actionMenu(beanSummary: beanSummary, tab: tab, viewStore: viewStore)
                }
            }

            if tab == .active {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("기록 \(beanSummary.cupCount)잔")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(InventoryStyle.espresso)

                        Spacer()

                        Text("/ \(Int(bean.totalWeight.rounded()))g")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(InventoryStyle.muted)
                    }

                    progressBar(fill: activeProgressFraction(beanSummary))
                }
            }

            HStack(spacing: 16) {
                metadataItem(systemName: "calendar", text: purchaseDateText(bean.purchaseDate))
                metadataItem(systemName: "tag", text: currencyText(bean.price))
            }
            .padding(.top, 1)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(InventoryStyle.pampas)
                    .frame(height: 1)
                    .offset(y: -12)
            }
        }
        .padding(21)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tab == .active ? .white : InventoryStyle.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(tab == .active ? InventoryStyle.pearl.opacity(0.8) : InventoryStyle.pearl.opacity(0.6), lineWidth: 1)
        }
        .shadow(color: tab == .active ? InventoryStyle.espresso.opacity(0.04) : .clear, radius: 12, x: 0, y: 8)
        .opacity(tab == .active ? 1 : 0.82)
    }

    private func statusBadge(tab: InventoryTab, cupCount: Int) -> some View {
        let title: String
        let foreground: Color
        let background: Color

        if tab == .active {
            title = cupCount == 0 ? "시작 전" : "신선함"
            foreground = InventoryStyle.moss
            background = InventoryStyle.sage
        } else {
            title = "다 마심"
            foreground = InventoryStyle.grayText
            background = InventoryStyle.pampas
        }

        return Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func actionMenu(
        beanSummary: InventoryBeanSummary,
        tab: InventoryTab,
        viewStore: ViewStore<InventoryFeature.State, InventoryFeature.Action>
    ) -> some View {
        Menu {
            if tab == .active {
                Button {
                    viewStore.send(.setBeanExhausted(beanSummary.id, true))
                } label: {
                    Label("다 마심 처리", systemImage: "checkmark.circle")
                }
            } else {
                Button {
                    viewStore.send(.setBeanExhausted(beanSummary.id, false))
                } label: {
                    Label("재고로 되돌리기", systemImage: "arrow.uturn.backward")
                }
            }

            Button(role: .destructive) {
                viewStore.send(.deleteBeanButtonTapped(beanSummary.id))
            } label: {
                Label("삭제", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(InventoryStyle.olive)
                .frame(width: 32, height: 32)
                .background(InventoryStyle.pampas, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func metadataItem(systemName: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.86)
        }
        .foregroundStyle(InventoryStyle.olive)
    }

    private func progressBar(fill: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(InventoryStyle.pampas)
                Capsule()
                    .fill(InventoryStyle.olive)
                    .frame(width: max(8, proxy.size.width * fill))
            }
        }
        .frame(height: 8)
    }

    private func addBeanCard(viewStore: ViewStore<InventoryFeature.State, InventoryFeature.Action>) -> some View {
        DisclosureGroup(isExpanded: $isAddFormExpanded) {
            VStack(spacing: 12) {
                formTextField(
                    placeholder: "원두 이름",
                    text: viewStore.binding(
                        get: \.beanName,
                        send: InventoryFeature.Action.beanNameChanged
                    )
                )

                formTextField(
                    placeholder: "로스터리",
                    text: viewStore.binding(
                        get: \.roaster,
                        send: InventoryFeature.Action.roasterChanged
                    )
                )

                formTextField(
                    placeholder: "총중량(g)",
                    text: viewStore.binding(
                        get: \.totalWeight,
                        send: InventoryFeature.Action.totalWeightChanged
                    )
                )
                .keyboardType(.decimalPad)

                formTextField(
                    placeholder: "가격(원)",
                    text: viewStore.binding(
                        get: \.price,
                        send: InventoryFeature.Action.priceChanged
                    )
                )
                .keyboardType(.numberPad)

                DatePicker(
                    "구매일",
                    selection: viewStore.binding(
                        get: \.purchaseDate,
                        send: InventoryFeature.Action.purchaseDateChanged
                    ),
                    displayedComponents: .date
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(InventoryStyle.espresso)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(InventoryStyle.pampas, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    viewStore.send(.saveBeanButtonTapped)
                    isAddFormExpanded = false
                    selectedTab = .active
                } label: {
                    Text("원두 저장")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(InventoryStyle.surface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(InventoryStyle.espresso, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSaveDisabled(viewStore))
                .opacity(isSaveDisabled(viewStore) ? 0.55 : 1)
            }
            .padding(.top, 16)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(InventoryStyle.surface)
                    .frame(width: 28, height: 28)
                    .background(InventoryStyle.espresso, in: Circle())

                Text("새 원두 등록")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(InventoryStyle.espresso)
            }
        }
        .tint(InventoryStyle.espresso)
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(InventoryStyle.pearl.opacity(0.75), lineWidth: 1)
        }
    }

    private func formTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(InventoryStyle.espresso)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(InventoryStyle.pampas, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func activeProgressFraction(_ beanSummary: InventoryBeanSummary) -> CGFloat {
        let bean = beanSummary.bean
        guard bean.totalWeight > 0 else { return 0.08 }

        let estimatedUsedWeight = Double(beanSummary.cupCount) * 18
        return CGFloat(min(max(estimatedUsedWeight / bean.totalWeight, 0.08), 1))
    }

    private func purchaseDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yy.MM.dd"
        return "\(formatter.string(from: date)) 구매"
    }

    private func currencyText(_ value: Int) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "KRW"))
    }

    private func isSaveDisabled(_ viewStore: ViewStore<InventoryFeature.State, InventoryFeature.Action>) -> Bool {
        viewStore.beanName.isEmpty
            || viewStore.roaster.isEmpty
            || Double(viewStore.totalWeight) == nil
            || Int(viewStore.price) == nil
    }
}

private enum InventoryTab {
    case active
    case exhausted
}

private enum InventoryStyle {
    static let espresso = Color(red: 0.212, green: 0.145, blue: 0.106)
    static let caramel = Color(red: 0.761, green: 0.498, blue: 0.361)
    static let pearl = Color(red: 0.91, green: 0.886, blue: 0.851)
    static let pampas = Color(red: 0.961, green: 0.949, blue: 0.933)
    static let surface = Color(red: 0.988, green: 0.98, blue: 0.973)
    static let background = Color(red: 0.988, green: 0.98, blue: 0.973)
    static let olive = Color(red: 0.451, green: 0.498, blue: 0.416)
    static let moss = Color(red: 0.333, green: 0.42, blue: 0.306)
    static let sage = Color(red: 0.941, green: 0.957, blue: 0.937)
    static let muted = Color(red: 0.6, green: 0.631, blue: 0.686)
    static let grayText = Color(red: 0.416, green: 0.447, blue: 0.51)
}
