import UIKit
import MapsIndoors

class StartPage: UIViewController {
    @IBOutlet weak var apiTextField: UITextField!
    @IBOutlet weak var loadButton: UIButton!
    
    @IBOutlet weak var mapProviderSegmentedControl: UISegmentedControl!
    
    var selectedMapProvider: Int = 0
    
    @IBAction func mapProviderChanged(_ sender: UISegmentedControl) {
        // Store the selected map provider when the segmented control value changes
        selectedMapProvider = sender.selectedSegmentIndex
    }
    
    @IBAction func dMap(_ sender: Any) {
        presentDemoSelectorViewController(apiKey: "qa3dglb")
    }
    
    @IBAction func WhiteHouse(_ sender: Any) {
        presentDemoSelectorViewController(apiKey: "d876ff0e60bb430b8fabb145")
    }
    
    @IBAction func mapsPeople(_ sender: Any) {
        presentDemoSelectorViewController(apiKey: "mapspeople")
    }
    
    @IBAction func customKey(_ sender: Any) {
        presentDemoSelectorViewController(apiKey: "4808bca6db85450c819c020c") // YOUR Key goes here for quick selection
    }
    
    @IBAction func loadAPIKey(_ sender: Any) {
        presentDemoSelectorViewController(apiKey: apiTextField.text)
    }
    
    private func presentDemoSelectorViewController(apiKey: String?) {
        let controller = storyboard?.instantiateViewController(identifier: "demoSelector") as! DemoSelectorViewController
        controller.APIKey = apiKey
        controller.selectedMapProvider = selectedMapProvider  // Pass the selected map provider
        
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        
        present(navigationController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Adjusts the background color based on the interface style
        self.view.backgroundColor = UIColor.systemBackground
    }
}
