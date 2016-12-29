//
//  FilesViewController.swift
//  CloudDocuments
//
//  Created by Mihail Salari on 12/29/16.
//  Copyright © 2016 Mihail Salari. All rights reserved.
//

import UIKit

class FilesViewController: UITableViewController {
    
    // MARK: - Properties
    
    lazy var metadataQuery: NSMetadataQuery = {
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        let filePattern = "*.jpg"
        query.predicate = NSPredicate(format: "%K LIKE %@", NSMetadataItemFSNameKey, filePattern)
        /// what are you looking for
        
        return query
    }()
    
    
    
    // MARK: - LyfeCicle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.checkiCloudAviability { [unowned self] (succes) in
            if succes {
                self.metadataQuery.start()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateFileList(_:)), name: NSNotification.Name(rawValue: NSNotification.Name.NSMetadataQueryDidFinishGathering.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateFileList(_:)), name: NSNotification.Name(rawValue: NSNotification.Name.NSMetadataQueryDidUpdate.rawValue), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Deinit
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


// MARK: - Table view data source

extension FilesViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return metadataQuery.resultCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if let result = self.metadataQuery.result(at: indexPath.row) as? NSMetadataItem {
            if self.isMetadataItemDownloaded(result) {
                cell.textLabel?.textColor = .black
            } else {
                cell.textLabel?.textColor = .lightGray
            }
            
            if let urlResult = result.value(forAttribute: NSMetadataItemURLKey) as? URL {
                if let imageData = try? Data(contentsOf: urlResult) {
                    if let thumbnail = resizeData(imageData) {
                        cell.imageView?.image = thumbnail
                    }
                }
                
                cell.textLabel?.text = urlResult.lastPathComponent
            } else {
                cell.textLabel?.text = "Error finding file"
                cell.imageView?.image = UIImage(named: "denied")
            }
        }
        
        return cell
    }
}


// MARK: - Table view delegate

extension FilesViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let result = self.metadataQuery.result(at: indexPath.row) as? NSMetadataItem {
            if let urlResult = result.value(forAttribute: NSMetadataItemURLKey) as? URL {
                self.performSegue(withIdentifier: "ShowImageSegue", sender: urlResult)
            }
        }
    }
}


// MARK: - Helper Methods

extension FilesViewController {
    
    fileprivate func checkiCloudAviability(_ completion: @escaping (Bool) -> ()) {
        
        /// Take in background
        OperationQueue().addOperation { _ in
            let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
            
            if containerURL != nil {
                OperationQueue.main.addOperation {
                    completion(true)
                }
            } else {
                OperationQueue.main.addOperation {
                    completion(false)
                }
            }
        }
    }
    
    fileprivate func isMetadataItemDownloaded(_ item: NSMetadataItem) -> Bool {
        if let value = item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey)  as? String {
            if value == NSMetadataUbiquitousItemDownloadingStatusCurrent {
                return true
            }
        }
        
        return false
    }
}


extension FilesViewController {
    
    func updateFileList(_ sender: Notification) {
        self.metadataQuery.enumerateResults({ (item, index, stopPointer) in
            if let metadataItem = item as? NSMetadataItem {
                if !self.isMetadataItemDownloaded(metadataItem) {
                    if let itemURL = metadataItem.value(forAttribute: NSMetadataItemURLKey) as? URL {
                        
                        do {
                            try FileManager.default.startDownloadingUbiquitousItem(at: itemURL)
                        } catch {
                            print("Error downloading file at \(itemURL), \(error)")
                        }
                    }
                }
            }
        })

        self.tableView.reloadData()
    }
}


// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension FilesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
         
            let fileName = "Image \(Date().timeIntervalSinceReferenceDate).jpg"
            
            let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            
            if let imageData = UIImageJPEGRepresentation(image, 0.8) {
                do {
                    try imageData.write(to: temporaryURL)
                } catch { }
            }
            
            self.dismiss(animated: true, completion: nil)
            
            OperationQueue().addOperation {
                if let destinationURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent(fileName) {
                    
                    do {
                        try FileManager.default.setUbiquitous(true, itemAt: temporaryURL, destinationURL: destinationURL)
                    } catch {
                        print("Error moving \(temporaryURL) to storage \(destinationURL)")
                    }
                }
            }
        }
    }
}


// MARK: - @IBAction's

extension FilesViewController {
    
    @IBAction func addNewFileTapped(_ sender: UIBarButtonItem) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
        } else {
            imagePicker.sourceType = .photoLibrary
        }
        
        self.present(imagePicker, animated: true, completion: nil)
    }
}



// MARK: - Navigation

extension FilesViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            
            switch identifier {
            case "ShowImageSegue":
                if let urlResult = sender as? URL {
                    print("urlResult = \(urlResult)")
                    let previewController = segue.destination as! PreviewViewController
                    if let image = UIImage(contentsOfFile: urlResult.path) {
                        previewController.image = image
                    }
                }
            default:
                break
            }
        }
    }
}
