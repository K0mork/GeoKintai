# Phase 1: Project Setup & Core Logic

## 1.1 Project Structure
- [ ] **Initialize Xcode Project**
    - [ ] Create `GeoKintai` (App)
    - [ ] **Create `GeoKintaiTests` (Test Target)**
    - [ ] Folders: `Core`, `Features`, `Model`, `Resources`
- [ ] **Capability Configuration**
    - `Info.plist`: Location Usage Description (Always & When In Use)
    - Check `Background Modes`: Location Updates

## 1.2 Data Persistence (Core Data)
- [ ] **Model Definition** (`GeoKintai.xcdatamodeld`)
    - [ ] Define Entity: `Workplace` (attributes: id, name, lat, lon, radius, monitoringEnabled)
    - [ ] Define Entity: `AttendanceRecord` (attributes: id, entryTime, exitTime, isManual, note)
    - [ ] Define Entity: `AttendanceCorrection` (attributes: recordId, old/new times, reason, editedAt, integrityHash)
    - [ ] Define Entity: `LocationProof` (attributes: id, lat, lon, accuracy, altitude, speed, reason)
    - [ ] Add integrity hash field to evidence entities (`AttendanceCorrection`, `LocationProof`)
    - [ ] Generate NSManagedObject subclasses (manual/none codegen suggested for flexibility)
- [ ] **PersistenceController (TDD)**
    - [ ] **RED**: Create `PersistenceControllerTests.swift`. Write test to verify `NSPersistentContainer` loads.
    - [ ] **GREEN**: Implement `PersistenceController.shared`.
    - [ ] **REFACTOR**: Ensure in-memory store is used for tests.

## 1.3 Repositories (TDD)
- [ ] **WorkplaceRepository**
    - [ ] **RED**: Create `WorkplaceRepositoryTests.swift`. Write tests for add/fetch/delete.
    - [ ] **GREEN**: Implement `WorkplaceRepository` methods using Core Data.
    - [ ] **REFACTOR**: Extract Core Data context injection for easier testing.
- [ ] **AttendanceRepository**
    - [ ] **RED**: Create `AttendanceRepositoryTests.swift`. Write tests for check-in/check-out logic.
    - [ ] **RED**: Add test to prevent duplicate active record (`exitTime == nil`) per workplace.
    - [ ] **GREEN**: Implement `AttendanceRepository` methods.
    - [ ] **REFACTOR**: Optimize fetch requests.
- [ ] **AttendanceCorrectionRepository**
    - [ ] **RED**: Create `AttendanceCorrectionRepositoryTests.swift` for append-only correction records.
    - [ ] **GREEN**: Implement correction append and fetch timeline methods.
    - [ ] **REFACTOR**: Prevent update/delete operations on correction entity.

## 1.4 Location Service (Core Logic) (TDD)
- [ ] **LocationManager Wrapper**
    - [ ] **RED**: Create `LocationManagerTests.swift` (Mock CLLocationManager).
    - [ ] **GREEN**: Implement `LocationManagerWrapper` to handle delegate callbacks.
    - [ ] **REFACTOR**: Ensure thread safety.
- [ ] **Region Monitoring Logic**
    - [ ] **RED**: Write tests for `startMonitoring(for: region)`.
    - [ ] **GREEN**: Implementation.
- [ ] **Background Handling Logic**
    - [ ] **RED**: Test background task creation triggers.
    - [ ] **GREEN**: Implement `didEnterRegion` -> `beginBackgroundTask` flow.

## 1.5 Domain Verifiers (TDD)
- [ ] **StayVerifier**
    - [ ] **RED**: Write tests for stay confirmation with threshold fixed to 5 min.
    - [ ] **GREEN**: Implement radius/time-based confirmation.
- [ ] **ExitVerifier**
    - [ ] **RED**: Write tests for exit confirmation with re-check window fixed to 2 min.
    - [ ] **GREEN**: Implement drift-tolerant exit decision.
- [ ] **Clock Abstraction**
    - [ ] **RED**: Test deterministic time control without `sleep`.
    - [ ] **GREEN**: Inject mockable clock into verifiers/services.

## 1.6 Integrity (TDD)
- [ ] **IntegrityHashService**
    - [ ] **RED**: Write tests for deterministic hash generation from evidence fields.
    - [ ] **GREEN**: Implement hash generation and verification.
- [ ] **Audit Policy Guard**
    - [ ] **RED**: Write tests that correction logs cannot be overwritten/deleted.
    - [ ] **GREEN**: Implement append-only guard at repository layer.
