import Foundation
import UIKit
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
        if sideMenu != nil {
            sideMenu.isHidden = true
            menuButton.isHidden = true
            dropdownTable.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await setupUI()
            await setupMap()
            await loadMapsIndoors()
        }
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
    
    fileprivate func setupUI() async {
        startLoadingUI()
    }
    
    fileprivate func setupMap() async {
        DispatchQueue.main.async {
            self.map = MapEngine.selectedMapView
            // Add the map view as a subview instead of replacing the entire view
            self.view.addSubview(self.map!)
            self.map?.frame = self.view.bounds
            
            // Bring the activity indicator and loading label to the front of the view hierarchy
            self.view.bringSubviewToFront(self.activityIndicator)
            self.view.bringSubviewToFront(self.loadingLabel)
        }
    }
    
    fileprivate func loadMapsIndoors() async {
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
            UserDefaults.standard.set("Failed to load MapsIndoors: \(error.localizedDescription)", forKey: "MapsIndoorsError")
            navigationController?.popViewController(animated: true)
        }
    }
    
    func startLoadingUI() {
        DispatchQueue.main.async {
            self.activityIndicator = self.createActivityIndicator()
            self.loadingLabel = self.createLoadingLabel()
            
            // Add the activity indicator to the view and center it
            self.view.addSubview(self.activityIndicator)
            NSLayoutConstraint.activate([
                self.activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            ])
            
            // Add the loading label to the view and position it below the activity indicator
            self.view.addSubview(self.loadingLabel)
            NSLayoutConstraint.activate([
                self.loadingLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.loadingLabel.topAnchor.constraint(equalTo: self.activityIndicator.bottomAnchor, constant: 20)
            ])
            
            // Start the activity indicator
            self.activityIndicator.startAnimating()
        }
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
        DispatchQueue.main.async {
            self.menuButton = UIButton(type: .system)
            self.menuButton.setImage(UIImage(systemName: "list.dash"), for: .normal)
            self.menuButton.tintColor = .black
            self.menuButton.backgroundColor = .systemYellow
            self.menuButton.frame = CGRect(x: 10, y: 160, width: 50, height: 50)
            self.menuButton.addTarget(self, action: #selector(self.toggleSideMenu), for: .touchUpInside)
            self.view.addSubview(self.menuButton)
        }
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
        DispatchQueue.main.async {
            let menuWidth: CGFloat = 200
            let menuHeight: CGFloat = self.view.bounds.height
            
            self.sideMenu = UIView(frame: CGRect(x: -menuWidth, y: 0, width: menuWidth, height: menuHeight))
            self.sideMenu.backgroundColor = .systemTeal
            
            // Add the menu to the view
            self.view.addSubview(self.sideMenu)
        }
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
        DispatchQueue.main.async {
            let padding: CGFloat = 210  // Padding for menuButton
            
            self.dropdownDataSource = DropdownDataSource { [weak self] choice in
                Task {
                    guard let self = self else { return }
                    
                    self.prefferdOfficeBuildingID = choice
                    self.currentBuilding = await MPMapsIndoors.shared.buildingWith(id: choice)
                    
                    await self.moveCameraToBuilding()
                    self.hideSideMenu()
                }
            }
            
            self.dropdownTable = UITableView(frame: CGRect(x: self.sideMenu.bounds.origin.x, y: padding, width: self.sideMenu.bounds.width, height: self.sideMenu.bounds.height - padding), style: .plain)
            self.dropdownTable.delegate = self.dropdownDataSource
            self.dropdownTable.dataSource = self.dropdownDataSource
            self.dropdownTable.register(UITableViewCell.self, forCellReuseIdentifier: "DropdownCell")
            self.sideMenu.addSubview(self.dropdownTable)
        }
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
        
        DispatchQueue.main.async {
            self.dropdownDataSource.venuesWithBuildings = venuesWithBuildings
            self.dropdownTable.reloadData()
        }
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
