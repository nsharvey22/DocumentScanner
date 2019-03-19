//
//  MyCell.swift
//  Gemini Demo
//
//  Start building your own apps today. Get my 7 day app action plan here:
//  https://codewithchris.com/actionplan/
//
//  Photos used: rawpixel.com, PixaSquare, Naveen Annam, Murilo Folgosi and Chloe Kala from Pexels 

import UIKit
import Gemini

class MyCell: GeminiCell {
    
    @IBOutlet weak var documentTitle: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var customShadowView: UIView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var deleteButton: UIButton!
    override var shadowView: UIView? {
        return customShadowView
    }

    func setCell(imageName:String) {
        
        mainImageView.image = UIImage(named: imageName)

    }
    
    func setCellwithImage(image:UIImage) {
        
        mainImageView.image = image
        
    }
    
    func setCellwithTitle(title:String) {
        
        documentTitle.text = title
        documentTitle.textColor = .white
        documentTitle.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: CGFloat(0.5))
        let gradient = CAGradientLayer()
        gradient.frame = documentTitle.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.locations = [0, 0.4, 0.6, 1]
        documentTitle.layer.mask = gradient
        
    }
    
}
