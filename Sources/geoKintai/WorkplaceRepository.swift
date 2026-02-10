import Foundation

public final class WorkplaceRepository {
    private var workplaces: [Workplace]

    public init(initialWorkplaces: [Workplace] = []) {
        self.workplaces = initialWorkplaces
    }

    public func save(_ workplace: Workplace) {
        if let index = workplaces.firstIndex(where: { $0.id == workplace.id }) {
            workplaces[index] = workplace
            return
        }

        workplaces.append(workplace)
    }

    public func fetchAll() -> [Workplace] {
        workplaces
    }

    public func fetchBy(id: UUID) -> Workplace? {
        workplaces.first(where: { $0.id == id })
    }

    public func delete(id: UUID) {
        workplaces.removeAll(where: { $0.id == id })
    }
}
