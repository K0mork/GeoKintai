# Logic Flow (Sequence Diagram)

## 1. Background Entry Detection & Monitoring Logic

This diagram illustrates how the app handles geofence entry, background execution, and "stay" confirmation.

```mermaid
sequenceDiagram
    participant OS as iOS (Core Location)
    participant App as GeoKintai App (Bg Task)
    participant CoreData as Local DB
    participant User

    Note over OS, User: App is in Background / Suspended

    User->>OS: Enters monitored region (Radius 100m)
    OS->>App: didEnterRegion (Wakes up App)
    
    activate App
    App->>App: beginBackgroundTask (Request extra time)
    App->>App: startUpdatingLocation (High Accuracy)
    App->>App: Start Timer (5 mins)
    
    loop Every 1 sec for 5 mins
        OS->>App: didUpdateLocations (GPS Data)
        App->>App: Append to collectedLocations buffer
    end
    
    Note right of App: Timer Fired (5 mins)
    
    App->>App: Analyze collectedLocations
    
    alt Stay Confirmed (e.g. still in radius)
        App->>CoreData: Save AttendanceRecord (Entry)
        App->>CoreData: Save LocationProofs (Sampled GPS points)
        App->>User: (Optional) Send Local Notification "Checked In"
    else False Alarm (Passed through)
        App->>App: Discard data
    end
    
    App->>App: stopUpdatingLocation
    App->>App: endBackgroundTask
    deactivate App
```

## 2. Exit Logic

Similar logic applies to exit, but with a "debounce" buffer to prevent accidental checkout due to GPS drift.

```mermaid
sequenceDiagram
    User->>OS: Exits monitored region
    OS->>App: didExitRegion
    activate App
    App->>App: beginBackgroundTask
    App->>App: startUpdatingLocation
    App->>App: Start Timer (e.g. 2 mins verification)
    
    loop Verification
        OS->>App: didUpdateLocations
    end
    
    App->>App: Timer Fired. Check distance.
    
    alt Real Exit Confirmed
        App->>CoreData: Update AttendanceRecord (Set ExitTime)
        App->>CoreData: Save proofs
    else Still Inside (GPS Drift)
        App->>App: Ignore exit event
    end
    
    App->>App: stopUpdatingLocation
    App->>App: endBackgroundTask
    deactivate App
```
