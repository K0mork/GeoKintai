import Foundation

public final class WorkplaceRepository {
    private var workplaces: [Workplace]
    public var onChange: (([Workplace]) -> Void)?

    public init(
        initialWorkplaces: [Workplace] = [],
        onChange: (([Workplace]) -> Void)? = nil
    ) {
        self.workplaces = initialWorkplaces
        self.onChange = onChange
    }

    public func save(_ workplace: Workplace) {
        if let index = workplaces.firstIndex(where: { $0.id == workplace.id }) {
            workplaces[index] = workplace
            onChange?(workplaces)
            return
        }

        workplaces.append(workplace)
        onChange?(workplaces)
    }

    public func fetchAll() -> [Workplace] {
        workplaces
    }

    public func fetchBy(id: UUID) -> Workplace? {
        workplaces.first(where: { $0.id == id })
    }

    public func delete(id: UUID) {
        workplaces.removeAll(where: { $0.id == id })
        onChange?(workplaces)
    }
}
