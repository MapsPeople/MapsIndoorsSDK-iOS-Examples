import Foundation
import MapsIndoorsCore
import MapsIndoors

class BaseMapController: UIViewController {
    
    var map: UIView? = nil
    var mapControl: MPMapControl? = nil
    
    var currentBuilding: MPBuilding? {
        didSet {
            updateForBuildingChange()
        }
    }
    
    var prefferdOfficeBuildingID = "Stigsborgvej" // Preference for `moveCameraToBuilding` to select, change this to your building's `administrativeId` to focus on it instead
    
    var activityIndicator: UIActivityIndicatorView!
    var loadingLabel: UILabel!
    
    var dropdownDataSource: DropdownDataSource!
    
    var sideMenu: UIView!
    var menuButton: UIButton!
    var dropdownTable: UITableView!
    
    // To hide side panel when going back to Demo selection
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sideMenu.isHidden = true
        menuButton.isHidden = true
        dropdownTable.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupMap()
        loadMapsIndoors()
    }
    
    /// This function can be overridden by subclasses to provide specific behavior. Default implementation selects `prefferdOfficeBuildingID` or a random building
    func moveCameraToBuilding() async {
        let allBuildings = await MPMapsIndoors.shared.buildings()
        if let building = allBuildings.first(where: {$0.administrativeId == prefferdOfficeBuildingID }) {
            currentBuilding = building
            mapControl?.select(building: building, behavior: .default)
        } else {
            if let building = allBuildings.first{
                currentBuilding = building
                mapControl?.select(building: building, behavior: .default)
            }
        }
    }
    
    /// This function should be overridden by subclasses to provide starting specific behavior, default implementation does nothing
    func setupController() async {
    }
    
    /// This function is intended to be overridden by subclasses to update content like Locations if current building changes
    func updateForBuildingChange() {
    }
    /// intended to be overridden if subclass has UI elements that may overlap with the BaseMapController class UI
    func adjustUI(forMenu: Bool) {
        // Base implementation does nothing for now...
    }
    
    fileprivate func createActivityIndicator() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = UIColor(red: 35/255, green: 85/255, blue: 84/255, alpha: 1.0)
        return indicator
    }
    
    fileprivate func createLoadingLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Loading MapsIndoors..."
        label.textColor = UIColor(red: 35/255, green: 85/255, blue: 84/255, alpha: 1.0)
        label.shadowColor = .systemTeal
        return label
    }
    
    fileprivate func setupUI() {
        startLoadingUI()
    }
    
    fileprivate func setupMap() {
        self.map = MapEngine.selectedMapView
        // Add the map view as a subview instead of replacing the entire view
        self.view.addSubview(self.map!)
        self.map?.frame = self.view.bounds
        
        // Bring the activity indicator and loading label to the front of the view hierarchy
        self.view.bringSubviewToFront(activityIndicator)
        self.view.bringSubviewToFront(loadingLabel)
    }
    
    fileprivate func loadMapsIndoors() {
        Task {
            do {
                try await loadMapsIndoorsSDK()
                mapControl = MPMapsIndoors.createMapControl(mapConfig: MapEngine.selectedMapConfig!)
                await setupSideMenu()
                setupMenuButton()
                await moveCameraToBuilding()
                performPostLoadingActions()
                await setupController()
            } catch {
                print("Failed to load MapsIndoors: \(error.localizedDescription)")
            }
        }
    }
    
    func startLoadingUI() {
        activityIndicator = createActivityIndicator()
        loadingLabel = createLoadingLabel()
        
        // Add the activity indicator to the view and center it
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add the loading label to the view and position it below the activity indicator
        view.addSubview(loadingLabel)
        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20)
        ])
        
        // Start the activity indicator
        activityIndicator.startAnimating()
    }
    
    func stopLoadingUI() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
            self.loadingLabel.isHidden = true
        }
    }
    
    func loadMapsIndoorsSDK() async throws {
        try await MPMapsIndoors.shared.load(apiKey: MapEngine.APIKey!)
        if !MPMapsIndoors.shared.ready {
            try await MPMapsIndoors.shared.synchronize()
        }
    }
    
    fileprivate func performPostLoadingActions() {
        stopLoadingUI()
    }
    
    fileprivate func setupMenuButton() {
        menuButton = UIButton(type: .system)
        menuButton.setImage(UIImage(systemName: "list.dash"), for: .normal)
        menuButton.tintColor = .black
        menuButton.backgroundColor = .systemYellow
        menuButton.frame = CGRect(x: 10, y: 160, width: 50, height: 50)
        menuButton.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        view.addSubview(menuButton)
    }

    @objc func toggleSideMenu() {
        if sideMenu.frame.origin.x < 0 {
            showSideMenu()
            adjustUI(forMenu: true)
        } else {
            hideSideMenu()
            adjustUI(forMenu: false)
        }
    }
    
    fileprivate func setupSideMenu() async {
        let menuWidth: CGFloat = 200
        let menuHeight: CGFloat = view.bounds.height
        
        sideMenu = UIView(frame: CGRect(x: -menuWidth, y: 0, width: menuWidth, height: menuHeight))
        sideMenu.backgroundColor = .systemTeal
        
        // Add the menu to the view
        view.addSubview(sideMenu)
        setupDropdownTable()
        await populateDropdownTable()
    }
    
    func showSideMenu() {
        UIView.animate(withDuration: 0.3) {
            self.sideMenu.frame.origin.x = 0
        }
    }
    
    func hideSideMenu() {
        UIView.animate(withDuration: 0.3) {
            self.sideMenu.frame.origin.x = -self.sideMenu.bounds.width
        }
    }
    
    fileprivate func setupDropdownTable() {
        let padding: CGFloat = 210  // Padding for menuButton
        
        dropdownDataSource = DropdownDataSource { [weak self] choice in
            Task {
                guard let self = self else { return }
                
                self.prefferdOfficeBuildingID = choice
                self.currentBuilding = await MPMapsIndoors.shared.buildingWith(id: choice)
                
                await self.moveCameraToBuilding()
                self.hideSideMenu()
            }
        }
        
        dropdownTable = UITableView(frame: CGRect(x: sideMenu.bounds.origin.x, y: padding, width: sideMenu.bounds.width, height: sideMenu.bounds.height - padding), style: .plain)
        dropdownTable.delegate = dropdownDataSource
        dropdownTable.dataSource = dropdownDataSource
        dropdownTable.register(UITableViewCell.self, forCellReuseIdentifier: "DropdownCell")
        sideMenu.addSubview(dropdownTable)
    }
    
    func populateDropdownTable() async {
        let buildings = await MPMapsIndoors.shared.buildings()
        
        var venuesWithBuildings: [VenueWithBuildings] = []
        
        for building in buildings {
            if let venueId = building.venueId, let venue = await MPMapsIndoors.shared.venueWith(id: venueId) {
                if let index = venuesWithBuildings.firstIndex(where: { $0.venue.venueId == venueId }) {
                    venuesWithBuildings[index].buildings.append(building)
                } else {
                    venuesWithBuildings.append(VenueWithBuildings(venue: venue, buildings: [building]))
                }
            }
        }
        dropdownDataSource.venuesWithBuildings = venuesWithBuildings
        dropdownTable.reloadData()
    }
}

// extension for convenience methods
extension BaseMapController {
    // Convenience function to get a random location in the same "selected" building
    func getRandomLocation() async -> MPLocation? {
        let allLocations = await MPMapsIndoors.shared.locationsWith(query: MPQuery(), filter: MPFilter())
        if let validBuilding = currentBuilding {
            let locationInSelectedBuilding = allLocations.filter({ $0.building == validBuilding.administrativeId })
            return locationInSelectedBuilding.randomElement()
        }
        return nil
    }
    
    // Convenience function to fetch image/icon for an MPLocation using ´imageProvider´
    func fetchImage(from location: MPLocation, size: CGSize = CGSize(width: 15, height: 15)) async throws -> (UIImage?, String?) {
        var image: UIImage?
        var url: String?
        
        // Set the image view to the location's icon, if it exists
        // If it doesn't exist, try to load the image from `iconUrl` or `imageURL`
        if let icon = location.icon {
            image = icon
        } else if let iconUrl = location.iconUrl?.absoluteString {
            image = try await MPMapsIndoors.shared.imageProvider.imageFrom(urlString: iconUrl, imageSize: size)
            url = iconUrl
        } else if let imageURL = location.imageURL {
            image = try await MPMapsIndoors.shared.imageProvider.imageFrom(urlString: imageURL, imageSize: size)
            url = imageURL
        }
        return (image, url)
    }
}

typealias SelectionHandler = (String) -> Task<Void, Error>

class DropdownDataSource: NSObject, UITableViewDelegate, UITableViewDataSource {
    var venuesWithBuildings: [VenueWithBuildings] = []
    var selectionHandler: SelectionHandler?
    
    // Initialize with a selection handler
    init(selectionHandler: @escaping SelectionHandler) {
        self.selectionHandler = selectionHandler
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return venuesWithBuildings.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return venuesWithBuildings[section].venue.name
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venuesWithBuildings[section].buildings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropdownCell", for: indexPath)
        let building = venuesWithBuildings[indexPath.section].buildings[indexPath.row]
        cell.textLabel?.text = building.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBuilding = venuesWithBuildings[indexPath.section].buildings[indexPath.row]
        if let adminId = selectedBuilding.administrativeId {
            Task {
                selectionHandler?(adminId)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

struct VenueWithBuildings {
    let venue: MPVenue
    var buildings: [MPBuilding]
}
