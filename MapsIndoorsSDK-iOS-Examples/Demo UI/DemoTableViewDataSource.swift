import UIKit

class DemoTableViewDataSource: NSObject, UITableViewDataSource {
    var demos: [Demo]
    var sectionTitles: [String]
    var filteredDemos: [Demo]
    
    init(demos: [Demo], sectionTitles: [String], filteredDemos: [Demo]) {
        self.demos = demos
        self.sectionTitles = sectionTitles
        self.filteredDemos = filteredDemos
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = sectionTitles[section]
        return filteredDemos.filter { $0.sectionTitle == sectionTitle }.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoTableViewCell", for: indexPath)
        let sectionTitle = sectionTitles[indexPath.section]
        let demosInSection = filteredDemos.filter { $0.sectionTitle == sectionTitle }
        let demo = demosInSection[indexPath.row]
        cell.textLabel?.text = demo.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        cell.detailTextLabel?.text = demo.description
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessibilityIdentifier = cell.textLabel?.text
        return cell
    }
}
