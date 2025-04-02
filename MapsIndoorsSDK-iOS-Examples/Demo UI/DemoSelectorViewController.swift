import UIKit
import MapsIndoorsCore
import MapsIndoors
import MapsIndoorsGoogleMaps
import MapsIndoorsMapbox
import GoogleMaps
import MapboxMaps

class DemoSelectorViewController: UITableViewController {
    
    var googleMap: GMSMapView? = nil
    var mapView: MapView? = nil
    var APIKey: String?
    var selectedMapProvider: Int?
    @IBOutlet weak var mapProviderSegmentedControl: UISegmentedControl!
    static var isGoogleMapsInitialized = false
    
    var memoryAndZoomUI: MemoryAndZoomUI!
    
    var searchController: UISearchController!
    var filteredDemos: [Demo] = []
    
    var sectionTitles: [String] = []
    
    var dataSource: DemoTableViewDataSource!
    var demoTableViewDelegate: DemoTableViewDelegate!
    
    var hasAlreadyAppeared = false // hack to not force clear selected map view on first launch
    
    @IBAction func segmentControl(_ sender: UISegmentedControl) {
        selectedMapProvider = sender.selectedSegmentIndex
        setupMapProvider(index: sender.selectedSegmentIndex)
    }
    
    var operationalState: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchController()
        
        sectionTitles = Array(Set(demos.map { $0.sectionTitle })).sorted {
            switch ($0, $1) {
            case ("Getting Started", _): return true
            case (_, "Getting Started"): return false
            case ("Basic", _): return true
            case (_, "Basic"): return false
            case ("Intermediate", _): return true
            case (_, "Intermediate"): return false
            case ("Advanced", _): return true
            case (_, "Advanced"): return false
            default: return $0 < $1
            }
        }
        filteredDemos = demos
        
        dataSource = DemoTableViewDataSource(demos: demos, sectionTitles: sectionTitles, filteredDemos: filteredDemos)
        demoTableViewDelegate = DemoTableViewDelegate(demos: demos, sectionTitles: sectionTitles, filteredDemos: filteredDemos, navigationController: navigationController)
        demoTableViewDelegate.delegate = self
        
        tableView.dataSource = dataSource
        tableView.delegate = demoTableViewDelegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let error = UserDefaults.standard.string(forKey: "MapsIndoorsError") {
            let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            UserDefaults.standard.removeObject(forKey: "MapsIndoorsError")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Only clear the selected map view if the view controller has already appeared once
        if hasAlreadyAppeared {
            MapEngine.clearSelectedMapView()
        }
        
        // Set up the map view based on the selected map provider
        if let selectedMapProvider = selectedMapProvider {
            mapProviderSegmentedControl.selectedSegmentIndex = selectedMapProvider  // Update the UISegmentedControl
            setupMapProvider(index: selectedMapProvider)
        }
        
        setupMemoryAndZoomUI()
        
        // Set the flag to true after the first appearance
        hasAlreadyAppeared = true
    }
    
    private func setupMapProvider(index: Int) {
        switch index {
        case 0:
            setupMapBox()
        case 1:
            setupGoogleMaps()
        default:
            print("Invalid map provider index")
        }
    }
    
    private func setupGoogleMaps() {
        if !DemoSelectorViewController.isGoogleMapsInitialized {
            GMSServices.provideAPIKey(APIKeys.googleMapsAPIKey)
            DemoSelectorViewController.isGoogleMapsInitialized = true
        }
        self.googleMap = GMSMapView()
        MapEngine.selectedMapView = googleMap
        MapEngine.APIKey = APIKey!
        MapEngine.selectedMapProvider = GoogleMapsWrapper(GMMapView: googleMap!)
        MapEngine.selectedMapConfig = MPMapConfig(gmsMapView: googleMap!, googleApiKey: APIKeys.googleMapsAPIKey)
        print("Google is selected")
    }
    
    private func setupMapBox() {
        let styleURI: StyleURI = isDarkModeEnabled() ? .dark : .light
        let mapInitOptions = MapInitOptions(mapOptions: MapOptions(), styleURI: styleURI)
        mapView = MapView(frame: view.bounds, mapInitOptions: mapInitOptions)

        MapEngine.selectedMapView = mapView!
        MapEngine.APIKey = APIKey!
        MapEngine.selectedMapProvider = MapboxWrapper(MBmapView: mapView!)
        MapEngine.selectedMapConfig = MPMapConfig(mapBoxView: mapView!, accessToken: "---")
        print("MapBox is selected")
    }

    private func isDarkModeEnabled() -> Bool {
        return self.traitCollection.userInterfaceStyle == .dark
    }
    
    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Demos"
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func setupMemoryAndZoomUI() {
        memoryAndZoomUI = MemoryAndZoomUI.shared
        memoryAndZoomUI.delegate = self
        let window = UIApplication.shared.keyWindow
        if memoryAndZoomUI.superview == nil {
            window?.addSubview(memoryAndZoomUI)
        } else {
            window?.bringSubviewToFront(memoryAndZoomUI)
        }
        reportMemoryUsage()
        reportZoom()
    }
    
    @objc func reportMemoryUsage() -> Void {
        memoryAndZoomUI.firstLabel.text = Memory.formattedMemoryFootprint()
        self.perform(#selector(reportMemoryUsage), with: nil, afterDelay: 1)
    }
    
    @objc func reportZoom() {
        memoryAndZoomUI.secondLabel.text = String(format: "%.2f", MapEngine.selectedMapProvider?.zoom ?? 99)
        self.perform(#selector(reportZoom), with: nil, afterDelay: 0.01)
    }
    
    let demos: [Demo] = [
        // Getting Started
        Demo(controllerClass: DisplayMap.self, title: "Display Map", description: "This demo simply displays map with MapsIndoors content", sectionTitle: "Getting Started"),
        Demo(controllerClass: BasicDirection.self, title: "Render Route", description: "This demo renders a route between two random locations, reload if it does not", sectionTitle: "Getting Started"),
        Demo(controllerClass: SearchLocation.self, title: "Search a Location", description: "This demo lets you search and select an MPLocation", sectionTitle: "Getting Started"),
        Demo(controllerClass: BasicLiveData.self, title: "Live Data", description: "Turn on live updates", sectionTitle: "Getting Started"),
        // Basic
        Demo(controllerClass: SelectionController.self, title: "Select/Show Content", description: "This demonstrates how to use API to select location, building, floor and venue", sectionTitle: "Basic"),
        Demo(controllerClass: ShowMultipleLocationsController.self, title: "Show Multiple Locations", description: "Set and apply filter to only show certain Locations.", sectionTitle: "Basic"),
        Demo(controllerClass: MapPadding.self, title: "Map Padding", description: "Adjust Map Padding", sectionTitle: "Basic"),
        Demo(controllerClass: LocationDetailsController.self, title: "Location Details", description: "This demo shows the details of a location", sectionTitle: "Basic"),
        // Intermediate
        Demo(controllerClass: ShowMyLocationController.self, title: "Show My Location", description: "Mock a position provider and show user location (blue dot) and set it's Display Rule to change it's default icon", sectionTitle: "Intermediate"),
        Demo(controllerClass: UseDelegatesController.self, title: "Custom Map Control Delegate", description: "Implement your own custom Map Control Delegate", sectionTitle: "Intermediate"),
        Demo(controllerClass: CustomInfoWindowController.self, title: "Custom Info Window", description: "Implement your own custom Info Window", sectionTitle: "Intermediate"),
        // Advanced: Directions
        Demo(controllerClass: ShowDirection.self, title: "Search Directions", description: "Search locations and render route between them. Also set stair preference. Note: only avoid stairs work for now...", sectionTitle: "Advanced: Directions"),
        Demo(controllerClass: DirectionsWithPadding.self, title: "Direction with padding", description: "Set padding for rendered route and select orientation", sectionTitle: "Advanced: Directions"),
        // Advanced: Display Rule
        Demo(controllerClass: ToggleLocationsVisibilityController.self, title: "Toggle Locations Visibility", description: "Set visibility via Display Rule. Change in code to not randomly select location. If everything disappears, reload.", sectionTitle: "Advanced: Display Rule"),
        Demo(controllerClass: ChangeDisplaySettingController.self, title: "Change Display Rule", description: "Set and change Locations Display Rule at runtime", sectionTitle: "Advanced: Display Rule"),
        // Advanced
        Demo(controllerClass: ClusteringController.self, title: "Clustering and Collisions", description: "Enable/Disable Clustering and Collisions at runtime and provide a custom icon for cluster", sectionTitle: "Advanced"),
        Demo(controllerClass: CustomFloorSelectorController.self, title: "Custom Floor Selector", description: "Provide your own custom floor selector, reload controller if no custom floor selector is visible", sectionTitle: "Advanced"),
        Demo(controllerClass: DatasetMapController.self, title: "Dataset/Cache", description: "Demo on MapsIndoors cache", sectionTitle: "Advanced"),
        Demo(controllerClass: IndoorPositioning.self, title: "Indoor Positioning", description: "Indoor positioning/my location/blue dot", sectionTitle: "Advanced"),
        Demo(controllerClass: SolutionSwitchController.self, title: "Solution Switch", description: "Switch a MapsIndoors solution at runtime", sectionTitle: "Advanced"),
    ]
}

private extension DemoSelectorViewController {
    
    func displayNameFor(demo: Demo) -> String {
        return demo.title
    }
}

extension DemoSelectorViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredDemos = demos.filter { demo in
                return demo.title.lowercased().contains(searchText.lowercased())
            }
        } else {
            filteredDemos = demos
        }
        // Update sectionTitles based on filteredDemos
        sectionTitles = Array(Set(filteredDemos.map { $0.sectionTitle })).sorted {
            switch ($0, $1) {
            case ("Getting Started", _): return true
            case (_, "Getting Started"): return false
            case ("Basic", _): return true
            case (_, "Basic"): return false
            case ("Intermediate", _): return true
            case (_, "Intermediate"): return false
            case ("Advanced", _): return true
            case (_, "Advanced"): return false
            default: return $0 < $1
            }
        }
        // Update filteredDemos in dataSource and delegate
        dataSource.filteredDemos = filteredDemos
        demoTableViewDelegate.filteredDemos = filteredDemos
        tableView.reloadData()
    }
}

extension DemoSelectorViewController: MemoryAndZoomUIDelegate {
    func didTapSettingsButton() {
        openSettings()
    }
    
    @objc func openSettings() {
        let controller = storyboard?.instantiateViewController(identifier: "settings") as! SettingsController
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        controller.MBMapView = mapView
        controller.gMapView = googleMap
        setupGestureRecognizer(for: navigationController.view)
        present(navigationController, animated: true, completion: nil)
    }
    
    // This handlePanGesture is used for the slide up effect on the settings view controller. It is found multible places on Stack Overflow...
    
    func setupGestureRecognizer(for view: UIView) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let navigationController = presentedViewController as? UINavigationController else {
            return
        }
        
        let translation = gestureRecognizer.translation(in: navigationController.view)
        let screenHeight = navigationController.view.bounds.height
        
        switch gestureRecognizer.state {
        case .began:
            navigationController.view.tag = Int(translation.y)
            dismiss(animated: true, completion: nil)
            
        case .changed:
            let progress = 1 - (translation.y / screenHeight)
            
            let boundedProgress = min(max(progress, 0), 1)
            
            let newHeight = (screenHeight * 2 / 3) + (screenHeight * boundedProgress / 3)
            navigationController.view.frame.size.height = newHeight
            
        case .ended:
            
            let velocity = gestureRecognizer.velocity(in: navigationController.view)
            let hasPassedDismissalThreshold = translation.y > (screenHeight / 3) || velocity.y > 500
            
            if hasPassedDismissalThreshold {
                
                dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.2) {
                    navigationController.view.frame.size.height = screenHeight
                }
            }
            
        default:
            break
        }
    }
}

extension DemoSelectorViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        memoryAndZoomUI.isHidden = true
        memoryAndZoomUI.isUserInteractionEnabled = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        memoryAndZoomUI.isHidden = false
        memoryAndZoomUI.isUserInteractionEnabled = true
    }
}

extension DemoSelectorViewController: DemoTableViewDelegateCallback {
    func didSelectCell() {
        memoryAndZoomUI.isHidden = false
        memoryAndZoomUI.isUserInteractionEnabled = true
    }
}

struct Demo {
    let controllerClass: UIViewController.Type
    let title: String
    let description: String
    let sectionTitle: String
}
