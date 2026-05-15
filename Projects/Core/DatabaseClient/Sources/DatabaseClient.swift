import CoffeeDomain
import ComposableArchitecture
import Foundation

public struct DatabaseClient: Sendable {
    public var fetchDashboard: @Sendable (_ month: Date) async throws -> DashboardSnapshot
    public var fetchBrewingDefaults: @Sendable () async throws -> BrewDefaults
    public var fetchInventory: @Sendable () async throws -> InventorySnapshot
    public var fetchHasCompletedOnboarding: @Sendable () async throws -> Bool
    public var completeOnboarding: @Sendable () async throws -> Void
    public var saveBean: @Sendable (_ bean: Bean) async throws -> Void
    public var addBrewLog: @Sendable (_ brewLog: BrewLog) async throws -> BrewSaveResult
    public var deleteBean: @Sendable (_ beanID: UUID) async throws -> Void
    public var deleteBrewLog: @Sendable (_ brewLogID: UUID) async throws -> Void
    public var setBeanExhausted: @Sendable (_ beanID: UUID, _ isExhausted: Bool) async throws -> Void

    public init(
        fetchDashboard: @escaping @Sendable (_ month: Date) async throws -> DashboardSnapshot,
        fetchBrewingDefaults: @escaping @Sendable () async throws -> BrewDefaults,
        fetchInventory: @escaping @Sendable () async throws -> InventorySnapshot,
        fetchHasCompletedOnboarding: @escaping @Sendable () async throws -> Bool,
        completeOnboarding: @escaping @Sendable () async throws -> Void,
        saveBean: @escaping @Sendable (_ bean: Bean) async throws -> Void,
        addBrewLog: @escaping @Sendable (_ brewLog: BrewLog) async throws -> BrewSaveResult,
        deleteBean: @escaping @Sendable (_ beanID: UUID) async throws -> Void,
        deleteBrewLog: @escaping @Sendable (_ brewLogID: UUID) async throws -> Void,
        setBeanExhausted: @escaping @Sendable (_ beanID: UUID, _ isExhausted: Bool) async throws -> Void
    ) {
        self.fetchDashboard = fetchDashboard
        self.fetchBrewingDefaults = fetchBrewingDefaults
        self.fetchInventory = fetchInventory
        self.fetchHasCompletedOnboarding = fetchHasCompletedOnboarding
        self.completeOnboarding = completeOnboarding
        self.saveBean = saveBean
        self.addBrewLog = addBrewLog
        self.deleteBean = deleteBean
        self.deleteBrewLog = deleteBrewLog
        self.setBeanExhausted = setBeanExhausted
    }
}

extension DatabaseClient: DependencyKey {
    public static var liveValue: DatabaseClient {
        .inMemory()
    }

    public static var previewValue: DatabaseClient {
        .inMemory()
    }

    public static let testValue = DatabaseClient(
        fetchDashboard: { _ in CoffeeFixtures.sampleDashboardSnapshot() },
        fetchBrewingDefaults: {
            CoffeeCalculations.brewingDefaults(
                activeBeans: CoffeeFixtures.sampleBeans().filter { !$0.isExhausted },
                brewLogs: CoffeeFixtures.sampleBrewLogs()
            )
        },
        fetchInventory: {
            let beans = CoffeeFixtures.sampleBeans()
            return InventorySnapshot(
                activeBeans: beans.filter { !$0.isExhausted }.map {
                    InventoryBeanSummary(
                        bean: $0,
                        cupCount: CoffeeCalculations.beanCupCount(for: $0.id, brewLogs: CoffeeFixtures.sampleBrewLogs())
                    )
                },
                exhaustedBeans: beans.filter(\.isExhausted).map {
                    InventoryBeanSummary(
                        bean: $0,
                        cupCount: CoffeeCalculations.beanCupCount(for: $0.id, brewLogs: CoffeeFixtures.sampleBrewLogs())
                    )
                }
            )
        },
        fetchHasCompletedOnboarding: { true },
        completeOnboarding: { },
        saveBean: { _ in },
        addBrewLog: { _ in
            BrewSaveResult(beanName: "에티오피아 예가체프", cupCount: 4)
        },
        deleteBean: { _ in },
        deleteBrewLog: { _ in },
        setBeanExhausted: { _, _ in }
    )
}

public extension DependencyValues {
    var databaseClient: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}

public extension DatabaseClient {
    static func inMemory(
        seed: InMemoryDatabase.Seed = .preview
    ) -> DatabaseClient {
        let database = InMemoryDatabase(seed: seed)

        return DatabaseClient(
            fetchDashboard: { month in
                await database.fetchDashboard(month: month)
            },
            fetchBrewingDefaults: {
                await database.fetchBrewingDefaults()
            },
            fetchInventory: {
                await database.fetchInventory()
            },
            fetchHasCompletedOnboarding: {
                await database.fetchHasCompletedOnboarding()
            },
            completeOnboarding: {
                await database.completeOnboarding()
            },
            saveBean: { bean in
                await database.saveBean(bean)
            },
            addBrewLog: { brewLog in
                await database.addBrewLog(brewLog)
            },
            deleteBean: { beanID in
                await database.deleteBean(id: beanID)
            },
            deleteBrewLog: { brewLogID in
                await database.deleteBrewLog(id: brewLogID)
            },
            setBeanExhausted: { beanID, isExhausted in
                await database.setBeanExhausted(id: beanID, isExhausted: isExhausted)
            }
        )
    }
}
