import Foundation

public struct Bean: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let roaster: String
    public let totalWeight: Double
    public let price: Int
    public let purchaseDate: Date
    public var isExhausted: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        roaster: String,
        totalWeight: Double,
        price: Int,
        purchaseDate: Date,
        isExhausted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.roaster = roaster
        self.totalWeight = totalWeight
        self.price = price
        self.purchaseDate = purchaseDate
        self.isExhausted = isExhausted
        self.createdAt = createdAt
    }
}

public struct BrewLog: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let beanId: UUID
    public let usedWeight: Double
    public let date: Date
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        beanId: UUID,
        usedWeight: Double,
        date: Date,
        createdAt: Date = .now
    ) {
        self.id = id
        self.beanId = beanId
        self.usedWeight = usedWeight
        self.date = date
        self.createdAt = createdAt
    }
}

public struct UserPreference: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var standardCafePrice: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        standardCafePrice: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.standardCafePrice = standardCafePrice
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CurrentBeanStatus: Equatable, Sendable {
    public let beanName: String
    public let remainingWeight: Double
    public let expectedRemainingCups: Double?
    public let isExhaustionWarning: Bool

    public init(
        beanName: String,
        remainingWeight: Double,
        expectedRemainingCups: Double?,
        isExhaustionWarning: Bool
    ) {
        self.beanName = beanName
        self.remainingWeight = remainingWeight
        self.expectedRemainingCups = expectedRemainingCups
        self.isExhaustionWarning = isExhaustionWarning
    }
}

public struct DashboardChartEntry: Equatable, Identifiable, Sendable {
    public let id: Date
    public let month: Date
    public let savings: Int

    public init(month: Date, savings: Int) {
        self.id = month
        self.month = month
        self.savings = savings
    }
}

public struct DashboardSnapshot: Equatable, Sendable {
    public let month: Date
    public let monthLabel: String
    public let monthlySavings: Int
    public let monthlyBeanUsage: Double
    public let monthlyPurchaseCost: Int
    public let currentBeanStatus: CurrentBeanStatus?
    public let chartEntries: [DashboardChartEntry]

    public init(
        month: Date,
        monthLabel: String,
        monthlySavings: Int,
        monthlyBeanUsage: Double,
        monthlyPurchaseCost: Int,
        currentBeanStatus: CurrentBeanStatus?,
        chartEntries: [DashboardChartEntry]
    ) {
        self.month = month
        self.monthLabel = monthLabel
        self.monthlySavings = monthlySavings
        self.monthlyBeanUsage = monthlyBeanUsage
        self.monthlyPurchaseCost = monthlyPurchaseCost
        self.currentBeanStatus = currentBeanStatus
        self.chartEntries = chartEntries
    }
}

public struct BrewDefaults: Equatable, Sendable {
    public let activeBeans: [Bean]
    public let selectedBeanID: UUID?
    public let usedWeight: Double

    public init(activeBeans: [Bean], selectedBeanID: UUID?, usedWeight: Double) {
        self.activeBeans = activeBeans
        self.selectedBeanID = selectedBeanID
        self.usedWeight = usedWeight
    }
}

public struct InventorySnapshot: Equatable, Sendable {
    public let activeBeans: [Bean]
    public let exhaustedBeans: [Bean]

    public init(activeBeans: [Bean], exhaustedBeans: [Bean]) {
        self.activeBeans = activeBeans
        self.exhaustedBeans = exhaustedBeans
    }
}
