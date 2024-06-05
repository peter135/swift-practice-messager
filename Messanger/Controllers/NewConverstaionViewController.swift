//
//  NewConverstaionViewController.swift
//  Messanger
//
//  Created by apple on 2024/6/3.
//

import UIKit
import JGProgressHUD

class NewConverstaionViewController: UIViewController {

    private let spinner = JGProgressHUD()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "search for users"
        return searchBar
    }()
    
    private let tableView:UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResutlsLable:UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "no reusluts"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21,weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

}

extension NewConverstaionViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
}
