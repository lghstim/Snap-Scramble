//
//  IAPViewController.swift
//  Snap Scramble
//
//  Created by Tim Gorer on 12/29/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

import UIKit

class IAPViewController: UIViewController {

    override func viewDidLoad() {
        self.navigationController?.navigationBar.isHidden = true;
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func goBackButtonDidPress(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    @IBAction func purchaseFullVersionButtonDidPress(_ sender: Any) {
    }

}
