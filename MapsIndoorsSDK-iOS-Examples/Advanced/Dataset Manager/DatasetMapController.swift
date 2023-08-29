import UIKit

class DatasetMapController: BaseMapController {
    
    var showDatasetsButton: UIButton!
    
    override func setupController() async {
        let datasetListController = DatasetListController()
        datasetListController.delegate = self
        self.present(datasetListController, animated: true, completion: nil)
        
        showDatasetsButton = UIButton(frame: CGRect(x: 20, y: self.view.bounds.height - 120, width: self.view.bounds.width - 40, height: 40))
        showDatasetsButton.setTitle("Show Datasets", for: .normal)
        showDatasetsButton.backgroundColor = .systemTeal
        showDatasetsButton.addTarget(self, action: #selector(showDatasets), for: .touchUpInside)
        self.view.addSubview(showDatasetsButton)
    }
    
    @objc func showDatasets() {
        let datasetListController = DatasetListController()
        datasetListController.delegate = self
        self.present(datasetListController, animated: true, completion: nil)
    }
    
    override func adjustUI(forMenu: Bool) {
        if showDatasetsButton != nil {
            showDatasetsButton.isHidden = forMenu
        }
    }
    
    override func updateForBuildingChange() {
        if showDatasetsButton != nil {
            showDatasetsButton.isHidden = false
        }
    }
}

extension DatasetMapController: DatasetListControllerDelegate {
    func didLoadDataset() {
        reloadData()
    }
    
    func reloadData() {
        Task {
            startLoadingUI()
            try await loadMapsIndoorsSDK()
            await moveCameraToBuilding()
            stopLoadingUI()
            await repopulateTable()
        }
    }
    
    func repopulateTable() async{
        await populateDropdownTable()
    }
}
