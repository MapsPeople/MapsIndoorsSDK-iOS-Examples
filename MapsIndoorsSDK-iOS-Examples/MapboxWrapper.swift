import Foundation
import MapboxMaps
import MapsIndoors
import MapsIndoorsMapbox

@objcMembers public class MapboxWrapper : NSObject, GenericMap {

    private let map : MapboxMap
    private let mapView : MapView

    public required init(MBmapView: MapView) {
        self.mapView = MBmapView
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.map = self.mapView.mapboxMap
    }

    public func setup() {
        // Nothing needed here, for now
    }

    var delegate: GenericMapDelegate?

    public var view: UIView {
        return mapView
    }

    public var padding: UIEdgeInsets {
        get { return mapView.cameraState.padding }
        set { map.setCamera(to: CameraOptions(padding: newValue)) }
    }

    public var target: CLLocationCoordinate2D {
        get { return mapView.cameraState.center }
        set { map.setCamera(to: CameraOptions(center: newValue)) }
    }

    public var bearing: Double {
        get { return mapView.cameraState.bearing }
        set { map.setCamera(to: CameraOptions(bearing: newValue)) }
    }

    public var tilt: Double {
        get { return mapView.cameraState.pitch }
        set { map.setCamera(to: CameraOptions(pitch: newValue)) }
    }

    public var zoom: Double {
        get { return mapView.cameraState.zoom }
        set { map.setCamera(to: CameraOptions(zoom: newValue)) }
    }

    public var visibleRegion: MPGeoRegion {
        let farLeft = map.coordinate(for: view.frame.origin)
        let farRight = map.coordinate(for: view.frame.origin.applying(CGAffineTransform(translationX: view.frame.width, y: 0)))
        let nearLeft = map.coordinate(for: view.frame.origin.applying(CGAffineTransform(translationX: 0, y: view.frame.height)))
        let nearRight = map.coordinate(for: view.frame.origin.applying(CGAffineTransform(translationX: view.frame.width, y: view.frame.height)))
        return MPGeoRegion(nearLeft: nearLeft, farLeft: farLeft, farRight: farRight, nearRight: nearRight)
    }
    
    func animate(bounds: MPGeoBounds) {
        let mapBounds = CoordinateBounds(southwest: CLLocationCoordinate2D(latitude: bounds.southWest.latitude, longitude: bounds.southWest.longitude),
                                      northeast: CLLocationCoordinate2D(latitude: bounds.northEast.latitude, longitude: bounds.northEast.longitude))
        try? mapView.mapboxMap.setCameraBounds(with: CameraBoundsOptions(bounds: mapBounds))
        
        let camera = mapView.mapboxMap.camera(for: mapBounds, padding: .zero, bearing: 0, pitch: 0)
        
        mapView.mapboxMap.setCamera(to: camera)
    }

    func setCamera(coordinates: CLLocationCoordinate2D, zoom: Float) {
        self.mapView.camera.fly(to: CameraOptions(center: coordinates, padding: UIEdgeInsets(), anchor: nil, zoom: CGFloat(zoom), bearing: CLLocationDirection(0), pitch: CGFloat(0)), duration: TimeInterval(0.5)) { _ in }
    }
    
    public func move(target: CLLocationCoordinate2D, zoom: Double, bearing: Double, tilt: Double) {
        mapView.camera.fly(to: CameraOptions(center: target, zoom: zoom, bearing: bearing, pitch: tilt))
    }

    public func fit(northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D, padding: Float) {
        do {
            let pos = mapView.mapboxMap.camera(for: CoordinateBounds(southwest: southWest, northeast: northEast), padding: UIEdgeInsets(), bearing: 0.0, pitch: 0.0)
            mapView.mapboxMap.setCamera(to: pos)
        }
    }

    public func fit(northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D, edgeInsets: UIEdgeInsets) {
        do {
            let pos = mapView.mapboxMap.camera(for: CoordinateBounds(southwest: southWest, northeast: northEast), padding: edgeInsets, bearing: 0.0, pitch: 0.0)
            mapView.mapboxMap.setCamera(to: pos)
        }
    }

}
