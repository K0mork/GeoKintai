import SwiftUI
import CoreLocation

struct RootTabView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsInitialWorkplaceSetup = false

    var body: some View {
        TabView {
            NavigationStack {
                StatusView()
            }
            .tabItem {
                Label("Status", systemImage: "dot.radiowaves.left.and.right")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .onAppear {
            refreshPermissionStatus()
            store.requestLocationPermissionForInitialSetupIfNeeded()
            updateInitialWorkplaceSetupPresentation()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else {
                return
            }
            refreshPermissionStatus()
            store.requestLocationPermissionForInitialSetupIfNeeded()
            updateInitialWorkplaceSetupPresentation()
        }
        .onChange(of: store.workplaces) { _, workplaces in
            showsInitialWorkplaceSetup = workplaces.isEmpty
        }
        .onChange(of: store.permissionStatus) { _, _ in
            updateInitialWorkplaceSetupPresentation()
        }
        .fullScreenCover(isPresented: $showsInitialWorkplaceSetup) {
            NavigationStack {
                InitialWorkplaceSetupView()
            }
            .interactiveDismissDisabled(true)
            .environmentObject(store)
        }
    }

    private func refreshPermissionStatus() {
        store.refreshPermissionStatusFromSystem()
    }

    private func updateInitialWorkplaceSetupPresentation() {
        let requiresInitialSetup = store.workplaces.isEmpty
        let shouldDeferForPermissionPrompt = store.permissionStatus == .notDetermined
        showsInitialWorkplaceSetup = requiresInitialSetup && !shouldDeferForPermissionPrompt
    }
}

private struct InitialWorkplaceSetupView: View {
    @EnvironmentObject private var store: AppStore

    @State private var locationFetcher = CurrentLocationFetcher()
    @State private var companyName = ""
    @State private var address = ""
    @State private var radius = ""
    @State private var method: RegistrationMethod = .address
    @State private var isSubmitting = false
    @State private var message: String?

    private let addressResolver = AddressCoordinateResolver()

    var body: some View {
        Form {
            Section("初回設定") {
                Text("会社所在地を登録してください。登録後に自動監視を開始します。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("会社情報") {
                TextField("会社名", text: $companyName)
                TextField("監視半径(m, 省略時100)", text: $radius)
                    .keyboardType(.decimalPad)
            }

            Section("登録方法") {
                Picker("登録方法", selection: $method) {
                    ForEach(RegistrationMethod.allCases, id: \.self) { registrationMethod in
                        Text(registrationMethod.title).tag(registrationMethod)
                    }
                }
                .pickerStyle(.segmented)

                switch method {
                case .address:
                    TextField("住所", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                    Button {
                        Task { await registerFromAddress() }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("住所から登録")
                        }
                    }
                    .disabled(isSubmitting)
                case .currentLocation:
                    Button {
                        Task { await registerFromCurrentLocation() }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("現在地を登録")
                        }
                    }
                    .disabled(isSubmitting)
                }
            }

            if let message {
                Section("メッセージ") {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("会社所在地設定")
    }

    @MainActor
    private func registerFromAddress() async {
        let normalizedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedAddress.isEmpty else {
            message = "住所を入力してください。"
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let coordinate = try await addressResolver.resolve(address: normalizedAddress)
            registerWorkplace(latitude: coordinate.latitude, longitude: coordinate.longitude)
        } catch {
            message = error.localizedDescription
        }
    }

    @MainActor
    private func registerFromCurrentLocation() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let coordinate = try await locationFetcher.fetchCurrentCoordinate()
            registerWorkplace(latitude: coordinate.latitude, longitude: coordinate.longitude)
        } catch {
            message = error.localizedDescription
        }
    }

    @MainActor
    private func registerWorkplace(latitude: Double, longitude: Double) {
        store.addWorkplace(
            name: companyName,
            latitudeText: String(latitude),
            longitudeText: String(longitude),
            radiusText: radius
        )
        if let errorMessage = store.lastErrorMessage {
            message = errorMessage
            return
        }
        message = nil
    }
}

private extension InitialWorkplaceSetupView {
    enum RegistrationMethod: CaseIterable {
        case address
        case currentLocation

        var title: String {
            switch self {
            case .address:
                return "住所"
            case .currentLocation:
                return "現在地"
            }
        }
    }
}

private struct AddressCoordinateResolver {
    func resolve(address: String) async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error {
                    continuation.resume(
                        throwing: InitialWorkplaceSetupError.addressLookupFailed(
                            detail: error.localizedDescription
                        )
                    )
                    return
                }

                guard let coordinate = placemarks?.first(where: { $0.location != nil })?.location?.coordinate else {
                    continuation.resume(throwing: InitialWorkplaceSetupError.addressNotFound)
                    return
                }
                continuation.resume(returning: coordinate)
            }
        }
    }
}

private final class CurrentLocationFetcher: NSObject, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func fetchCurrentCoordinate() async throws -> CLLocationCoordinate2D {
        guard CLLocationManager.locationServicesEnabled() else {
            throw InitialWorkplaceSetupError.locationServiceDisabled
        }
        guard continuation == nil else {
            throw InitialWorkplaceSetupError.locationRequestInProgress
        }

        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw InitialWorkplaceSetupError.locationPermissionMissing
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let continuation else {
            return
        }
        self.continuation = nil

        guard let coordinate = locations.last?.coordinate else {
            continuation.resume(throwing: InitialWorkplaceSetupError.locationUnavailable)
            return
        }
        continuation.resume(returning: coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        guard let continuation else {
            return
        }
        self.continuation = nil
        continuation.resume(
            throwing: InitialWorkplaceSetupError.locationLookupFailed(detail: error.localizedDescription)
        )
    }
}

private enum InitialWorkplaceSetupError: LocalizedError {
    case addressNotFound
    case addressLookupFailed(detail: String)
    case locationPermissionMissing
    case locationServiceDisabled
    case locationUnavailable
    case locationLookupFailed(detail: String)
    case locationRequestInProgress

    var errorDescription: String? {
        switch self {
        case .addressNotFound:
            return "住所から位置情報を特定できませんでした。"
        case .addressLookupFailed(let detail):
            return "住所検索に失敗しました: \(detail)"
        case .locationPermissionMissing:
            return "現在地登録には iOS 設定で位置情報の許可が必要です。"
        case .locationServiceDisabled:
            return "位置情報サービスが無効です。iOS 設定を確認してください。"
        case .locationUnavailable:
            return "現在地を取得できませんでした。"
        case .locationLookupFailed(let detail):
            return "現在地の取得に失敗しました: \(detail)"
        case .locationRequestInProgress:
            return "現在地取得を実行中です。完了をお待ちください。"
        }
    }
}
