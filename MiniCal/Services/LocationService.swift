//
//  LocationService.swift
//  MiniCal
//
//  地理位置服务 - 用于日出日落和礼拜时间计算
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    // MARK: - Published Properties

    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var locationAuthorized: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer  // 城市级精度足够
        checkAuthorization()
    }

    // MARK: - Public Methods

    /// 请求位置权限
    func requestAuthorization() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // 引导用户到设置页面
            Logger.warning("位置权限被拒绝，请到系统设置中开启", category: Logger.app)
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingLocation()
        @unknown default:
            break
        }
    }

    /// 开始更新位置
    func startUpdatingLocation() {
        guard locationAuthorized else {
            Logger.warning("未授权位置权限", category: Logger.app)
            return
        }

        locationManager.startUpdatingLocation()
        Logger.debug("开始更新位置", category: Logger.app)
    }

    /// 停止更新位置
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        Logger.debug("停止更新位置", category: Logger.app)
    }

    /// 获取默认位置（北京）
    func getDefaultLocation() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)  // 北京
    }

    // MARK: - Private Methods

    private func checkAuthorization() {
        let status = locationManager.authorizationStatus
        authorizationStatus = status

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationAuthorized = true
            startUpdatingLocation()
            Logger.debug("位置权限已授权", category: Logger.app)

        case .notDetermined:
            locationAuthorized = false
            Logger.debug("位置权限未确定", category: Logger.app)

        case .denied, .restricted:
            locationAuthorized = false
            Logger.warning("位置权限被拒绝或受限", category: Logger.app)

        @unknown default:
            locationAuthorized = false
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location.coordinate

            Logger.debug(
                "位置更新: \(location.coordinate.latitude), \(location.coordinate.longitude)",
                category: Logger.app
            )

            // 获取位置后停止更新（节省电量）
            manager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.error("位置更新失败: \(error.localizedDescription)", category: Logger.app)

        // 使用默认位置
        if currentLocation == nil {
            currentLocation = getDefaultLocation()
            Logger.debug("使用默认位置（北京）", category: Logger.app)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
}
