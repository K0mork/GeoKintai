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
-   **Commit Policy**: All tests must pass before committing changes.
