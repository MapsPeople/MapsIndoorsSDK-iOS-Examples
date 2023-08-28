import Foundation
import UIKit
import MapsIndoorsCore
import MapsIndoors

class SearchLocation: BaseMapController {
    fileprivate let searchBar = UISearchBar()
    fileprivate let tableView = UITableView()
    fileprivate var locations: [MPLocation] = []
    fileprivate var filteredLocations: [MPLocation] = []
    
    override func setupController() async {
        setupUI()
        await loadLocations()
    }
    
    func setupUI() {
        setupSearchBar()
        setupTableView()
    }
    
    func setupSearchBar() {
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.barTintColor = UIColor(red: 35/255, green: 85/255, blue: 84/255, alpha: 0.7)
        searchBar.searchTextField.textColor = .white
        searchBar.searchTextField.backgroundColor = UIColor(red: 75/255, green: 125/255, blue: 124/255, alpha: 0.3)
        searchBar.searchTextField.layer.cornerRadius = 8
        searchBar.searchTextField.clipsToBounds = true
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        let screenWidth = UIScreen.main.bounds.width
        let searchBarWidth = screenWidth * 0.9 // 90% of screen
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBar.widthAnchor.constraint(equalToConstant: searchBarWidth),
        ])
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func loadLocations() async {
        locations = await LocationLoader.loadLocations(building: currentBuilding)
        filteredLocations = locations
    }
    
    override func updateForBuildingChange() {
        Task {
            locations = await LocationLoader.loadLocations(building: currentBuilding)
            searchBar.isHidden = false
        }
    }
    
    override func adjustUI(forMenu: Bool) {
        searchBar.isHidden = forMenu
    }
}

extension SearchLocation: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // This method is called whenever the text in the search bar changes
        // You can filter your locations here based on the search text
        if searchText.isEmpty {
            filteredLocations = locations
            tableView.isHidden = true // Hide the table view when there's no text
        } else {
            filteredLocations = locations.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            tableView.isHidden = filteredLocations.isEmpty // Hide the table view when there are no results
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // This method is called when the user clicks the search button on the keyboard
        // You can start your search here
        print("Search button clicked with text: \(searchBar.text ?? "")")
        searchBar.resignFirstResponder()
        tableView.isHidden = true
    }
}

extension SearchLocation: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // This method is called when the user selects a row in the table view
        // You can perform your action here
        let selectedLocation = filteredLocations[indexPath.row]
        print("Selected location: \(selectedLocation.name)")
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
        tableView.isHidden = true
        // Select the location
        mapControl?.select(location: selectedLocation, behavior: .default)
    }
}

extension SearchLocation: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // Use `subtitle` style
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        let location = filteredLocations[indexPath.row]
        
        // Set the text label to the location's name
        cell.textLabel?.text = location.name
        
        // Set the detail text label to the location's floor
        cell.detailTextLabel?.text = "Floor: \(location.floorName)"
        
        // Initially set the imageView's image to nil to avoid displaying incorrect recycled images
        cell.imageView?.image = nil
        
        loadImage(for: location, at: indexPath, in: tableView)
        
        return cell
    }
    
    private func loadImage(for location: MPLocation, at indexPath: IndexPath, in tableView: UITableView) {
        Task {
            do {
                let (image, url) = try await fetchImage(from: location)
                
                // Update the UI on the main thread
                DispatchQueue.main.async {
                    // Ensure that the cell is being displayed for the data it was loaded for
                    if let cell = tableView.cellForRow(at: indexPath),
                       let currentUrl = self.filteredLocations[indexPath.row].iconUrl?.absoluteString ?? self.filteredLocations[indexPath.row].imageURL,
                       currentUrl == url {
                        cell.imageView?.image = image
                        cell.setNeedsLayout()
                    }
                }
            } catch {
                print("Error loading image: \(error)")
            }
        }
    }
}

class LocationLoader {
    static func loadLocations(building: MPBuilding?) async -> [MPLocation] {
        if let selectedBuilding = building {
            return await MPMapsIndoors.shared.locationsWith(query: MPQuery(), filter: MPFilter()).filter({ $0.building == selectedBuilding.administrativeId })
        } else {
            return await MPMapsIndoors.shared.locationsWith(query: MPQuery(), filter: MPFilter())
        }
    }
}
