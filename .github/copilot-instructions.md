# Copilot Instructions (GeoKintai)

## Build, test, lint
- Build/test are expected via Xcode (no CLI scripts found yet). Use Xcode Test targets (XCTest/XCUITest) once the project is created.
- Simulator validation uses GPX files (see `docs/test_plan.md`); run from Xcode: Debug > Simulate Location.

## High-level architecture
- iOS app that auto-records workplace attendance in the background using Core Location region monitoring and a verification window (enter/exit events trigger a short high-accuracy tracking window before confirming stay/exit).
- Persistence is Core Data (or SwiftData) with relational entities: Workplace, AttendanceRecord, LocationProof.
- Workflow: OS region event → app wakes → background task begins → collect GPS samples → confirm stay/exit → persist attendance + proofs → stop updates.

## Key conventions
- Strict TDD: Red → Green → Refactor; all logic must have tests before production code (`docs/development_rules.md`).
- Keep logic out of SwiftUI views; place it in ViewModels/UseCases/Repositories/Services for unit testing.
- UI must follow native iOS look & feel: SwiftUI `List` + `.insetGrouped`, system fonts, semantic colors; avoid custom sizing/modifiers (`docs/specification.md`).
- Use GPX-driven simulator tests and keep `SimulatedLocations/` GPX files under version control (`docs/test_plan.md`).

## Tooling / Documentation
- For any library or API reference used in implementation or tests, always verify details via Context7 MCP.
- Assumptions without documentation verification are not allowed.