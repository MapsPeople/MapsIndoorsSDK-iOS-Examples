import UIKit
import MapsIndoorsCore
import MapsIndoors

class DatasetListController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    weak var delegate: DatasetListControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(DatasetCell.self, forCellReuseIdentifier: "DatasetCell")
        self.view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MPMapsIndoors.shared.datasetCacheManager.managedDataSets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DatasetCell", for: indexPath) as! DatasetCell
        let dataSetCache = MPMapsIndoors.shared.datasetCacheManager.managedDataSets[indexPath.row]
        
        cell.mainLabel.text = dataSetCache.dataSetId
        cell.subLabel.text = """
        \(dataSetCache.cacheItem.name ?? "")
        Cached: \(dataSetCache.cacheItem.cachedTimestamp ?? Date())
        Synced: \(dataSetCache.cacheItem.syncTimestamp ?? Date())
        """
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataSetCache = MPMapsIndoors.shared.datasetCacheManager.managedDataSets[indexPath.row]
        let selectedDataSetId = dataSetCache.dataSetId
        
        let actionSheet = UIAlertController(title: "Choose an action", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Remove Dataset", style: .destructive, handler: { _ in
            if MPMapsIndoors.shared.datasetCacheManager.removeDataSet(dataSetCache) {
                self.dismiss(animated: true, completion: nil)
            } else {
                fatalError("failed")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Load", style: .default, handler: { _ in
            MapEngine.APIKey = selectedDataSetId
            self.delegate?.didLoadDataset()
            self.dismiss(animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
}
// Using a delegate to notify the `DatasetMapController` to execute the refresh method when the "Load" action is selected.
protocol DatasetListControllerDelegate: AnyObject {
    func didLoadDataset()
}

class DatasetCell: UITableViewCell {
    
    var mainLabel: UILabel!
    var subLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        mainLabel = UILabel()
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(mainLabel)
        
        subLabel = UILabel()
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.numberOfLines = 0
        subLabel.font = UIFont.systemFont(ofSize: 12)
        self.contentView.addSubview(subLabel)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            mainLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5),
            mainLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15),
            mainLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -15),
            mainLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        NSLayoutConstraint.activate([
            subLabel.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 5),
            subLabel.leadingAnchor.constraint(equalTo: mainLabel.leadingAnchor),
            subLabel.trailingAnchor.constraint(equalTo: mainLabel.trailingAnchor),
            subLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -5)
        ])
    }
}

