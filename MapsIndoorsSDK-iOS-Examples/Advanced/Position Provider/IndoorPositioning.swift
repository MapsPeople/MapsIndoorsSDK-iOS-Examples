import UIKit
import CoreLocation
import MapsIndoorsCore
import MapsIndoors

class IndoorPositioning: BaseMapController, MPMapControlDelegate {
    
    override func setupController() async {
        setPositionProvider()
        
        if let dr = MPMapsIndoors.shared.displayRuleFor(displayRuleType: .blueDot) {
            dr.icon = createLocationMarker()
        }
    }
    
    func onPositionUpdate(position: MPPositionResult) {
        // Handle the new position update if needed
        MapEngine.selectedMapProvider?.setCamera(coordinates: position.coordinate, zoom: 18.0)
    }
    
    private func setPositionProvider() {
        if let tenantId = fetchCiscoDNATenantId() {
            setupCiscoDNAProvider(with: tenantId)
        } else {
            setupCoreLocationProvider()
        }
        
        mapControl?.delegate = self
        mapControl?.showUserPosition = true
    }
    
    private func fetchCiscoDNATenantId() -> String? {
        guard let configs = MPMapsIndoors.shared.solution?.positionProviderConfigs,
              let ciscodnaConfig = configs[Constants.ciscoDNAKey],
              let tenantId = ciscodnaConfig[Constants.tenantIdKey] as? String else {
            return nil
        }
        return tenantId
    }
    
    private func setupCiscoDNAProvider(with tenantId: String) {
        let dnaPositionProvider = PureCiscoDNAProvider()
        dnaPositionProvider.tenantId = tenantId
        MPMapsIndoors.shared.positionProvider = dnaPositionProvider
        dnaPositionProvider.startPositioning(nil)
    }
    
    private func setupCoreLocationProvider() {
        let clPositionProvider = CoreLocationPositionProvider()
        clPositionProvider.setupLocationManager()
        MPMapsIndoors.shared.positionProvider = clPositionProvider
        clPositionProvider.startPositioning()
    }
    
    // create a blue colored dot
    private func createLocationMarker() -> UIImage {
        let size = CGSize(width: 25, height: 25)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        // Draw the blue dot
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fillEllipse(in: rect)
        
        // Draw the arrow
        context?.setFillColor(UIColor.white.cgColor) // Arrow color
        let arrowWidth: CGFloat = 6.0
        let arrowHeight: CGFloat = 10.0
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: size.width/2, y: 5)) // Top point of the arrow
        arrowPath.addLine(to: CGPoint(x: size.width/2 - arrowWidth/2, y: 5 + arrowHeight))
        arrowPath.addLine(to: CGPoint(x: size.width/2 + arrowWidth/2, y: 5 + arrowHeight))
        arrowPath.close()
        context?.addPath(arrowPath.cgPath)
        context?.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
    
}

class CoreLocationPositionProvider: NSObject, MPPositionProvider, CLLocationManagerDelegate {
    
    var delegate: MPPositionProviderDelegate?
    var latestPosition: MPPositionResult?
    let locationManager = CLLocationManager()

    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startPositioning() {
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = 5 // Get updates every 5 degrees change
        locationManager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let position = MPPositionResult(coordinate: location.coordinate, accuracy: location.horizontalAccuracy, bearing: latestPosition?.bearing ?? 0)
            latestPosition = position
            delegate?.onPositionUpdate(position: position)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if let latestPosition = self.latestPosition {
            let updatedPosition = MPPositionResult(coordinate: latestPosition.coordinate, floorIndex: latestPosition.floorIndex, accuracy: latestPosition.accuracy, bearing: newHeading.trueHeading)
            self.latestPosition = updatedPosition
            delegate?.onPositionUpdate(position: updatedPosition)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}

private struct Constants {
    static let ciscoDNAKey = "ciscodna"
    static let tenantIdKey = "ciscoDnaSpaceTenantId"
}
