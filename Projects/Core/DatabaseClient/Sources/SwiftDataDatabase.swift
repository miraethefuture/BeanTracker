import CoffeeDomain
import Foundation
import SwiftData

@Model
final class PersistedBean {
    @Attribute(.unique) var id: UUID
    var name: String
    var roaster: String
    var totalWeight: Double
    var price: Int
    var purchaseDate: Date
    var isExhausted: Bool
    var createdAt: Date

    init(bean: Bean) {
        self.id = bean.id
        self.name = bean.name
        self.roaster = bean.roaster
        self.totalWeight = bean.totalWeight
        self.price = bean.price
        self.purchaseDate = bean.purchaseDate
        self.isExhausted = bean.isExhausted
        self.createdAt = bean.createdAt
    }

    var domainValue: Bean {
        Bean(
            id: id,
            name: name,
            roaster: roaster,
            totalWeight: totalWeight,
            price: price,
            purchaseDate: purchaseDate,
            isExhausted: isExhausted,
            createdAt: createdAt
        )
    }
}

@Model
final class PersistedBrewLog {
    @Attribute(.unique) var id: UUID
    var beanId: UUID
    var usedWeight: Double
    var date: Date
    var createdAt: Date

    init(brewLog: BrewLog) {
        self.id = brewLog.id
        self.beanId = brewLog.beanId
        self.usedWeight = brewLog.usedWeight
        self.date = brewLog.date
        self.createdAt = brewLog.createdAt
    }

    var domainValue: BrewLog {
        BrewLog(
            id: id,
            beanId: beanId,
            usedWeight: usedWeight,
            date: date,
            createdAt: createdAt
        )
    }
}

@Model
final class PersistedAppState {
    @Attribute(.unique) var key: String
    var hasCompletedOnboarding: Bool

    init(key: String = SwiftDataDatabase.appStateKey, hasCompletedOnboarding: Bool) {
        self.key = key
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

public actor SwiftDataDatabase {
    fileprivate static let appStateKey = "default"

    private let context: ModelContext
    private let calendar = Calendar(identifier: .gregorian)

    public init(isStoredInMemoryOnly: Bool = false) throws {
        let schema = Schema([
            PersistedBean.self,
            PersistedBrewLog.self,
            PersistedAppState.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        self.context = ModelContext(container)
        self.context.autosaveEnabled = true
    }

    public func fetchDashboard(month: Date) throws -> DashboardSnapshot {
        let beans = try fetchBeans()
        let brewLogs = try fetchBrewLogs()
        let currentBean = CoffeeCalculations.currentActiveBean(
            activeBeans: beans.filter { !$0.isExhausted },
            brewLogs: brewLogs
        )
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy.MM"

        return DashboardSnapshot(
            month: month,
            monthLabel: formatter.string(from: month),
            monthlyCupCount: CoffeeCalculations.monthlyCupCount(
                month: month,
                brewLogs: brewLogs,
                calendar: calendar
            ),
            monthlyBeanUsage: CoffeeCalculations.monthlyBeanUsage(
                month: month,
                brewLogs: brewLogs,
                calendar: calendar
            ),
            monthlyPurchaseCost: CoffeeCalculations.monthlyBeanPurchaseCost(
                month: month,
                beans: beans,
                calendar: calendar
            ),
            currentBeanSummary: CoffeeCalculations.beanConsumptionSummary(
                for: currentBean,
                brewLogs: brewLogs
            ),
            currentBeanStatus: CoffeeCalculations.currentBeanStatus(
                for: currentBean,
                brewLogs: brewLogs
            ),
            chartEntries: CoffeeCalculations.chartEntries(
                endingAt: month,
                monthCount: 6,
                brewLogs: brewLogs,
                calendar: calendar
            )
        )
    }

    public func fetchBrewingDefaults() throws -> BrewDefaults {
        try CoffeeCalculations.brewingDefaults(
            activeBeans: fetchBeans().filter { !$0.isExhausted },
            brewLogs: fetchBrewLogs()
        )
    }

    public func fetchInventory() throws -> InventorySnapshot {
        let beans = try fetchBeans()
        let brewLogs = try fetchBrewLogs()

        return InventorySnapshot(
            activeBeans: inventorySummaries(for: beans.filter { !$0.isExhausted }, brewLogs: brewLogs),
            exhaustedBeans: inventorySummaries(for: beans.filter(\.isExhausted), brewLogs: brewLogs)
        )
    }

    public func fetchHasCompletedOnboarding() throws -> Bool {
        try fetchAppState()?.hasCompletedOnboarding ?? false
    }

    public func completeOnboarding() throws {
        if let appState = try fetchAppState() {
            appState.hasCompletedOnboarding = true
        } else {
            context.insert(PersistedAppState(hasCompletedOnboarding: true))
        }

        try context.save()
    }

    public func saveBean(_ bean: Bean) throws {
        context.insert(PersistedBean(bean: bean))
        try context.save()
    }

    public func addBrewLog(_ brewLog: BrewLog) throws -> BrewSaveResult {
        context.insert(PersistedBrewLog(brewLog: brewLog))
        try context.save()

        let beans = try fetchBeans()
        let brewLogs = try fetchBrewLogs()
        let beanName = beans.first(where: { $0.id == brewLog.beanId })?.name ?? "이 원두"
        let cupCount = CoffeeCalculations.beanCupCount(for: brewLog.beanId, brewLogs: brewLogs)

        return BrewSaveResult(beanName: beanName, cupCount: cupCount)
    }

    public func deleteBean(id: UUID) throws {
        let persistedBeans = try context.fetch(FetchDescriptor<PersistedBean>())
        persistedBeans
            .filter { $0.id == id }
            .forEach(context.delete)

        let persistedBrewLogs = try context.fetch(FetchDescriptor<PersistedBrewLog>())
        persistedBrewLogs
            .filter { $0.beanId == id }
            .forEach(context.delete)

        try context.save()
    }

    public func deleteBrewLog(id: UUID) throws {
        let persistedBrewLogs = try context.fetch(FetchDescriptor<PersistedBrewLog>())
        persistedBrewLogs
            .filter { $0.id == id }
            .forEach(context.delete)

        try context.save()
    }

    public func setBeanExhausted(id: UUID, isExhausted: Bool) throws {
        let persistedBeans = try context.fetch(FetchDescriptor<PersistedBean>())
        persistedBeans
            .first(where: { $0.id == id })?
            .isExhausted = isExhausted

        try context.save()
    }

    private func fetchBeans() throws -> [Bean] {
        try context.fetch(
            FetchDescriptor<PersistedBean>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        )
        .map(\.domainValue)
    }

    private func fetchBrewLogs() throws -> [BrewLog] {
        try context.fetch(
            FetchDescriptor<PersistedBrewLog>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        )
        .map(\.domainValue)
    }

    private func fetchAppState() throws -> PersistedAppState? {
        try context.fetch(FetchDescriptor<PersistedAppState>())
            .first { $0.key == Self.appStateKey }
    }

    private func inventorySummaries(
        for beans: [Bean],
        brewLogs: [BrewLog]
    ) -> [InventoryBeanSummary] {
        beans
            .sorted(by: { $0.createdAt > $1.createdAt })
            .map { bean in
                InventoryBeanSummary(
                    bean: bean,
                    cupCount: CoffeeCalculations.beanCupCount(for: bean.id, brewLogs: brewLogs)
                )
            }
    }
}

