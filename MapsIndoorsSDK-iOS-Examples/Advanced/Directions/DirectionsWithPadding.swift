import Foundation
import MapsIndoorsCore
import MapsIndoors
import GoogleMaps

class DirectionsWithPadding: BaseMapController {
    
    var directionsRenderer: MPDirectionsRenderer?
    
    var origin: MPLocation?
    var destination: MPLocation?
    
    private enum ButtonState {
        case state1
        case state2
        case state3
    }
    
    private var isFirstRun: Bool = false
    
    private var paddingOne: CGFloat = 50
    private var paddingTwo: CGFloat = 90
    private var padding = UIEdgeInsets()
    private var fitMode: MPCameraViewFitMode!
    
    private var paddingButtonState: ButtonState = .state1
    private var orientationButtonState: ButtonState = .state1
    private var paddingButton: UIButton = {
        let button = UIButton()
        return button
    }()
    private var orientationButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    override func setupController() async {
        await setupLocations()
        setupButtons()
    }
    
    func setupLocations() async {
        let query = MPQuery()
        let filter = MPFilter()
        filter.take = 1 // Take only one results

        // Set origin
        query.query = "Copenhagen"
        origin = await getFirstLocation(query: query, filter: filter)
        if origin == nil {
            origin = await getRandomLocation()
        }

        // Set destination
        query.query = "Dining Room"
        destination = await getFirstLocation(query: query, filter: filter)
        if destination == nil {
            destination = await getRandomLocation()
        }

        // Generate route
        if let destination = destination {
            generateRoute(to: destination)
        }
    }
    
    func getFirstLocation(query: MPQuery, filter: MPFilter) async -> MPLocation? {
        let locations = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        return locations.first
    }
    
    func generateRoute(to destination: MPLocation) {
        guard let mapControl = mapControl, let validOriginLocation = origin else { return }
        if directionsRenderer == nil {
            directionsRenderer = mapControl.newDirectionsRenderer()
        }
        
        let directionsQuery = MPDirectionsQuery(origin: validOriginLocation, destination: destination)
       
        Task {
            do {
                let route = try await MPMapsIndoors.shared.directionsService.routingWith(query: directionsQuery)
                
                directionsRenderer?.route = route
                directionsRenderer?.routeLegIndex = 0
                if isFirstRun {
                    // Set padding based on paddingButtonState
                    switch paddingButtonState {
                    case .state1:
                        // Do not provide padding
                        directionsRenderer?.padding = UIEdgeInsets.zero
                    case .state2:
                        directionsRenderer?.padding = UIEdgeInsets(top: paddingOne, left: paddingOne, bottom: paddingOne, right: paddingOne)
                    case .state3:
                        directionsRenderer?.padding = UIEdgeInsets(top: paddingTwo, left: paddingTwo, bottom: paddingTwo, right: paddingTwo)
                    }
                    
                    // Set fitMode based on orientationButtonState
                    switch orientationButtonState {
                    case .state1:
                        directionsRenderer?.fitMode = .firstStepAligned
                    case .state2:
                        directionsRenderer?.fitMode = .northAligned
                    case .state3:
                        directionsRenderer?.fitMode = .startToEndAligned
                    }
                } else {
                    isFirstRun = true
                    directionsRenderer?.fitMode = .northAligned
                }
                
                directionsRenderer?.animate(duration: 5)
                setGoogleCamera(route!) // TODO: use this while awaiting SDK route padding fix for Google Maps
                
            } catch {
                print("Error getting directions: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func paddingButtonTapped() {
        switch paddingButtonState {
        case .state1:
            paddingButton.setTitle("Padding: \(paddingOne.description)", for: .normal)
            paddingButtonState = .state2
        case .state2:
            paddingButton.setTitle("Padding: \(paddingTwo.description)", for: .normal)
            paddingButtonState = .state3
        case .state3:
            paddingButton.setTitle("Apply Padding", for: .normal)
            paddingButtonState = .state1
        }
        if let destination = destination {
            generateRoute(to: destination)
        }
    }
    
    @objc func orientationButtonTapped() {
        switch orientationButtonState {
        case .state1:
            orientationButton.setTitle("North Aligned", for: .normal)
            orientationButtonState = .state2
        case .state2:
            orientationButton.setTitle("Start to End Aligned", for: .normal)
            orientationButtonState = .state3
        case .state3:
            orientationButton.setTitle("First Step Aligned", for: .normal)
            orientationButtonState = .state1
        }
        if let destination = destination {
            generateRoute(to: destination)
        }
    }
    
    private func setupButtons() {
        paddingButton = UIButton(frame: CGRect(x: 50, y: 100, width: 200, height: 50))
        paddingButton.setTitle("Apply Padding", for: .normal)
        paddingButton.backgroundColor = UIColor(red: 75/255, green: 125/255, blue: 124/255, alpha: 0.4)
        paddingButton.addTarget(self, action: #selector(paddingButtonTapped), for: .touchUpInside)
        
        orientationButton = UIButton(frame: CGRect(x: 50, y: 200, width: 200, height: 50))
        orientationButton.setTitle("Change Orientation", for: .normal)
        orientationButton.backgroundColor = UIColor(red: 75/255, green: 125/255, blue: 124/255, alpha: 0.4)
        orientationButton.addTarget(self, action: #selector(orientationButtonTapped), for: .touchUpInside)
        
        // Create a stack view
        let stackView = UIStackView(arrangedSubviews: [paddingButton, orientationButton])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Add constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
        ])
    }
    
    override func adjustUI(forMenu: Bool) {
        paddingButton.isHidden = forMenu
        orientationButton.isHidden = forMenu
    }
    
    override func updateForBuildingChange() {
        paddingButton.isHidden = false
        orientationButton.isHidden = false
    }
    
    private func setGoogleCamera(_ route: MPRoute) {
        if let googleMapProvider = MapEngine.selectedMapProvider as? GoogleMapSpecific {
            if let firstLeg = route.legs.first {
                if let lastLeg = route.legs.last {
                    let startingPoint = CLLocationCoordinate2D(latitude: CLLocationDegrees(firstLeg.start_location.lat), longitude: CLLocationDegrees(firstLeg.start_location.lng))
                    let endingPoint = CLLocationCoordinate2D(latitude: CLLocationDegrees(lastLeg.end_location.lat), longitude: CLLocationDegrees(lastLeg.end_location.lng))
                    
                    // Create bounds using the starting and ending points
                    let bounds = GMSCoordinateBounds(coordinate: startingPoint, coordinate: endingPoint)
                    
                    // Adjust the camera to fit the bounds with some padding
                    let cameraUpdate = GMSCameraUpdate.fit(bounds, withPadding: 100.0) // Adjust the padding as needed
                    googleMapProvider.setCamera(update: cameraUpdate)
                }
            }
        }
    }
}
