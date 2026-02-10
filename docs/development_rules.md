# Development Rules (TDD Guidelines)

This project strictly follows Test-Driven Development (TDD).

## Core Principle: Red-Green-Refactor

1.  **Red**: Write a failing test for the desired functionality.
    -   Do not write any production code until a test exists and fails.
    -   Verify that the test fails for the expected reason.
2.  **Green**: Write the minimum amount of code to pass the test.
    -   Do not worry about code quality or optimization at this stage.
    -   Focus solely on satisfying the test requirements.
3.  **Refactor**: Improve the code without changing its behavior.
    -   Remove duplication.
    -   Improve readability and naming.
    -   Ensure all tests still pass.

## Rules

-   **Test Location**: All logical components (ViewModels, UseCases, Repositories, Services) must have unit tests.
-   **No Untested Logic**: Logic inside Views should be minimized. Move logic to ViewModels or other testable components.
-   **Traceability Required**: Every new test/feature must be mapped in `requirements_traceability.md`.
-   **Commit Policy**:
    -   All tests must pass before committing changes.
    -   Commit after each Red-Green-Refactor cycle when tests are green.
    -   Keep commits small and cohesive (one logical change).
    -   Include tests and production code in the same commit.
    -   Separate refactors from feature changes when possible.
    -   Commit before switching tasks or pausing work.
-   **Git Sync Frequency (Best Practice)**:
    -   Commit at least once per completed Red-Green-Refactor cycle.
    -   If a cycle is long, commit at least every 30-60 minutes while keeping commits coherent.
    -   Push at least every 1-2 hours, and always push before ending the work session.
    -   Push immediately after major milestone completion (e.g. phase/task completion).

## Related Documents
- `tdd_guide.md`: concrete test naming/mocking/DoD guidance.
- `acceptance_criteria.md`: implementation gate and Given/When/Then criteria.
- `requirements_traceability.md`: requirement-to-test mapping.
