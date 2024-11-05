import MapboxMaps
import MapsIndoors
import MapsIndoorsMapbox
import UIKit

@objcMembers public class MapboxWrapper: NSObject, GenericMap {
    private var map: MapboxMap { mapView.mapboxMap }
    private let mapView: MapView

    public required init(MBmapView: MapView) {
        mapView = MBmapView
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    public func setup() {
        // Nothing needed here, for now
    }

    var delegate: GenericMapDelegate?

    public var view: UIView {
        mapView
    }

    public var padding: UIEdgeInsets {
        get { mapView.mapboxMap.cameraState.padding }
        set { map.setCamera(to: CameraOptions(padding: newValue)) }
    }

    public var target: CLLocationCoordinate2D {
        get { mapView.mapboxMap.cameraState.center }
        set { map.setCamera(to: CameraOptions(center: newValue)) }
    }

    public var bearing: Double {
        get { mapView.mapboxMap.cameraState.bearing }
        set { map.setCamera(to: CameraOptions(bearing: newValue)) }
    }

    public var tilt: Double {
        get { mapView.mapboxMap.cameraState.pitch }
        set { map.setCamera(to: CameraOptions(pitch: newValue)) }
    }

    public var zoom: Double {
        get { mapView.mapboxMap.cameraState.zoom }
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
        let coordinates = [CLLocationCoordinate2D(latitude: bounds.southWest.latitude, longitude: bounds.southWest.longitude),
                           CLLocationCoordinate2D(latitude: bounds.northEast.latitude, longitude: bounds.northEast.longitude)]

        if let camera = try? mapView.mapboxMap.camera(for: coordinates, camera: CameraOptions(), coordinatesPadding: .zero, maxZoom: 99, offset: .zero) {
            mapView.mapboxMap.setCamera(to: camera)
        }
    }

    func setCamera(coordinates: CLLocationCoordinate2D, zoom: Float) {
        mapView.camera.fly(to: CameraOptions(center: coordinates, padding: UIEdgeInsets(), anchor: nil, zoom: CGFloat(zoom), bearing: CLLocationDirection(0), pitch: CGFloat(0)), duration: TimeInterval(0.5)) { _ in }
    }

    public func move(target: CLLocationCoordinate2D, zoom: Double, bearing: Double, tilt: Double) {
        mapView.camera.fly(to: CameraOptions(center: target, zoom: zoom, bearing: bearing, pitch: tilt))
    }

    public func fit(northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D, padding _: Float) {
        let coordinates = [southWest, northEast]
        if let pos = try? mapView.mapboxMap.camera(for: coordinates, camera: CameraOptions(), coordinatesPadding: .zero, maxZoom: 99, offset: .zero) {
            mapView.mapboxMap.setCamera(to: pos)
        }
    }

    public func fit(northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D, edgeInsets: UIEdgeInsets) {
        let coordinates = [southWest, northEast]
        if let pos = try? mapView.mapboxMap.camera(for: coordinates, camera: CameraOptions(), coordinatesPadding: edgeInsets, maxZoom: 99, offset: .zero) {
            mapView.mapboxMap.setCamera(to: pos)
        }
    }
}
