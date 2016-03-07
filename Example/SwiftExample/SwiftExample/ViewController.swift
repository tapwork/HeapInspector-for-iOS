//
//  ViewController.swift
//  SwiftExample
//
//  Created by Christian Menschel on 07/03/16.
//  Copyright © 2016 TAPWORK. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let detailViewController = DetailViewController();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.redColor()
        self.addChildViewController(self.detailViewController)
        self.view.addSubview(self.detailViewController.view)
        self.detailViewController.didMoveToParentViewController(self)
    }
}

