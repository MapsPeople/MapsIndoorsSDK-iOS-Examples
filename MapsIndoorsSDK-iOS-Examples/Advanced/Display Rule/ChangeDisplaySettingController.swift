import UIKit
import MapsIndoorsCore
import MapsIndoors

class ChangeDisplaySettingController: BaseMapController {
    
    var filterType1 = "Storage"
    var filterType2 = "Kitchen"
    
    // Create buttons
    var typeButton: UIButton!
    var locationButton: UIButton!
    var multipleButton: UIButton!

    var typeIcon: UIImage?
    
    var singleLocationIcon: UIImage?
    
    override func setupController() async {
        setupButtons()
    }
    
    func setupButtons() {
        typeButton = createButton(title: "Change for Type", selector: #selector(typeButtonTapped))
        locationButton = createButton(title: "Change Single Location", selector: #selector(locationButtonTapped))
        multipleButton = createButton(title: "Change Multiple Locations", selector: #selector(multipleButtonTapped))
        
        // Create a stack view
        let stackView = UIStackView(arrangedSubviews: [typeButton, locationButton, multipleButton])
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
    
    // Button actions
    @objc func typeButtonTapped() {
        Task {
            await toggleIconForType()
            
        }
    }
    
    @objc func locationButtonTapped() {
        Task {
            await changeLocations(for: [filterType1])
        }
        disableTypeButton()
    }
    
    @objc func multipleButtonTapped() {
        Task {
            await changeLocations(for: [filterType1, filterType2])
        }
        disableTypeButton()
    }
    
    func toggleIconForType() async {
        await moveNear(type: filterType1)
        await updateIconForType()
    }

    func updateIconForType() async {
        guard let disRul = MPMapsIndoors.shared.displayRuleFor(type: self.filterType1) else { return }
        
        if let validTypeImage = self.typeIcon {
            disRul.icon = (disRul.icon == validTypeImage) ? self.generateImage() : validTypeImage
        } else {
            await updateIconFromDisplayRule(disRul)
        }
        
        self.mapControl?.refresh()
    }

    func updateIconFromDisplayRule(_ disRul: MPDisplayRule) async{
        if let validIcon = disRul.icon {
            self.typeIcon = validIcon
            disRul.icon = self.generateImage()
        } else if let validUrl = disRul.iconURL {
            await updateIconFromURL(validUrl, iconSize: disRul.iconSize)
            disRul.icon = self.generateImage()
        }
    }

    func updateIconFromURL(_ url: URL, iconSize: CGSize) async {
        do {
            self.typeIcon = try await MPMapsIndoors.shared.imageProvider.imageFrom(urlString: url.absoluteString, imageSize: iconSize)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func disableTypeButton() {
        typeButton.isEnabled = false
        typeButton.setTitle("Disabled", for: .disabled)
        typeButton.backgroundColor = .systemGray
    }
    
    func changeLocations(for types: [String]) async {
        for type in types {
            // Select a location close to type to move the camera there
            await moveNear(type: type)
            
            let filter = MPFilter()
            let query = MPQuery()
            
            filter.types = [type]
            let locations = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
            for location in locations {
                await updateIconForLocation(location)
            }
        }
        mapControl?.refresh()
    }
    
    func updateIconForLocation(_ location: MPLocation) async {
        if let displayRule = MPMapsIndoors.shared.displayRuleFor(location: location) {
            if let disRuleIcon = displayRule.icon {
                displayRule.icon = (singleLocationIcon != disRuleIcon) ? singleLocationIcon : generateImage()
            } else if let disRuleIconURL = displayRule.iconURL {
                do {
                    self.singleLocationIcon = try await MPMapsIndoors.shared.imageProvider.imageFrom(urlString: disRuleIconURL.absoluteString, imageSize: displayRule.iconSize)
                    displayRule.icon = generateImage()
                } catch {
                    print(error.localizedDescription)
                }
            }
            MPMapsIndoors.shared.set(displayRule: displayRule, location: location)
        }
    }
    
    func createButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: selector, for: .touchUpInside)
        button.backgroundColor = UIColor(red: 35/255, green: 85/255, blue: 84/255, alpha: 0.7)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    func moveNear(type: String) async {
        let query = MPQuery()
        let filter = MPFilter()
        
        let allLocations = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        
        if let validBuilding = currentBuilding {
            let typeFilteredLocations = allLocations.filter({ $0.building == validBuilding.administrativeId && $0.type == type })
            if let focusLocation = typeFilteredLocations.first {
                if let centerCoordinate = focusLocation.coordinateBounds?.bounds.center.coordinate {
                    MapEngine.selectedMapProvider?.setCamera(coordinates: centerCoordinate, zoom: 21)
                    mapControl?.select(floorIndex: focusLocation.floorIndex.intValue)
                }
            }
        }
    }
    
    func generateImage() -> UIImage {
        let size = CGSize(width: 25, height: 25)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fillEllipse(in: rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
    
    override func adjustUI(forMenu: Bool) {
        typeButton.isHidden = forMenu
        locationButton.isHidden = forMenu
        multipleButton.isHidden = forMenu
    }
    
    override func updateForBuildingChange() {
        if typeButton != nil {
            typeButton.isHidden = false
            locationButton.isHidden = false
            multipleButton.isHidden = false
        }
    }
}
