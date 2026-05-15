import Foundation
import XCTest
@testable import CoffeeDomain

final class CoffeeCalculationsTests: XCTestCase {
    func testBeanCupCountCountsLogsForMatchingBeanOnly() {
        let now = Date(timeIntervalSince1970: 1_744_588_800)
        let beans = CoffeeFixtures.sampleBeans(now: now)
        let brewLogs = CoffeeFixtures.sampleBrewLogs(now: now)

        XCTAssertEqual(
            CoffeeCalculations.beanCupCount(for: beans[0].id, brewLogs: brewLogs),
            3
        )
    }

    func testMonthlyBeanPurchaseCostCountsOnlySelectedMonth() {
        let now = Date(timeIntervalSince1970: 1_744_588_800)
        let calendar = Calendar(identifier: .gregorian)
        let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: thisMonth) ?? thisMonth

        let beans = [
            Bean(name: "A", roaster: "R", totalWeight: 200, price: 12_000, purchaseDate: thisMonth, createdAt: thisMonth),
            Bean(name: "B", roaster: "R", totalWeight: 200, price: 8_000, purchaseDate: previousMonth, createdAt: previousMonth),
        ]

        XCTAssertEqual(
            CoffeeCalculations.monthlyBeanPurchaseCost(month: now, beans: beans, calendar: calendar),
            12_000
        )
    }

    func testMonthlyCupCountCountsOnlySelectedMonthLogs() {
        let now = Date(timeIntervalSince1970: 1_744_588_800)
        let calendar = Calendar(identifier: .gregorian)
        let brewLogs = CoffeeFixtures.sampleBrewLogs(now: now)

        XCTAssertEqual(
            CoffeeCalculations.monthlyCupCount(month: now, brewLogs: brewLogs, calendar: calendar),
            3
        )
    }

    func testBrewingDefaultsPreferMostRecentActiveBean() {
        let now = Date(timeIntervalSince1970: 1_744_588_800)
        let beans = CoffeeFixtures.sampleBeans(now: now).map { bean -> Bean in
            var copy = bean
            copy.isExhausted = false
            return copy
        }
        let brewLogs = CoffeeFixtures.sampleBrewLogs(now: now)

        let defaults = CoffeeCalculations.brewingDefaults(activeBeans: beans, brewLogs: brewLogs)

        XCTAssertEqual(defaults.selectedBeanID, brewLogs.sorted(by: { $0.date > $1.date }).first?.beanId)
        XCTAssertEqual(defaults.usedWeight, 21)
    }

    func testCurrentActiveBeanFallsBackToMostRecentActiveBeanWhenNoBrewsExist() {
        let now = Date(timeIntervalSince1970: 1_744_588_800)
        let beans = CoffeeFixtures.sampleBeans(now: now).filter { !$0.isExhausted }

        XCTAssertEqual(
            CoffeeCalculations.currentActiveBean(activeBeans: beans, brewLogs: []),
            beans.sorted(by: { $0.createdAt > $1.createdAt }).first
        )
    }
}
