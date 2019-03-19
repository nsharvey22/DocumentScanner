//
//  MyCollectionViewCell.swift
//  Gemini Demo
//
//  Created by Nick Harvey on 2/11/19.
//  Copyright © 2019 Christopher Ching. All rights reserved.
//

import UIKit

protocol MyCollectionViewCellDelegate: class {
    func delete(cell: MyCollectionViewCell)
}

class MyCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var documentTitle: UILabel!
    @IBOutlet weak var extraPagesView: UIView!
    @IBOutlet weak var extraPagesView2: UIView!
    @IBOutlet weak var extraPagesView3: UIView!
    @IBOutlet weak var deleteButton: UIButton!
    
    weak var delegate: MyCollectionViewCellDelegate?
    
    var isEditing: Bool = false {
        didSet {
            deleteButton.isHidden = !isEditing
            if isEditing {
                self.vibrate(stop: false)
            } else {
                self.vibrate(stop: true)
                //deleteButton.isHidden = false
            }
        }
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        delegate?.delete(cell: self)
    }
    
    func setCellwithImage(image:UIImage) {
        
        cellImage.image = image
        cellImage.contentMode = .scaleToFill
        cellImage.layer.borderColor = UIColor.gray.cgColor
        cellImage.layer.borderWidth = 0.5
        deleteButton.isHidden = true
    }
    
    func setCellwithExtraPages(num:Int) {

        let width = ((UIScreen.main.bounds.width - 40)/3)
        
        let height = width * (297/210)// A4 Size
        let horizontalInset = 3
        let verticalInset = 3
        
        extraPagesView.frame = CGRect(x: 0, y: 0, width: width, height: height)

        extraPagesView.frame.size.width -= CGFloat(3 * horizontalInset)
        extraPagesView.frame.origin.x += CGFloat(1 * horizontalInset)
        extraPagesView.frame.origin.y -= CGFloat(1 * verticalInset)
        extraPagesView.backgroundColor = .white
        extraPagesView.contentMode = .scaleToFill

        extraPagesView.layer.borderColor = UIColor.gray.cgColor
        extraPagesView.layer.borderWidth = 0.5


        extraPagesView2.frame = CGRect(x: extraPagesView.frame.origin.x, y: extraPagesView.frame.origin.y, width: extraPagesView.frame.width, height: extraPagesView.frame.height)
        extraPagesView2.frame.size.width -= CGFloat(2 * horizontalInset)
        extraPagesView2.frame.origin.x += CGFloat(1 * horizontalInset)
        extraPagesView2.frame.origin.y -= CGFloat(1 * verticalInset)
        extraPagesView2.backgroundColor = .white
        extraPagesView2.contentMode = .scaleToFill

        extraPagesView2.layer.borderColor! = UIColor.gray.cgColor
        extraPagesView2.layer.borderWidth = 0.5

    
        extraPagesView3.frame = CGRect(x: extraPagesView2.frame.origin.x, y: extraPagesView2.frame.origin.y, width: extraPagesView2.frame.width, height: extraPagesView2.frame.height)
        extraPagesView3.frame.size.width -= CGFloat(2 * horizontalInset)
        extraPagesView3.frame.origin.x += CGFloat(1 * horizontalInset)
        extraPagesView3.frame.origin.y -= CGFloat(1 * verticalInset)
        extraPagesView3.backgroundColor = .white
        extraPagesView3.contentMode = .scaleToFill

        extraPagesView3.layer.borderColor! = UIColor.gray.cgColor
        extraPagesView3.layer.borderWidth = 0.5

        
        if num >= 3 {
            extraPagesView.alpha = 1
            extraPagesView2.alpha = 1
            extraPagesView3.alpha = 1
            
        } else if num == 2 {
            extraPagesView3.alpha = 0
            extraPagesView.alpha = 1
            extraPagesView2.alpha = 1
        } else if num == 1 {
            extraPagesView2.alpha = 0
            extraPagesView3.alpha = 0
            extraPagesView.alpha = 1
        } else {
            extraPagesView.alpha = 0
            extraPagesView2.alpha = 0
            extraPagesView3.alpha = 0
        }
        
    }
    
    func setCellwithTitle(title:String) {

        documentTitle.text = title
        
    }
    
    func vibrate(stop: Bool) {
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.2
        animation.repeatCount = Float.infinity
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 1.0, y: self.center.y + 1))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 1.0, y: self.center.y - 1))
        
        let animation2 = CABasicAnimation(keyPath: "transform.rotation")
        animation2.duration = 0.15
        animation2.fromValue = -0.01
        animation2.toValue = 0.01
        animation2.repeatCount = Float.infinity
        animation2.autoreverses = true
        
        self.layer.add(animation, forKey: "position")
        self.layer.add(animation2, forKey: "transform.rotation")
        if stop {
            self.layer.removeAllAnimations()
        }

    }
    
}
