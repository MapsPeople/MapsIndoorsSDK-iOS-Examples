import UIKit
import MapsIndoorsCore
import MapsIndoorsGoogleMaps

/***
 ---
 title: Show Location Details
 ---
 
 This is an example of displaying some details of a random MapsIndoors location
 
 Start by creating a  class that conforms to the `BaseMapController` UIViewController
 ***/
class LocationDetailsController: BaseMapController {
 
    var selectedLocation: MPLocation? = nil
    
    /***
     Add other views needed for this example
     ***/
    var detailsView:UITableView = UITableView.init()
    var mainView:UIStackView = UIStackView.init()
    
    override func setupController() async {
        
        selectedLocation = await getRandomLocation()
        mapControl?.select(location: selectedLocation, behavior: .default)
        
        self.detailsView.dataSource = self as UITableViewDataSource

        /***
         Arrange the map and the stackview inside another stackview
         ***/

        mainView = UIStackView.init(arrangedSubviews: [map!, detailsView])
        mainView.axis = .vertical

        self.detailsView.translatesAutoresizingMaskIntoConstraints = false
        self.detailsView.heightAnchor.constraint(equalToConstant: 132).isActive = true
        self.detailsView.widthAnchor.constraint(equalTo: self.mainView.widthAnchor).isActive = true

        view = mainView
    }
}

    
extension LocationDetailsController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .value2, reuseIdentifier: nil)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Name"
            cell.detailTextLabel?.text = selectedLocation?.name
        case 1:
            cell.textLabel?.text = "Room Id"
            cell.detailTextLabel?.text = selectedLocation?.locationId
        case 2:
            cell.textLabel?.text = "Floor Index"
            cell.detailTextLabel?.text = selectedLocation?.floorIndex.stringValue
        default:
            break
        }
        
        return cell
    }
    
}
