import UIKit
import MapsIndoorsCore
import MapsIndoors

/***
 ---
 title: Work with location grouping / clustering
 ---
 
 This is an example of enabling and disabling location grouping on the map as well as providing custom cluster tapping behavior and custom cluster images.
 
 Start by creating a  class that conforms to the  protocol `MPCustomClusterIcon`
 ***/
class ClusteringController: BaseMapController, MPCustomClusterIcon {
    private let collisionButton = UIButton.init()
    private let clusteringButton = UIButton.init()
    private let iconToggleButton = UIButton.init()
    
    override func setupController() async {
        mapControl?.customClusterIcon = self
        
        /***
         Setup buttons that enables/disables the location collision/overlapping, grouping/clustering mechanism and the icon from default <=> custom
         ***/
        setupIconToggleButton()
        setupClusteringButton()
        setupCollisionButton()
        
        // Create a stack view
        let stackView = UIStackView(arrangedSubviews: [collisionButton, clusteringButton, iconToggleButton])
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
    
   private func setupButton(button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.backgroundColor = UIColor(red: 35/255, green: 85/255, blue: 84/255, alpha: 0.7)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false // Enable Auto Layout for the button
    }
    
    private func setupIconToggleButton() {
        setupButton(button: iconToggleButton, title: "Custom Cluster Icon", action: #selector(toggleIcon))
    }
    
    private func setupClusteringButton() {
        let clusteringEnabled = MPMapsIndoors.shared.solution?.config.enableClustering ?? false
        let title = "Clustering \(clusteringEnabled ? "enabled" : "disabled")"
        setupButton(button: clusteringButton, title: title, action: #selector(toggleClustering))
    }
    
    private func setupCollisionButton() {
        let collisionHandling = MPMapsIndoors.shared.solution?.config.collisionHandling
        let title = "Collision: \(collisionHandling?.description ?? "unknown")"
        setupButton(button: collisionButton, title: title, action: #selector(changeCollision))
    }
    
    /***
     Define an objective-c method `changeCollision` that will receive events from your button:
     * Check current state
     * Swap state
     * Make button reflect the state
     * Force re-render map
     ***/
    @objc func changeCollision() {
        guard let currentHandling = MPMapsIndoors.shared.solution?.config.collisionHandling else { return }
        
        let nextHandling: MPCollisionHandling
        switch currentHandling {
        case .allowOverLap:
            nextHandling = .removeIconAndLabel
        case .removeIconAndLabel:
            nextHandling = .removeIconFirst
        case .removeIconFirst:
            nextHandling = .removeLabelFirst
        case .removeLabelFirst:
            nextHandling = .allowOverLap
        }
        
        MPMapsIndoors.shared.solution?.config.collisionHandling = nextHandling
        collisionButton.setTitle("Collision: \(nextHandling.description)", for: .normal)
        mapControl?.refresh()
    }
    
    /***
     Define an objective-c method `toggleClustering` that will receive events from your button, and toggle the clustering flag:
     * Check current state
     * Swap state
     * Make button reflect the state
     * Force re-render map
     ***/
    @objc func toggleClustering() {
        guard let clusteringEnabled = MPMapsIndoors.shared.solution?.config.enableClustering else { return }
        
        let newStatus = !clusteringEnabled
        MPMapsIndoors.shared.solution?.config.enableClustering = newStatus
        clusteringButton.setTitle("Clustering \(newStatus ? "enabled" : "disabled")", for: .normal)
        mapControl?.refresh()
    }
    
    /***
     Define an objective-c method `toggleIcon` that will receive events from your button, and toggle the icon flag:
     * Check current state
     * Swap state
     * Make button reflect the state
     * Force re-render map
     ***/
    @objc func toggleIcon() {
        iconToggleButton.isSelected.toggle()
        // Update button title
        if iconToggleButton.isSelected {
            iconToggleButton.setTitle("Default Cluster Icon", for: .normal)
            mapControl?.customClusterIcon = nil // Use default icon
        } else {
            iconToggleButton.setTitle("Custom Cluster Icon", for: .normal)
            mapControl?.customClusterIcon = self // Use custom icon
        }
        mapControl?.refresh()
    }
    
    /***
     * Implement the `clusterIconFor` to provide custom icons for clusters
     **/
    func clusterIconFor(type: String, size: Int) -> UIImage {
        let clusterSize = CGSize(width: 30, height: 30)
        let renderer = UIGraphicsImageRenderer(size: clusterSize)
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.red.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
            ctx.cgContext.setLineWidth(2)
            
            let rectangle = CGRect(x: 0, y: 0, width: clusterSize.width, height: clusterSize.height)
            ctx.cgContext.addEllipse(in: rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white
            ]
            
            let text = NSAttributedString(string: "\(size)", attributes: attributes)
            let textSize = text.size()
            let textPoint = CGPoint(x: (clusterSize.width - textSize.width) / 2, y: (clusterSize.height - textSize.height) / 2)
            text.draw(at: textPoint)
        }
        return img
    }
    
    override func adjustUI(forMenu: Bool) {
        collisionButton.isHidden = forMenu
        clusteringButton.isHidden = forMenu
        iconToggleButton.isHidden = forMenu
    }
    
    override func updateForBuildingChange() {
        collisionButton.isHidden = false
        clusteringButton.isHidden = false
        iconToggleButton.isHidden = false
    }
}

fileprivate extension MPCollisionHandling {
    var description: String {
        switch self {
        case .allowOverLap:
            return "allowOverLap"
        case .removeLabelFirst:
            return "removeLabelFirst"
        case .removeIconFirst:
            return "removeIconFirst"
        case .removeIconAndLabel:
            return "removeIconAndLabel"
        }
    }
}
