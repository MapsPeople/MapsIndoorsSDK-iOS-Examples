//
//  SolutionSwitch.swift
//  Demos
//
//  Created by Christian Wolf Johannsen on 09/01/2023.
//  Copyright © 2023 MapsPeople A/S. All rights reserved.
//

import UIKit
import MapsIndoors
import MapsIndoorsCore

class SolutionSwitchController: BaseMapController{
    private let pickerView = UIPickerView()
    private let solutionName = UILabel()
    private let solutions = [
          "YOUR_SOLUTION_ID",
          "YOUR_SOLUTION_ID_2",
          "YOUR_SOLUTION_ID_3",
          "YOUR_SOLUTION_ID_4"
      ]

    override func setupController() async {
        setupPickerView()
        addSolutionLabel()
    }
    
    fileprivate func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.backgroundColor = .systemGray
        view.addSubview(pickerView)
        setupPickerViewConstraints()
    }
    
    fileprivate func setupPickerViewConstraints() {
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.text = solutions[row]
        label.textAlignment = .center
        return label
    }
    
    fileprivate func addSolutionLabel() {
        view.addSubview(solutionName)
        solutionName.textColor = .white
        solutionName.backgroundColor = .systemGray
        
        solutionName.translatesAutoresizingMaskIntoConstraints = false
        solutionName.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        solutionName.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
        solutionName.text = MapEngine.APIKey
    }
}
// MARK: - UIPickerViewDelegate
extension SolutionSwitchController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return solutions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedSolution = solutions[row]
        // update the solution key on app level so `BaseMapController` can update acoordingly
        MapEngine.APIKey = selectedSolution
        reloadData()
    }
}
// MARK: - UIPickerViewDataSource
extension SolutionSwitchController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return solutions.count
    }
}
// MARK: - Data Reload
extension SolutionSwitchController {
    func reloadData() {
        Task {
            startLoadingUI()
            try await loadMapsIndoorsSDK()
            await moveCameraToBuilding()
            stopLoadingUI()
            await repopulateTable()
            // update the label
            solutionName.text = MapEngine.APIKey
        }
    }
    
    func repopulateTable() async{
        await populateDropdownTable()
    }
}
