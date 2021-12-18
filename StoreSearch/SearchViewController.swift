//
//  ViewController.swift
//  StoreSearch
//
//  Created by Brang Mai on 12/4/21.
//

import UIKit

class SearchViewController: UIViewController {
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    
    var dataTask: URLSessionDataTask?
   
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        searchBar.becomeFirstResponder()
        super.viewDidLoad()
        
        var cellNib = UINib(nibName: TableView.CellIndentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIndentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableView.CellIndentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIndentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableView.CellIndentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIndentifiers.loadingCell)
        // Do any additional setup after loading the view.
        tableView.contentInset = UIEdgeInsets(top: 91, left: 0, bottom: 0, right: 0)
        
        
    }
    
    struct TableView {
        struct CellIndentifiers {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
            static let loadingCell = "LoadingCell"
        }
    }
    
}


// Mark: Search Bar Delegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        performSearch()
    }
  
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    func performSearch() {
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            dataTask?.cancel()
            
            isLoading = true
            tableView.reloadData()
            hasSearched = true
            searchResults = []
            
//            // 1
//            let queue = DispatchQueue.global()
//
//            // 2
//            queue.async {
//                let url = iTuneURL(searchText: searchBar.text!)
//                if let data = self.performStoreRequest(with: url) {
//                    self.searchResults = parse(data: data)
//                    self.searchResults.sorted(by: <)
//
//                    // 3
//                    DispatchQueue.main.async {
//                        self.isLoading = false
//                        self.tableView.reloadData()
//                    }
//                    return
//                }
//            }
            let url = iTuneURL(searchText: searchBar.text!, category: segmentedControl.selectedSegmentIndex)
            let session = URLSession.shared
            // 3
            dataTask = session.dataTask(with: url) {data, response, error in // [weak self] is used to avoid memory leaks
                // 4
                if let error = error as NSError?, error.code == -999 {
                    print("Failure! \(error.localizedDescription)")
                    return
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let data = data {
                        self.searchResults = parse(data: data)
                        self.searchResults.sorted(by: <)
                        DispatchQueue.main.async {
                            self.isLoading = false
//                            self.hasSearched = false
                            self.tableView.reloadData()
                            shownetworkError()
                        }
                    }
                } else {
                    print("Failure! \(response!)")
                }
            }
            // 5
            dataTask?.resume()
        }        
    }
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

// Mark: - Table View delegate
extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIndentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        } else if searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableView.CellIndentifiers.nothingFoundCell, for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIndentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            cell.configure(for: searchResult)
            return cell
            
//            if searchResult.artist.isEmpty {
//                cell.artistNameLabel.text = "Unknown"
//            } else {
//                cell.artistNameLabel.text = String(format: "%@ (%@)", searchResult.artist, searchResult.type)
//            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectedRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectedRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }

}
func iTuneURL(searchText: String, category: Int) -> URL {
    let kind: String
    switch category {
    case 1: kind = "musicTrack"
    case 2: kind = "software"
    case 3: kind = "ebook"
    default: kind = ""
    }
    let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    let urlString = "https://itunes.apple.com/search?" + "term=\(encodedText)&limit=200&entity=\(kind)"
    let url = URL(string: urlString)
    return url!
}

func parse(data: Data) -> [SearchResult] {
    do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(ResultArray.self, from: data)
        return result.results
    } catch {
        print("JSON Error: \(error)")
        return []
    }
}

func shownetworkError() {
    let alert = UIAlertController(title: "Whoops...", message: "There was an error accessing the iTunes Store." + "Please try again.", preferredStyle: .alert)
    
    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(action)
    present(alert, animated: true, completion: nil)
}

// Source from developer.apple.com
func present(_ viewControllerToPresent: UIViewController,
    animated flag: Bool,
    completion: (() -> Void)? = nil) {
        
}

