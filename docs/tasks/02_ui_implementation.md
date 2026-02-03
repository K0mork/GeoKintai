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

## 2.3 Settings Tab
- [ ] **Workplace List**
    - List registered locations
    - Swipe to define (Delete)
    - `+` Button for Add
- [ ] **Workplace Edit Form**
    - `TextField` (Name)
    - `Map` (Pin Drop / Drag)
    - `Slider` (Radius)
    - Save logic
