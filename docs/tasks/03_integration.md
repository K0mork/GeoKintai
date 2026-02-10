# Phase 3: Integration & Verification

## 3.1 Integration
- [ ] **App Launch Flow**
    - `GeoKintaiApp`: Inject Persistence
    - `onAppear`: Request Permissions & Sync Regions
- [ ] **Dependencies**
    - Connect `WorkplaceRepository` changes to `LocationManager.syncMonitoredRegions()`

## 3.2 Verification
- [ ] **Automated Tests**
    - Unit Tests for Repository CRUD
    - Logic Tests for Timer duration
    - Permission downgrade behavior tests
    - Export output contract tests (CSV/PDF)
    - Integrity hash verification tests
    - Append-only correction audit tests
- [ ] **Simulator Tests**
    - Create GPX files (`SimulatedLocations/`)
    - Verify `Commute_In.gpx` triggers Check-In
    - Verify `Pass_By.gpx` does NOT trigger Check-In
    - Verify permission change (`Always` -> `When In Use`) disables background detection
    - Verify multiple workplaces keep records isolated
    - Verify correction timeline appears after manual edits
