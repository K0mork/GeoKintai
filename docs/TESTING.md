# Testing Strategy

This document outlines the testing strategy for the GeoKintai project.

## 1. Unit Testing (TDD)
- **Scope**: ViewModels, Repositories, UseCases, Services.
- **Tools**: XCTest, Dependency Injection.
- **Workflow**: See [Development Rules (TDD)](development_rules.md).
- **Goal**: 100% logic coverage.

## 2. Integration & Simulation Testing
- **Scope**: Location Service, Background Task verification.
- **Tools**: Xcode Simulator, GPX Files.
- **Workflow**: See [Simulator Test Plan](test_plan.md).
- **Goal**: Verify OS-level integrations (Core Location, Background Modes).

## 3. UI Testing
- **Scope**: Critical user flows (optional in Phase 1).
- **Tools**: XCUITest.
