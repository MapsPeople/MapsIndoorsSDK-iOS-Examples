import CoreLocation
import MapsIndoors

class MyPositionProvider: MPPositionProvider {
    var delegate: MPPositionProviderDelegate?
    var latestPosition: MPPositionResult?
    private var running = false

    init(mockAt: MPPoint) {
        latestPosition = MPPositionResult(coordinate: CLLocationCoordinate2D(latitude: mockAt.latitude, longitude: mockAt.longitude), floorIndex: 10, accuracy: 20.0)
    }

    func updatePosition() {
        guard running else { return }

        latestPosition?.bearing = (latestPosition!.bearing + 10)
        latestPosition?.coordinate = generateRandomCoordinate()
        latestPosition?.bearing = Double.random(in: 0 ..< 360)
        latestPosition?.accuracy = Double.random(in: 0 ..< 10)

        if let delegate, let latestPosition {
            delegate.onPositionUpdate(position: latestPosition)
        }

        Task { @MainActor [weak self] in
            try await Task.sleep(nanoseconds: 1_000_000_000)
            guard let self else { return }

            updatePosition()
        }
    }

    func startPositioning(_: String?) {
        running = true
        updatePosition()
    }

    func stopPositioning(_: String?) {
        running = false
    }

    func generateRandomCoordinate() -> CLLocationCoordinate2D {
        // Define a small range for the random offset
        let offset = 0.00001

        // Generate random offsets for latitude and longitude
        let latOffset = Double.random(in: -offset ... offset)
        let lonOffset = Double.random(in: -offset ... offset)

        // Create a new coordinate with the random offsets
        let newCoordinate = CLLocationCoordinate2D(latitude: (latestPosition?.coordinate.latitude ?? 0) + latOffset, longitude: (latestPosition?.coordinate.longitude ?? 0) + lonOffset)
        return newCoordinate
    }
}
