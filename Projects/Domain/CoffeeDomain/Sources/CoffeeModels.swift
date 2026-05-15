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

public struct BeanConsumptionSummary: Equatable, Sendable {
    public let beanID: UUID
    public let beanName: String
    public let cupCount: Int

    public init(beanID: UUID, beanName: String, cupCount: Int) {
        self.beanID = beanID
        self.beanName = beanName
        self.cupCount = cupCount
    }
}

public struct DashboardChartEntry: Equatable, Identifiable, Sendable {
    public let id: Date
    public let month: Date
    public let cupCount: Int

    public init(month: Date, cupCount: Int) {
        self.id = month
        self.month = month
        self.cupCount = cupCount
    }
}

public struct DashboardSnapshot: Equatable, Sendable {
    public let month: Date
    public let monthLabel: String
    public let monthlyCupCount: Int
    public let monthlyBeanUsage: Double
    public let monthlyPurchaseCost: Int
    public let currentBeanSummary: BeanConsumptionSummary?
    public let currentBeanStatus: CurrentBeanStatus?
    public let chartEntries: [DashboardChartEntry]

    public init(
        month: Date,
        monthLabel: String,
        monthlyCupCount: Int,
        monthlyBeanUsage: Double,
        monthlyPurchaseCost: Int,
        currentBeanSummary: BeanConsumptionSummary?,
        currentBeanStatus: CurrentBeanStatus?,
        chartEntries: [DashboardChartEntry]
    ) {
        self.month = month
        self.monthLabel = monthLabel
        self.monthlyCupCount = monthlyCupCount
        self.monthlyBeanUsage = monthlyBeanUsage
        self.monthlyPurchaseCost = monthlyPurchaseCost
        self.currentBeanSummary = currentBeanSummary
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

public struct InventoryBeanSummary: Equatable, Identifiable, Sendable {
    public let bean: Bean
    public let cupCount: Int

    public var id: UUID { bean.id }

    public init(bean: Bean, cupCount: Int) {
        self.bean = bean
        self.cupCount = cupCount
    }
}

public struct InventorySnapshot: Equatable, Sendable {
    public let activeBeans: [InventoryBeanSummary]
    public let exhaustedBeans: [InventoryBeanSummary]

    public init(activeBeans: [InventoryBeanSummary], exhaustedBeans: [InventoryBeanSummary]) {
        self.activeBeans = activeBeans
        self.exhaustedBeans = exhaustedBeans
    }
}

public struct BrewSaveResult: Equatable, Sendable {
    public let beanName: String
    public let cupCount: Int

    public init(beanName: String, cupCount: Int) {
        self.beanName = beanName
        self.cupCount = cupCount
    }
}
