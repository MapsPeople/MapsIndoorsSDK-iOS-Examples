import UIKit

class DemoTableViewDelegate: NSObject, UITableViewDelegate {
    var demos: [Demo]
    var sectionTitles: [String]
    var filteredDemos: [Demo]
    weak var navigationController: UINavigationController?
    weak var delegate: DemoTableViewDelegateCallback?
    
    init(demos: [Demo], sectionTitles: [String], filteredDemos: [Demo], navigationController: UINavigationController?) {
        self.demos = demos
        self.sectionTitles = sectionTitles
        self.filteredDemos = filteredDemos
        self.navigationController = navigationController
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionTitle = sectionTitles[indexPath.section]
        let demosInSection = filteredDemos.filter { $0.sectionTitle == sectionTitle }
        let vc = demosInSection[indexPath.row].controllerClass.init()
        delegate?.didSelectCell()
        navigationController?.pushViewController(vc, animated: true)
    }
}

protocol DemoTableViewDelegateCallback: AnyObject {
    func didSelectCell()
}
