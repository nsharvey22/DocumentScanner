//
//  FullScreenViewController.swift
//  Gemini Demo
//
//  Created by Nick Harvey on 2/11/19.
//  Copyright © 2019 Christopher Ching. All rights reserved.
//

import UIKit
import WeScan
import EPSignature

class FullScreenViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImageScannerControllerDelegate, EPSignatureDelegate, UIGestureRecognizerDelegate {
    
    var selectedDoc:Document?
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolBarView: UIToolbar!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var addSignatureBtn: UIBarButtonItem!
    let imagePicker = UIImagePickerController()
    var tempIndexPath:IndexPath?
    var combinedImage:UIImage?
    var selectedImage:Image?
    var currentCell:PageCollectionViewCell?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        imagePicker.delegate = self
        setupCollectionView()
        
        saveButton.isHidden = true
        cancelButton.isHidden = true
        addSignatureBtn.isEnabled = false
        addSignatureBtn.image = UIImage()
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            self.navigationController?.navigationBar.isHidden = false
        }
    }
    
    func setupCollectionView() {

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
        }
        collectionView?.isPagingEnabled = true
    }

    @IBAction func addSignature(_ sender: Any) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        var arrayOfImages = self.selectedDoc?.image?.sortedArray(
            using: [NSSortDescriptor(key:"pageNumber", ascending: true)]) as! [Image]
        if let image = arrayOfImages[(visibleIndexPath?.item)!] as? Image {
            print("current index: ", visibleIndexPath?.item)
            print("current page: ", image.pageNumber)
        }
        let signatureVC = EPSignatureViewController(signatureDelegate: self, showsDate: true, showsSaveSignatureOption: true)
        signatureVC.subtitleText = "I agree to the terms and conditions"
        signatureVC.title = "John Doe"
        let nav = UINavigationController(rootViewController: signatureVC)
        present(nav, animated: true, completion: nil)
        
    }
    
    func epSignature(_: EPSignatureViewController, didCancel error : NSError) {
        print("User canceled")
    }
    
    func epSignature(_: EPSignatureViewController, didSign signatureImage : UIImage, boundingRect: CGRect) {

        let visibleRect = CGRect(origin: self.collectionView.contentOffset, size: self.collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = self.collectionView.indexPathForItem(at: visiblePoint)
        var arrayOfImages = self.selectedDoc?.image?.sortedArray(
            using: [NSSortDescriptor(key:"pageNumber", ascending: true)]) as! [Image]
        if let image = arrayOfImages[(visibleIndexPath?.item)!] as? Image {
            if let cell = collectionView.cellForItem(at: visibleIndexPath!) as? PageCollectionViewCell {
                cell.setCellwithSignature(image: signatureImage)
                currentCell = cell
                combinedImage = self.mergeImages(imageView: cell.mainImageView)
                selectedImage = image
                UIView.animate(withDuration: 0.3, animations: {
                    self.navigationController?.navigationBar.isHidden = true
                    self.toolBarView.isHidden = true
                    self.saveButton.isHidden = false
                    self.cancelButton.isHidden = false
                    
                    self.saveButton.layer.shadowColor = UIColor.black.cgColor
                    self.saveButton.layer.shadowOffset = CGSize(width: 0, height: 10.0)
                    self.saveButton.layer.shadowRadius = 12.0
                    self.saveButton.layer.shadowOpacity = 0.3
 
                    self.cancelButton.layer.shadowColor = UIColor.black.cgColor
                    self.cancelButton.layer.shadowOffset = CGSize(width: 0, height: 10.0)
                    self.cancelButton.layer.shadowRadius = 12.0
                    self.cancelButton.layer.shadowOpacity = 0.3

                })
                self.collectionView.isScrollEnabled = false
                self.collectionView.reloadData()
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.navigationController?.navigationBar.isHidden = false
            self.toolBarView.isHidden = false
            self.saveButton.isHidden = true
            self.cancelButton.isHidden = true
        })
        self.collectionView.isScrollEnabled = true
        currentCell?.resizableView.removeFromSuperview()
        self.collectionView.reloadData()
    }
    
    func saveSignature(selectedImage: Image) {
        
        selectedImage.data = NSData(data: (combinedImage?.jpegData(compressionQuality: 0.3))!) as Data
        
        let viewController = UIApplication.shared.windows[0].rootViewController?.children[0] as! ViewController
        do {
            try viewController.managedObjectContext.save()
            print("saving complete")
        }catch {
            print("could not save data for insertion \(error.localizedDescription)")
        }
    }
    
    func mergeImages(imageView: UIImageView) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, 0.0)
        imageView.superview!.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    @IBAction func deleteButton(_ sender: Any) {
        
        let viewController = UIApplication.shared.windows[0].rootViewController?.children[0] as! ViewController
        
        let alert = UIAlertController(title: "Are you sure you want to delete this page?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            
            let visibleRect = CGRect(origin: self.collectionView.contentOffset, size: self.collectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            let visibleIndexPath = self.collectionView.indexPathForItem(at: visiblePoint)
            var arrayOfImages = self.selectedDoc?.image?.sortedArray(
                using: [NSSortDescriptor(key:"pageNumber", ascending: true)]) as! [Image]
            if let image = arrayOfImages[(visibleIndexPath?.item)!] as? Image {
                if arrayOfImages.count > 1 {
                    self.deletePage(selectedPage: image)
                    arrayOfImages.remove(at: (visibleIndexPath?.item)!)
                    self.collectionView?.deleteItems(at: [[0, (visibleIndexPath?.item)!]])
                    viewController.collectionView.reloadData()
                    viewController.collectionViewB.reloadData()
                    
                    if (visibleIndexPath?.item)! > 0 {
                        if visibleIndexPath?.item != arrayOfImages.count {
                            for page in arrayOfImages[(visibleIndexPath?.item)!..<arrayOfImages.count] {
                                page.pageNumber -= 1
                            }
                        }
                    } else {
                        for page in arrayOfImages[0..<arrayOfImages.count] {
                            page.pageNumber -= 1
                        }
                    }
                } else {
                    viewController.deleteDocument(selectedDoc: self.selectedDoc!)
                    if let navController = self.navigationController {
                        navController.popViewController(animated: true)
                    }
                }
            }
        }))
        self.present(alert, animated: true)
    }
    
    func deletePage(selectedPage: Image) {
        
        let viewController = UIApplication.shared.windows[0].rootViewController?.children[0] as! ViewController
        self.selectedDoc?.removeFromImage(selectedPage)
        do {
            try viewController.managedObjectContext.save()
            print("saving complete")
        }catch {
            print("could not save data for insertion \(error.localizedDescription)")
        }
    }

    @IBAction func shareImage(_ sender: Any) {
        
        let viewController = UIApplication.shared.windows[0].rootViewController?.children[0] as! ViewController
        let arrayOfImages = selectedDoc?.image?.sortedArray(
            using: [NSSortDescriptor(key:"pageNumber", ascending: true)]) as! [Image]

        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        if let cell = collectionView.cellForItem(at: visibleIndexPath!) as? PageCollectionViewCell {
            self.combinedImage = self.mergeImages(imageView: cell.mainImageView)
        }
        if let image = arrayOfImages[(visibleIndexPath?.item)!] as? Image {
            // set up activity view controller
            let img = UIImage(data: image.data!) //combinedImage
            let pdfImage = createPDFDataFromImage(image: img!)
            let imageToShare = [pdfImage] as [Any]
            let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            
            // exclude some activity types from the list (optional)
            //activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
            
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func createPDFDataFromImage(image: UIImage) -> NSMutableData {
        let pdfData = NSMutableData()
        let imgView = UIImageView.init(image: image)
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        UIGraphicsBeginPDFContextToData(pdfData, imageRect, nil)
        UIGraphicsBeginPDFPage()
        let context = UIGraphicsGetCurrentContext()
        imgView.layer.render(in: context!)
        UIGraphicsEndPDFContext()
        
        //try saving in doc dir to confirm:
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let path = dir?.appendingPathComponent("file.pdf")
        
        do {
            try pdfData.write(to: path!, options: NSData.WritingOptions.atomic)
        } catch {
            print("error catched")
        }
        
        return pdfData
    }
    
    @IBAction func addPage(_ sender: Any) {
        
        let alert = UIAlertController(title: "Scan new page or pick from photos?", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Scan", style: .default, handler: { action in
            self.initScanner()
        }))
        alert.addAction(UIAlertAction(title: "Photos", style: .default, handler: { action in
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        // You are responsible for carefully handling the error
        print(error)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        // The user successfully scanned an image, which is available in the ImageScannerResults
        var newImage = UIImage.init(named: "myimage")
        if results.doesUserPreferEnhancedImage == true {
            newImage = results.enhancedImage
        } else {
            newImage = results.scannedImage
        }
        
        scanner.dismiss(animated: true)
        let viewController = UIApplication.shared.windows[0].rootViewController?.children[0] as! ViewController
        viewController.addPage(with: newImage!, to: selectedDoc!)
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        // The user tapped 'Cancel' on the scanner
        // You are responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true)
    }
    
    func initScanner() {
        
        let scannerViewController = ImageScannerController()
        scannerViewController.imageScannerDelegate = self
        present(scannerViewController, animated: true)
        
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {

            let viewController = UIApplication.shared.windows[0].rootViewController?.children[0] as! ViewController
            viewController.addPage(with: pickedImage, to: selectedDoc!)
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let images = selectedDoc?.image?.allObjects as? [Image] {
            return images.count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "pageCell", for: indexPath) as! PageCollectionViewCell

        let arrayOfImages = selectedDoc?.image?.sortedArray(
            using: [NSSortDescriptor(key:"pageNumber", ascending: true)]) as! [Image]
            
        if let cellImage = UIImage(data: (arrayOfImages[indexPath.item].data)!) {
            cell.setCellwithImage(image: cellImage)
            tempIndexPath = indexPath
        }
        return cell
    }
}


extension FullScreenViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: view.frame.width, height: view.frame.height)
    }
    
}

