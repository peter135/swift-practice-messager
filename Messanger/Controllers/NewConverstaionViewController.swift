//
//  NewConverstaionViewController.swift
//  Messanger
//
//  Created by apple on 2024/6/3.
//

import UIKit
import JGProgressHUD

class NewConverstaionViewController: UIViewController {

    public var completion:(([String:String]) -> (Void))?
    private let spinner = JGProgressHUD(style: .dark)
    private var users = [[String:String]]()
    private var results = [[String:String]]()
    private var hasFetched = false
    
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
        view.addSubview(noResutlsLable)
        view.addSubview(tableView)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.delegate = self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResutlsLable.frame = CGRect(x: view.width/4, y: (view.height - 200)/2, width: view.width/2, height: 200)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

}


extension NewConverstaionViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUser = self.results[indexPath.row]
        
        dismiss(animated: true) {[weak self] in
            self?.completion?(targetUser)
        }
    }
    
}

extension NewConverstaionViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        spinner.show(in: view)
        self.searchUsers(query: text)
    }
    
    func searchUsers(query:String) {
        /// check if array has firebase results
        
        if hasFetched {
            filterUsers(with: query)
            
        }else {
            DatabaseManager.shared.getAllUsers { [weak self] result in
                guard let self = self else {return}
                switch result{
                    case .success(let users):
                        self.hasFetched = true
                        self.users = users
                        self.filterUsers(with: query)
                    case .failure(let error):
                      print("failed error \(error)")
                }
            }
            
        }
        
    }
    
    func filterUsers(with term:String){
        guard hasFetched else {return}
        
        self.spinner.dismiss()
        
        var results : [[String:String]] = self.users.filter{ user in
            guard let name = user["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }
        
        self.results = results
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            self.noResutlsLable.isHidden = false
            self.tableView.isHidden = true
            
        }else{
            self.noResutlsLable.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
}
