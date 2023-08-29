import UIKit
import MapsIndoorsCore
import MapsIndoors

class ShowDirection: BaseMapController, UISearchBarDelegate, MPMapControlDelegate {
    
    var directionsRenderer: MPDirectionsRenderer?
    var currentRoute: MPRoute?
    
    var origin: MPLocation? {
        didSet {
            if let destination = destination {
                generateRoute(to: destination)
            }
        }
    }

    var destination: MPLocation? {
        didSet {
            if destination != nil {
                generateRoute(to: destination!)
            }
        }
    }

    // To hold the floors that the route passes through
    var routeFloors: Set<Int> = []
    
    // Search Bar
    var searchResult: [MPLocation]?
    lazy var destinationSearch = UISearchBar(frame: CGRect(x: 0, y: 40, width: 0, height: 0))
    var tableView = UITableView(frame: CGRect(x: 0, y: 180, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
    
    // origin and destination labels
    let originLabel = UILabel()
    let destinationLabel = UILabel()

    // location label being edited
    var locationBeingEdited: String?
    
    // properties to store whether stairs and elevators should be avoided
    var shouldAvoidStairs: Bool = false
    var shouldAvoidElevators: Bool = false
    
    // stairs button
    let stairsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Avoid Stairs", for: .normal)
        button.setTitle("Avoiding Stairs", for: .selected)
        button.backgroundColor = UIColor(red: 75/255, green: 125/255, blue: 124/255, alpha: 0.4)
        button.addTarget(self, action: #selector(handleStairsButtonTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // elevator button
    let elevatorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Avoid Elevators", for: .normal)
        button.setTitle("Avoiding Elevators", for: .selected)
        button.backgroundColor = UIColor(red: 75/255, green: 125/255, blue: 124/255, alpha: 0.4)
        button.addTarget(self, action: #selector(handleElevatorButtonTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
  
    
    override func setupController() async {
        setupTapGesture()
        setupMapControlDelegate()
        setupSearchBar()
        setupTableView()
        setupLabels()
        setupButtons()
        await setupLocations()
    }
    
    // To dismiss search results when user taps outside the search bar and the table view
    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideSearch(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    func setupMapControlDelegate() {
        DispatchQueue.main.async {
            self.mapControl?.delegate = self
        }
    }
    
    func setupSearchBar() {
        destinationSearch.sizeToFit()
        destinationSearch.delegate = self
        destinationSearch.barTintColor = UIColor(red: 35/255, green: 85/255, blue: 84/255, alpha: 0.7)
        destinationSearch.searchTextField.textColor = .white
        destinationSearch.searchTextField.backgroundColor = UIColor(red: 75/255, green: 125/255, blue: 124/255, alpha: 0.3)
        destinationSearch.searchTextField.layer.cornerRadius = 8
        destinationSearch.searchTextField.clipsToBounds = true
        destinationSearch.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(destinationSearch)
        
        let screenWidth = UIScreen.main.bounds.width
        let searchBarWidth = screenWidth * 0.9 // 90% of screen
        
        NSLayoutConstraint.activate([
            destinationSearch.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            destinationSearch.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            destinationSearch.widthAnchor.constraint(equalToConstant: searchBarWidth),
        ])
    }
    
    func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func setupLabels() {
        // Configure the origin and destination labels
        originLabel.backgroundColor = UIColor(red: 75/255, green: 125/255, blue: 124/255, alpha: 0.4)
        destinationLabel.backgroundColor = UIColor(red: 75/255, green: 125/255, blue: 124/255, alpha: 0.4)
        originLabel.translatesAutoresizingMaskIntoConstraints = false
        destinationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let labelStackView = UIStackView(arrangedSubviews: [originLabel, destinationLabel])
        labelStackView.axis = .vertical
        labelStackView.distribution = .fillEqually
        labelStackView.spacing = 10
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelStackView)
        
        NSLayoutConstraint.activate([
            labelStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            labelStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
        ])
        
        // tap gesture recognizers to the labels
        let originTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap(_:)))
        let destinationTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap(_:)))
        originLabel.addGestureRecognizer(originTapGesture)
        destinationLabel.addGestureRecognizer(destinationTapGesture)
        originLabel.isUserInteractionEnabled = true
        destinationLabel.isUserInteractionEnabled = true
    }
    
    func setupButtons() {
        // Create a stack view
        let stackView = UIStackView(arrangedSubviews: [stairsButton, elevatorButton])
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
    
    func setupLocations() async {
        let query = MPQuery()
        let filter = MPFilter()
        filter.take = 1 // Take only one results

        // Set origin
        query.query = "Tokyo"
        origin = await getFirstLocation(query: query, filter: filter)
        if origin == nil {
            origin = await getRandomLocation()
        }

        // Set destination
        query.query = "Manaus"
        destination = await getFirstLocation(query: query, filter: filter)
        if destination == nil {
            destination = await getRandomLocation()
        }

        // Generate route
        if let destination = destination {
            generateRoute(to: destination)
        }
    }
    
    @objc func handleStairsButtonTap() {
        stairsButton.isSelected.toggle()
        shouldAvoidStairs = stairsButton.isSelected
        // Generate a new route when the button is tapped
        if let destination = destination {
            generateRoute(to: destination)
        }
    }
    
    @objc func handleElevatorButtonTap() {
        elevatorButton.isSelected.toggle()
        shouldAvoidElevators = elevatorButton.isSelected
        // Generate a new route when the button is tapped
        if let destination = destination {
            generateRoute(to: destination)
        }
    }
    
    func getFirstLocation(query: MPQuery, filter: MPFilter) async -> MPLocation? {
        let locations = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        return locations.first
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        view.addSubview(tableView)
        let query = MPQuery()
        let filter = MPFilter()
        query.query = searchText
        filter.take = 100 // Take 100 results
        Task {
            searchResult = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
            tableView.reloadData()
        }
    }
    
    func generateRoute(to destination: MPLocation) {
        guard let mapControl = mapControl, let validOriginLocation = origin else { return }
        if directionsRenderer == nil {
            directionsRenderer = mapControl.newDirectionsRenderer()
        }
        
        let directionsQuery = MPDirectionsQuery(origin: validOriginLocation, destination: destination)
        // Set avoidWayTypes if stairs or elevators should be avoided
        var avoidTypes: [MPHighway] = []
        if shouldAvoidStairs {
            avoidTypes.append(.stairs)
        }
        if shouldAvoidElevators {
            avoidTypes.append(.elevator)
        }
        directionsQuery.avoidWayTypes = avoidTypes
        
        Task {
            do {
                let route = try await MPMapsIndoors.shared.directionsService.routingWith(query: directionsQuery)
                self.currentRoute = route // Store the route
                directionsRenderer?.route = route
                directionsRenderer?.routeLegIndex = 0 // TODO: make this dynamic not 0 (first leg) all the time
                
                directionsRenderer?.animate(duration: 5)
                
                // Collect the floors that the route passes through
                routeFloors = []
                for leg in route!.legs {
                    routeFloors.insert(leg.start_location.zLevel.intValue)
                    routeFloors.insert(leg.end_location.zLevel.intValue)
                }
            } catch {
                print("Error getting directions: \(error.localizedDescription)")
            }
        }
        // Update the origin and destination labels
        originLabel.text = "Origin: \(origin?.name ?? "")"
        destinationLabel.text = "Destination: \(destination.name)"
    }
    
    @objc func handleTapOutsideSearch(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        if !destinationSearch.frame.contains(location) && !tableView.frame.contains(location) {
            destinationSearch.resignFirstResponder()
            tableView.removeFromSuperview()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.removeFromSuperview()
    }
    
    func didChange(floorIndex: Int) -> Bool {
        if routeFloors.contains(floorIndex) {
            // If the new floor index is one of the floors that the route passes through, re-set the route
            directionsRenderer?.route = currentRoute
            directionsRenderer?.animate(duration: 5)
        } else {
            // If the new floor index is not one of the floors that the route passes through, clear the route
            directionsRenderer?.clear()
        }
        return false
    }
    
    @objc func handleLabelTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.view === originLabel {
            locationBeingEdited = "origin"
        } else if gestureRecognizer.view === destinationLabel {
            locationBeingEdited = "destination"
        }
        destinationSearch.becomeFirstResponder()
    }
    
    override func adjustUI(forMenu: Bool) {
        destinationSearch.isHidden = forMenu
        originLabel.isHidden = forMenu
        destinationLabel.isHidden = forMenu
        stairsButton.isHidden = forMenu
        elevatorButton.isHidden = forMenu
    }
    
    override func updateForBuildingChange() {
        destinationSearch.isHidden = false
        originLabel.isHidden = false
        destinationLabel.isHidden = false
        stairsButton.isHidden = false
        elevatorButton.isHidden = false
    }
}

extension ShowDirection: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let location = searchResult?[indexPath.row] else { return }
        tableView.removeFromSuperview()
        if locationBeingEdited == "origin" {
            origin = location
            originLabel.text = "Origin: \(location.name)"
        } else {
            destination = location
            destinationLabel.text = "Destination: \(location.name)"
        }
        locationBeingEdited = nil
        destinationSearch.resignFirstResponder()
    }
}

extension ShowDirection: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResult?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // Use `subtitle` style
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        let location = searchResult?[indexPath.row]
        
        // Set the text label to the location's name
        cell.textLabel?.text = location?.name
        
        // Set the detail text label to the location's floor
        cell.detailTextLabel?.text = "Floor: \(location?.floorName ?? "N/A")"
        
        // Initially set the imageView's image to nil to avoid displaying incorrect recycled images
        cell.imageView?.image = nil
        
        if let validLocation = location {
            loadImage(for: validLocation, at: indexPath, in: tableView)
        }
        
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
                       let currentUrl = self.searchResult?[indexPath.row].iconUrl?.absoluteString ?? self.searchResult?[indexPath.row].imageURL,
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
