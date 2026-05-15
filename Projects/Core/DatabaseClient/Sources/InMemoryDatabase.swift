import CoffeeDomain
import Foundation

public actor InMemoryDatabase {
    public enum Seed: Sendable {
        case empty
        case preview
    }

    private var beans: [Bean]
    private var brewLogs: [BrewLog]
    private var hasCompletedOnboarding: Bool
    private let calendar = Calendar(identifier: .gregorian)

    public init(seed: Seed) {
        switch seed {
        case .empty:
            self.beans = []
            self.brewLogs = []
            self.hasCompletedOnboarding = false
        case .preview:
            self.beans = CoffeeFixtures.sampleBeans()
            self.brewLogs = CoffeeFixtures.sampleBrewLogs()
            self.hasCompletedOnboarding = true
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

    public func fetchBrewingDefaults() -> BrewDefaults {
        CoffeeCalculations.brewingDefaults(
            activeBeans: beans.filter { !$0.isExhausted },
            brewLogs: brewLogs
        )
    }

    public func fetchInventory() -> InventorySnapshot {
        InventorySnapshot(
            activeBeans: inventorySummaries(for: beans.filter { !$0.isExhausted }),
            exhaustedBeans: inventorySummaries(for: beans.filter(\.isExhausted))
        )
    }

    public func fetchHasCompletedOnboarding() -> Bool {
        hasCompletedOnboarding
    }

    public func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    public func saveBean(_ bean: Bean) {
        beans.insert(bean, at: 0)
    }

    public func addBrewLog(_ brewLog: BrewLog) -> BrewSaveResult {
        brewLogs.insert(brewLog, at: 0)

        let beanName = beans.first(where: { $0.id == brewLog.beanId })?.name ?? "이 원두"
        let cupCount = CoffeeCalculations.beanCupCount(for: brewLog.beanId, brewLogs: brewLogs)

        return BrewSaveResult(beanName: beanName, cupCount: cupCount)
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
        CoffeeCalculations.currentActiveBean(
            activeBeans: beans.filter { !$0.isExhausted },
            brewLogs: brewLogs
        )
    }

    private func inventorySummaries(for beans: [Bean]) -> [InventoryBeanSummary] {
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
