# Phase 2: UI Implementation (Native Look & Feel)

## 2.1 Dashboard (Status Tab)
- [ ] **ViewModel Setup**
    - Observe `AttendanceRepository`
    - Status State (On Duty / Off Duty)
- [ ] **UI Components (`.insetGrouped` List)**
    - Section: Current Status (Large Text/Icon)
    - Section: Map (Mini Map showing current loc & workplace)
    - Section: Actions (Button: Check In / Check Out)

## 2.2 History Tab
- [ ] **ViewModel Setup**
    - Fetch Records (Sorted by Date Desc)
    - Grouping logic (by Month/Day)
- [ ] **List View**
    - `NavigationLink` to Detail
    - Row: Workplace Name + Time Range
- [ ] **Detail View**
    - Map showing `LocationProof` points
    - Metadata display (Note, Manual flag)
    - Edit action (manual correction of entry/exit time)
    - Show correction reason and edited flag for auditability
    - Show correction timeline (before/after values + editedAt)

## 2.3 Settings Tab
- [ ] **Workplace List**
    - List registered locations
    - Swipe to delete
    - `+` Button for Add
- [ ] **Workplace Edit Form**
    - `TextField` (Name)
    - `Map` (Pin Drop / Drag)
    - `Slider` (Radius)
    - Save logic

## 2.4 Export
- [ ] **Export UI**
    - CSV export action
    - PDF export action
    - Include export generated time and integrity hash in output preview
    - Error handling and user feedback
- [ ] **Export ViewModel (TDD)**
    - **RED**: Write tests for output field completeness and empty-state handling
    - **RED**: Write tests for integrity hash display and mismatch warning
    - **GREEN**: Implement export use case wiring
    - **REFACTOR**: Separate formatting concern from UI state
