//
//  ViewController.swift
//  SwiftExample
//
//  Created by Christian Menschel on 07/03/16.
//  Copyright © 2016 TAPWORK. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton();
        button.addTarget(self, action: "pressed:", forControlEvents: .TouchUpInside)
        button.frame = CGRectMake(100, 300, 100, 50)
        button.setTitle("Details", forState: .Normal)
        button.backgroundColor = UIColor.blackColor()
        self.view.addSubview(button)
    }

    func pressed(sender: UIButton!) {
        let detailVC = DetailViewController()
        self.addChildViewController(detailVC)
        self.view.addSubview(detailVC.view)
        detailVC.didMoveToParentViewController(self)
    }
}

