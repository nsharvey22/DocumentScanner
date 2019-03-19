//
//  TakePhotoViewController.swift
//  Gemini Demo
//
//  Created by Nick Harvey on 2/6/19.
//  Copyright © 2019 Christopher Ching. All rights reserved.
//

import UIKit


class TakePhotoViewController: UIViewController, UIPopoverPresentationControllerDelegate {


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        modalPresentationStyle = .popover
        popoverPresentationController!.delegate = self
        
        self.preferredContentSize = CGSize(width:320,height:100)
      //  initScanner()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        //do som stuff from the popover
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
