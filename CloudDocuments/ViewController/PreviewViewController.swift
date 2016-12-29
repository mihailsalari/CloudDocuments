//
//  PreviewViewController.swift
//  CloudDocuments
//
//  Created by Mihail Salari on 12/29/16.
//  Copyright © 2016 Mihail Salari. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage?
    
    
    
    // MARK: - LyfeCicle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        imageView.image = image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


// MARK: - @IBAction's

extension PreviewViewController {
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}
