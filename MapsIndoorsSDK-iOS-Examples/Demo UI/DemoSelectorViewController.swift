//
//  DemoSelectorViewController.swift
//  MapsIndoorsSDK-iOS-Examples
//
//  Created by M. Faizan Satti on 24/08/2023.
//

import UIKit
import GoogleMaps
import MapboxMaps
import MapsIndoorsCore
import MapsIndoors
import MapsIndoorsGoogleMaps
import MapsIndoorsMapbox

class DemoSelectorViewController: UITableViewController {
    
    var googleMap: GMSMapView? = nil
    var mapView: MapView? = nil
    var APIKey: String?
    var selectedMapProvider: Int?
    @IBOutlet weak var mapProviderSegmentedControl: UISegmentedControl!
    static var isGoogleMapsInitialized = false
    
    var searchController: UISearchController!
    var filteredDemos: [Demo] = []
    
    var sectionTitles: [String] = []
    
    var dataSource: DemoTableViewDataSource!
    var delegate: DemoTableViewDelegate!
    
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
        delegate = DemoTableViewDelegate(demos: demos, sectionTitles: sectionTitles, filteredDemos: filteredDemos, navigationController: navigationController)
        
        tableView.dataSource = dataSource
        tableView.delegate = delegate
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
            setupGoogleMaps()
        case 1:
            setupMapBox()
        default:
            print("Invalid map provider index")
        }
    }
    
    private func setupGoogleMaps() {
        if !DemoSelectorViewController.isGoogleMapsInitialized {
            GMSServices.provideAPIKey(APIKeys.googleMapsAPIKey)
            DemoSelectorViewController.isGoogleMapsInitialized = true
        }
        self.googleMap = GMSMapView(frame: CGRect.zero)
        MapEngine.selectedMapView = googleMap
        MapEngine.APIKey = APIKey!
        MapEngine.selectedMapProvider = GoogleMapsWrapper(GMMapView: googleMap!)
        MapEngine.selectedMapConfig = MPMapConfig(gmsMapView: googleMap!, googleApiKey: APIKeys.googleMapsAPIKey)
        print("Google is selected")
    }
    
    private func setupMapBox() {
        let myResourceOptions = ResourceOptions(accessToken: APIKeys.mapboxAPIKey)
        let styleURI: StyleURI = isDarkModeEnabled() ? .dark : .light
        let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions, styleURI: styleURI)
        self.mapView = MapView(frame: view.bounds, mapInitOptions: myMapInitOptions)
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
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func setupMemoryAndZoomUI() {
        let window = UIApplication.shared.keyWindow
        window?.addSubview(MemoryAndZoom())
        reportMemoryUsage()
        reportZoom()
    }
    
    @objc func reportMemoryUsage() -> Void {
        firstLabel.text = Memory.formattedMemoryFootprint()
        self.perform(#selector(reportMemoryUsage), with: nil, afterDelay: 1)
    }
    
    @objc func reportZoom() {
        secondLabel.text = String(format: "%.2f", MapEngine.selectedMapProvider?.zoom ?? 99)
        self.perform(#selector(reportZoom), with: nil, afterDelay: 0.01)
    }
    
    let memoryLabel = UILabel()
    let firstImageView = UIImageView()
    let firstLabel = UILabel()
    let secondImageView = UIImageView()
    let secondLabel = UILabel()
    let settingsButton = UIButton(type: .custom)
    
    func MemoryAndZoom() -> UIView {
        let window = UIView(frame: CGRect(x: 230, y: 65, width: 150, height: 20))
        
        secondImageView.translatesAutoresizingMaskIntoConstraints = false
        secondImageView.contentMode = .scaleAspectFit
        secondImageView.accessibilityIdentifier = "plusGlass"
        secondImageView.image = UIImage(systemName: "plus.magnifyingglass")
        window.addSubview(secondImageView)
        
        secondLabel.translatesAutoresizingMaskIntoConstraints = false
        secondLabel.accessibilityIdentifier = "Zoom"
        secondLabel.font = UIFont.boldSystemFont(ofSize: 14)
        window.addSubview(secondLabel)
        
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.accessibilityIdentifier = "gear"
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        window.addSubview(settingsButton)
        
        NSLayoutConstraint.activate([
            settingsButton.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: window.centerYAnchor),
            settingsButton.heightAnchor.constraint(equalTo: window.heightAnchor),
            settingsButton.widthAnchor.constraint(equalTo: settingsButton.heightAnchor),
            
            secondImageView.leadingAnchor.constraint(equalTo: settingsButton.trailingAnchor, constant: 3),
            secondImageView.centerYAnchor.constraint(equalTo: window.centerYAnchor),
            secondImageView.heightAnchor.constraint(equalTo: window.heightAnchor),
            secondImageView.widthAnchor.constraint(equalTo: secondImageView.heightAnchor),
            
            secondLabel.leadingAnchor.constraint(equalTo: secondImageView.trailingAnchor, constant: 3),
            secondLabel.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            secondLabel.centerYAnchor.constraint(equalTo: window.centerYAnchor)
        ])
        
        return window
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
    
    /*let demoControllerClasses:[UIViewController.Type] = [
                                                          //AdvancedDirectionsController.self, //WIP
                                                          MapStyleController.self,
                                                          MultipleDatasetsController.self,
                                                          SearchMapController.self,
                                                          OfflineController.self,
                                                          LocationSourcesController.self,
                                                          AppUserRolesController.self,
                                                          LiveDataController.self,
                                                          BookableLocationsController.self,
    ]*/
    
    let demos: [Demo] = [
        // Getting Started
        Demo(controllerClass: DisplayMap.self, title: "Display Map", description: "This demo simply displays map with MapsIndoors content", sectionTitle: "Getting Started"),
        /*Demo(controllerClass: BasicDirection.self, title: "Render Route", description: "This demo renders a route between two random locations, reload if it does not", sectionTitle: "Getting Started"),
        Demo(controllerClass: SearchLocation.self, title: "Search a Location", description: "This demo lets you search and select an MPLocation", sectionTitle: "Getting Started"),
        Demo(controllerClass: BasicLiveData.self, title: "Live Data", description: "Turn on live updates", sectionTitle: "Getting Started"),
        // Basic
        Demo(controllerClass: ShowLocationController.self, title: "Select Location", description: "This demo selects a random Location", sectionTitle: "Basic"),
        Demo(controllerClass: ShowMultipleLocationsController.self, title: "Show Multiple Locations", description: "Set and apply filter to only show certain Locations.", sectionTitle: "Basic"),
        Demo(controllerClass: ShowVenueController.self, title: "Select Venue", description: "This demo selects a random Venue in your solution", sectionTitle: "Basic"),
        Demo(controllerClass: ShowBuildingController.self, title: "Select Building", description: "This demo selects a random Building", sectionTitle: "Basic"),
        Demo(controllerClass: ShowFloorController.self, title: "Select Floor", description: "This demo selects a random floor", sectionTitle: "Basic"),
        Demo(controllerClass: MapPadding.self, title: "Map Padding", description: "Adjust Map Padding", sectionTitle: "Basic"),
        Demo(controllerClass: LocationDetailsController.self, title: "Location Details", description: "This demo shows the details of a location", sectionTitle: "Basic"),
        // Intermediate
        Demo(controllerClass: ShowMyLocationController.self, title: "Show My Location", description: "Mock a position provider and show user location (blue dot) and set it's Display Rule to change it's default icon", sectionTitle: "Intermediate"),
        Demo(controllerClass: UseDelegatesController.self, title: "Custom Map Control Delegate", description: "Implement your own custom Map Control Delegate", sectionTitle: "Intermediate"),
        Demo(controllerClass: CustomInfoWindowController.self, title: "Custom Info Window", description: "Implement your own custom Info Window", sectionTitle: "Intermediate"),
        Demo(controllerClass: MapStyleController.self, title: "Map Style", description: "Switch Map style at runtime", sectionTitle: "Intermediate"),
        Demo(controllerClass: MultipleDatasetsController.self, title: "Multiple Datasets", description: "Switch and load Multiple Datasets", sectionTitle: "Intermediate"),
        // Advanced: Directions
        Demo(controllerClass: ShowDirection.self, title: "Search Directions", description: "Search locations and render route between them. Also set stair preference. Note: only avoid stairs work for now...", sectionTitle: "Advanced: Directions"),
        Demo(controllerClass: DirectionsWithPadding.self, title: "Direction with padding", description: "Set padding for rendered route and select orientation", sectionTitle: "Advanced: Directions"),
        // Advanced
        Demo(controllerClass: ClusteringController.self, title: "Clustering/Collisions", description: "Enable/Disable Clustering at runtime and provide a custom icon", sectionTitle: "Advanced"),
        Demo(controllerClass: LiveData.self, title: "Live data and delegate", description: "Enable live data and implement delegate", sectionTitle: "Advanced"),
        Demo(controllerClass: ToggleLocationsVisibilityController.self, title: "Toggle Locations Visibility", description: "Set visibility via Display Rule. Change in code to not randomly select location. If everything disappears, reload.", sectionTitle: "Advanced: Display Rule"),
        Demo(controllerClass: ChangeDisplaySettingController.self, title: "Change Display Rule", description: "Set and change Locations Display Rule at runtime", sectionTitle: "Advanced: Display Rule"),
        Demo(controllerClass: CustomFloorSelectorController.self, title: "Custom Floor Selector", description: "Provide your own custom floor selector, reload controller if no custom floor selector is visible", sectionTitle: "Advanced"),
        Demo(controllerClass: BookableLocationsController.self, title: "Location Booking", description: "View and book MPLocation", sectionTitle: "Advanced"),
        Demo(controllerClass: DatasetMapController.self, title: "Dataset/Cache", description: "Demo on MapsIndoors cache", sectionTitle: "Advanced"),*/
        //Demo(controllerClass: PerVenueController.self, title: "Mega Solutions", description: "Per venue loading", sectionTitle: "Advanced"),
        //Demo(controllerClass: ChnageLanguage.self, title: "Change Language", description: "Chnage MP language and app language via localizable string, sectionTitle: "Intermediate"),
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
        delegate.filteredDemos = filteredDemos
        tableView.reloadData()
    }
}

struct Demo {
    let controllerClass: UIViewController.Type
    let title: String
    let description: String
    let sectionTitle: String
}

class DemoTableViewDataSource: NSObject, UITableViewDataSource {
    var demos: [Demo]
    var sectionTitles: [String]
    var filteredDemos: [Demo]
    
    init(demos: [Demo], sectionTitles: [String], filteredDemos: [Demo]) {
        self.demos = demos
        self.sectionTitles = sectionTitles
        self.filteredDemos = filteredDemos
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = sectionTitles[section]
        return filteredDemos.filter { $0.sectionTitle == sectionTitle }.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoTableViewCell", for: indexPath)
        let sectionTitle = sectionTitles[indexPath.section]
        let demosInSection = filteredDemos.filter { $0.sectionTitle == sectionTitle }
        let demo = demosInSection[indexPath.row]
        cell.textLabel?.text = demo.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        cell.detailTextLabel?.text = demo.description
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessibilityIdentifier = cell.textLabel?.text
        return cell
    }
}

class DemoTableViewDelegate: NSObject, UITableViewDelegate {
    var demos: [Demo]
    var sectionTitles: [String]
    var filteredDemos: [Demo]
    weak var navigationController: UINavigationController?
    
    init(demos: [Demo], sectionTitles: [String], filteredDemos: [Demo], navigationController: UINavigationController?) {
        self.demos = demos
        self.sectionTitles = sectionTitles
        self.filteredDemos = filteredDemos
        self.navigationController = navigationController
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionTitle = sectionTitles[indexPath.section]
        let demosInSection = filteredDemos.filter { $0.sectionTitle == sectionTitle }
        let vc = demosInSection[indexPath.row].controllerClass.init()
        navigationController?.pushViewController(vc, animated: true)
    }
}

