import Foundation

public enum CoffeeFixtures {
    public static func sampleBeans(now: Date = .now) -> [Bean] {
        let calendar = Calendar(identifier: .gregorian)
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth

        return [
            Bean(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE1") ?? UUID(),
                name: "에티오피아 예가체프",
                roaster: "프리뷰 로스터스",
                totalWeight: 500,
                price: 28_000,
                purchaseDate: currentMonth,
                createdAt: currentMonth
            ),
            Bean(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE2") ?? UUID(),
                name: "콜롬비아 수프리모",
                roaster: "포트폴리오 커피",
                totalWeight: 300,
                price: 18_000,
                purchaseDate: previousMonth,
                isExhausted: true,
                createdAt: previousMonth
            ),
        ]
    }

    public static func sampleBrewLogs(now: Date = .now) -> [BrewLog] {
        let calendar = Calendar(identifier: .gregorian)
        let beans = sampleBeans(now: now)
        let firstBean = beans[0]
        let secondBean = beans[1]

        return [
            BrewLog(
                id: UUID(uuidString: "BBBBBBBB-BBBB-CCCC-DDDD-EEEEEEEEEEE1") ?? UUID(),
                beanId: secondBean.id,
                usedWeight: 18,
                date: calendar.date(byAdding: .day, value: -20, to: now) ?? now
            ),
            BrewLog(
                id: UUID(uuidString: "BBBBBBBB-BBBB-CCCC-DDDD-EEEEEEEEEEE2") ?? UUID(),
                beanId: firstBean.id,
                usedWeight: 20,
                date: calendar.date(byAdding: .day, value: -4, to: now) ?? now
            ),
            BrewLog(
                id: UUID(uuidString: "BBBBBBBB-BBBB-CCCC-DDDD-EEEEEEEEEEE3") ?? UUID(),
                beanId: firstBean.id,
                usedWeight: 20,
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now
            ),
            BrewLog(
                id: UUID(uuidString: "BBBBBBBB-BBBB-CCCC-DDDD-EEEEEEEEEEE4") ?? UUID(),
                beanId: firstBean.id,
                usedWeight: 21,
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
        ]
    }

    public static func sampleDashboardSnapshot(
        month: Date = .now,
        calendar: Calendar = .current
    ) -> DashboardSnapshot {
        let beans = sampleBeans(now: month)
        let brewLogs = sampleBrewLogs(now: month)
        let currentBean = CoffeeCalculations.currentActiveBean(
            activeBeans: beans.filter { !$0.isExhausted },
            brewLogs: brewLogs
        )
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"

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
}
