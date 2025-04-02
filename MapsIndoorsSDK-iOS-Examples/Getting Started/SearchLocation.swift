import Foundation
import MapsIndoors
import MapsIndoorsCore
import UIKit

class SearchLocation: BaseMapController {
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private var locations = [MPLocation]()

    override func setupController() async {
        setupUI()
    }

    func setupUI() {
        setupSearchBar()
        setupTableView()
    }

    func setupSearchBar() {
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.barTintColor = UIColor(red: 35 / 255, green: 85 / 255, blue: 84 / 255, alpha: 0.7)
        searchBar.searchTextField.textColor = .white
        searchBar.searchTextField.backgroundColor = UIColor(red: 75 / 255, green: 125 / 255, blue: 124 / 255, alpha: 0.3)
        searchBar.searchTextField.layer.cornerRadius = 8
        searchBar.searchTextField.clipsToBounds = true
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        let screenWidth = UIScreen.main.bounds.width
        let searchBarWidth = screenWidth * 0.9  // 90% of screen

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

    override func adjustUI(forMenu: Bool) {
        searchBar.isHidden = forMenu
    }
}

extension SearchLocation: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // This method is called whenever the text in the search bar changes
        // You can search with MapsIndoors using the search text
        if searchText.isEmpty {
            tableView.isHidden = true  // Hide the table view when there's no text
        } else {
            Task {
                let query = MPQuery()
                query.query = searchText.lowercased()
                locations = await MPMapsIndoors.shared.locationsWith(query: query, filter: nil)
                tableView.isHidden = locations.isEmpty  // Hide the table view when there are no results
                tableView.reloadData()
            }
        }
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
        let selectedLocation = locations[indexPath.row]
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
        return locations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Use `subtitle` style
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")

        let location = locations[indexPath.row]
        Task {
            let venue = await MPMapsIndoors.shared.venues().first { $0.administrativeId?.lowercased() == location.venue?.lowercased() }
            let building = await MPMapsIndoors.shared.buildings().first { $0.administrativeId?.lowercased() == location.building?.lowercased() }

            var c = cell.defaultContentConfiguration()
            // Set the text label to the location's name
            c.text = location.name
            // Set the detail text label to the location's floor
            c.secondaryText = "Venue: \(venue?.name ?? "")\nBuilding: \(building?.name ?? "")\nFloor: \(location.floorName)"
            c.image = nil
            c.image = await getImage(for: location)
            cell.contentConfiguration = c
        }

        return cell
    }

    private func getImage(for location: MPLocation) async -> UIImage? {
        do {
            let (image, _) = try await fetchImage(from: location)
            return image
        } catch {
            print("Error loading image: \(error)")
        }
        return nil
    }
}
