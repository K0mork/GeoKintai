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
- [ ] **Simulator Tests**
    - Create GPX files (`SimulatedLocations/`)
    - Verify `Commute_In.gpx` triggers Check-In
    - Verify `Pass_By.gpx` does NOT trigger Check-In
