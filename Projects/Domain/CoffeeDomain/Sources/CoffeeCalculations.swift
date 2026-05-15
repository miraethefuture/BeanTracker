import Foundation

public enum CoffeeCalculations {
    public static func beanCupCount(
        for beanID: UUID,
        brewLogs: [BrewLog]
    ) -> Int {
        brewLogs.filter { $0.beanId == beanID }.count
    }

    public static func monthlyCupCount(
        month: Date,
        brewLogs: [BrewLog],
        calendar: Calendar = .current
    ) -> Int {
        brewLogs.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }.count
    }

    public static func monthlyBeanUsage(
        month: Date,
        brewLogs: [BrewLog],
        calendar: Calendar = .current
    ) -> Double {
        brewLogs
            .filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.usedWeight }
    }

    public static func monthlyBeanPurchaseCost(
        month: Date,
        beans: [Bean],
        calendar: Calendar = .current
    ) -> Int {
        beans
            .filter { calendar.isDate($0.purchaseDate, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.price }
    }

    public static func remainingWeight(bean: Bean, brewLogs: [BrewLog]) -> Double {
        let usedWeight = brewLogs
            .filter { $0.beanId == bean.id }
            .reduce(0) { $0 + $1.usedWeight }

        return max(bean.totalWeight - usedWeight, 0)
    }

    public static func lastUsedWeight(
        for beanID: UUID,
        brewLogs: [BrewLog]
    ) -> Double? {
        brewLogs
            .filter { $0.beanId == beanID }
            .sorted(by: { $0.date > $1.date })
            .first?
            .usedWeight
    }

    public static func currentBeanStatus(
        for bean: Bean?,
        brewLogs: [BrewLog]
    ) -> CurrentBeanStatus? {
        guard let bean else { return nil }

        let remainingWeight = remainingWeight(bean: bean, brewLogs: brewLogs)
        let lastWeight = lastUsedWeight(for: bean.id, brewLogs: brewLogs) ?? 20
        let expectedCups = lastWeight > 0 ? remainingWeight / lastWeight : nil
        let isExhaustionWarning = remainingWeight <= 0

        return CurrentBeanStatus(
            beanName: bean.name,
            remainingWeight: remainingWeight,
            expectedRemainingCups: expectedCups,
            isExhaustionWarning: isExhaustionWarning
        )
    }

    public static func currentActiveBean(
        activeBeans: [Bean],
        brewLogs: [BrewLog]
    ) -> Bean? {
        let recentBeanID = brewLogs
            .sorted(by: { $0.date > $1.date })
            .first(where: { log in activeBeans.contains(where: { $0.id == log.beanId }) })?
            .beanId

        if let recentBeanID {
            return activeBeans.first(where: { $0.id == recentBeanID })
        }

        return activeBeans.sorted(by: { $0.createdAt > $1.createdAt }).first
    }

    public static func beanConsumptionSummary(
        for bean: Bean?,
        brewLogs: [BrewLog]
    ) -> BeanConsumptionSummary? {
        guard let bean else { return nil }

        return BeanConsumptionSummary(
            beanID: bean.id,
            beanName: bean.name,
            cupCount: beanCupCount(for: bean.id, brewLogs: brewLogs)
        )
    }

    public static func chartEntries(
        endingAt month: Date,
        monthCount: Int,
        brewLogs: [BrewLog],
        calendar: Calendar = .current
    ) -> [DashboardChartEntry] {
        guard monthCount > 0 else { return [] }

        return (0..<monthCount).reversed().compactMap { offset in
            guard let chartMonth = calendar.date(byAdding: .month, value: -offset, to: month) else {
                return nil
            }

            return DashboardChartEntry(
                month: chartMonth,
                cupCount: monthlyCupCount(
                    month: chartMonth,
                    brewLogs: brewLogs,
                    calendar: calendar
                )
            )
        }
    }

    public static func brewingDefaults(
        activeBeans: [Bean],
        brewLogs: [BrewLog]
    ) -> BrewDefaults {
        let sortedActiveBeans = activeBeans.sorted(by: { $0.createdAt > $1.createdAt })

        let selectedBeanID = brewLogs
            .sorted(by: { $0.date > $1.date })
            .first(where: { log in sortedActiveBeans.contains(where: { $0.id == log.beanId }) })?
            .beanId
            ?? sortedActiveBeans.first?.id

        let usedWeight = brewLogs
            .sorted(by: { $0.date > $1.date })
            .first?
            .usedWeight
            ?? 20

        return BrewDefaults(
            activeBeans: sortedActiveBeans,
            selectedBeanID: selectedBeanID,
            usedWeight: usedWeight
        )
    }
}
