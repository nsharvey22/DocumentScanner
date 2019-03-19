//
//  PageCollectionViewCell.swift
//  Gemini Demo
//
//  Created by Nick Harvey on 2/28/19.
//  Copyright © 2019 Christopher Ching. All rights reserved.
//

import UIKit
import DragRotateScaleView


class PageCollectionViewCell: UICollectionViewCell, DragRotateScaleViewDelegate {
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var signImageView: UIImageView!
    @IBOutlet weak var resizePoint: UIView!
    @IBOutlet weak var signImageCenterY: NSLayoutConstraint!
    @IBOutlet weak var signImageCenterX: NSLayoutConstraint!
    @IBOutlet weak var signImageWidth: NSLayoutConstraint!
    @IBOutlet weak var signImageHeight: NSLayoutConstraint!
    @IBOutlet weak var resizableView: DragRotateScaleView!
    
    func setCellwithImage(image:UIImage) {
        mainImageView.image = image
        if signImageView != nil {
            signImageView.removeFromSuperview()
        }
    }
    
    func setCellwithSignature(image:UIImage) {
        signImageView.image = image
        resizableView.delegate = self
    }
    
    func doubleTapGesture(_ sender: UITapGestureRecognizer, view: DragRotateScaleView) {
        view.rotated(by: CGFloat.pi / 4)
    }

}


