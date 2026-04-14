import CoffeeDomain
import Foundation

public actor InMemoryDatabase {
    public enum Seed: Sendable {
        case empty
        case preview
    }

    private var beans: [Bean]
    private var brewLogs: [BrewLog]
    private var userPreference: UserPreference?
    private let calendar = Calendar(identifier: .gregorian)

    public init(seed: Seed) {
        switch seed {
        case .empty:
            self.beans = []
            self.brewLogs = []
            self.userPreference = nil
        case .preview:
            self.beans = CoffeeFixtures.sampleBeans()
            self.brewLogs = CoffeeFixtures.sampleBrewLogs()
            self.userPreference = CoffeeFixtures.samplePreference()
        }
    }

    public func fetchDashboard(month: Date) -> DashboardSnapshot {
        let currentBean = currentBean()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy.MM"

        return DashboardSnapshot(
            month: month,
            monthLabel: formatter.string(from: month),
            monthlySavings: CoffeeCalculations.monthlySavings(
                month: month,
                brewLogs: brewLogs,
                beans: beans,
                standardCafePrice: userPreference?.standardCafePrice ?? 4_500,
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
            currentBeanStatus: CoffeeCalculations.currentBeanStatus(
                for: currentBean,
                brewLogs: brewLogs
            ),
            chartEntries: CoffeeCalculations.chartEntries(
                endingAt: month,
                monthCount: 6,
                brewLogs: brewLogs,
                beans: beans,
                standardCafePrice: userPreference?.standardCafePrice ?? 4_500,
                calendar: calendar
            )
        )
    }

    public func fetchBrewingDefaults() -> BrewDefaults {
        CoffeeCalculations.brewingDefaults(
            activeBeans: beans.filter { !$0.isExhausted },
            brewLogs: brewLogs
        )
    }

    public func fetchInventory() -> InventorySnapshot {
        InventorySnapshot(
            activeBeans: beans.filter { !$0.isExhausted }.sorted(by: { $0.createdAt > $1.createdAt }),
            exhaustedBeans: beans.filter(\.isExhausted).sorted(by: { $0.createdAt > $1.createdAt })
        )
    }

    public func fetchUserPreference() -> UserPreference? {
        userPreference
    }

    public func saveUserPreference(standardCafePrice: Int) {
        if var userPreference {
            userPreference.standardCafePrice = standardCafePrice
            userPreference.updatedAt = .now
            self.userPreference = userPreference
        } else {
            userPreference = UserPreference(standardCafePrice: standardCafePrice)
        }
    }

    public func saveBean(_ bean: Bean) {
        beans.insert(bean, at: 0)
    }

    public func addBrewLog(_ brewLog: BrewLog) {
        brewLogs.insert(brewLog, at: 0)
    }

    public func deleteBean(id: UUID) {
        beans.removeAll { $0.id == id }
        brewLogs.removeAll { $0.beanId == id }
    }

    public func deleteBrewLog(id: UUID) {
        brewLogs.removeAll { $0.id == id }
    }

    public func setBeanExhausted(id: UUID, isExhausted: Bool) {
        guard let index = beans.firstIndex(where: { $0.id == id }) else { return }
        beans[index].isExhausted = isExhausted
    }

    private func currentBean() -> Bean? {
        let activeBeans = beans.filter { !$0.isExhausted }
        let recentBeanID = brewLogs
            .sorted(by: { $0.date > $1.date })
            .first(where: { log in activeBeans.contains(where: { $0.id == log.beanId }) })?
            .beanId

        if let recentBeanID {
            return activeBeans.first(where: { $0.id == recentBeanID })
        }

        return activeBeans.sorted(by: { $0.createdAt > $1.createdAt }).first
    }
}
