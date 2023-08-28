import Foundation
import GoogleMaps
import MapsIndoors
import MapsIndoorsGoogleMaps

public class GoogleMapsWrapper: NSObject, GenericMap, GoogleMapSpecific, GMSMapViewDelegate {
    
    var view : UIView {
        get {
            map
        }
    }
    
    private let map : GMSMapView
    
    public required init(GMMapView: GMSMapView) {
        self.map = GMMapView
    }
    
    func setup() {
        self.map.accessibilityElementsHidden = false
        self.map.isBuildingsEnabled = false
        self.map.settings.compassButton = false
    }
    
    var delegate: GenericMapDelegate? {
        didSet {self.map.delegate = self}
    }
    
    var padding: UIEdgeInsets {
        get {
            map.padding
        }
        set {
            map.padding = newValue
        }
    }
    
    var target: CLLocationCoordinate2D {
        get {
            map.camera.target
        }
        set {
            map.animate(toLocation: newValue)
        }
    }
    
    var bearing: Double {
        get {
            map.camera.bearing
        }
        set {
            map.animate(toBearing: CLLocationDirection(floatLiteral: newValue))
        }
    }
    
    var tilt: Double{
        get {
            map.camera.viewingAngle
        }
        set {
            map.animate(toViewingAngle: newValue)
        }
    }
    
    var zoom: Double {
        get {
            Double(map.camera.zoom)
        }
        set {
            map.animate(toZoom: Float(newValue))
        }
    }
    
    var visibleRegion: MPGeoRegion {
        let gmsRegion = map.projection.visibleRegion()
        return MPGeoRegion(nearLeft: gmsRegion.nearLeft, farLeft: gmsRegion.farLeft, farRight: gmsRegion.farRight, nearRight: gmsRegion.nearRight)
    }
    
    func animate(bounds: MPGeoBounds) {
        let newBounds = LatLngBoundsConverter.convertToGoogleBounds(bounds: bounds)
        map.animate(with: GMSCameraUpdate.fit(newBounds))
    }
    
    func setCamera(coordinates: CLLocationCoordinate2D, zoom: Float) {
        map.camera = .camera(withLatitude: coordinates.latitude, longitude: coordinates.longitude, zoom: zoom)
    }
    
    func setCamera(update: GMSCameraUpdate) {
        map.moveCamera(update)
    }
    
    func move(target: CLLocationCoordinate2D, zoom: Double, bearing: Double, tilt: Double) {
        let position = GMSCameraPosition(target: target, zoom: Float(zoom), bearing: CLLocationDirection(floatLiteral: bearing), viewingAngle: tilt)
        map.animate(with: GMSCameraUpdate.setCamera(position))
    }
    
    func fit(northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D, padding: Float) {
        let bounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        map.animate(with: GMSCameraUpdate.fit(bounds, withPadding: CGFloat(padding)))
    }
    
    func fit(northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D, edgeInsets: UIEdgeInsets) {
        let bounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        map.animate(with: GMSCameraUpdate.fit(bounds, with: edgeInsets))
    }
}
