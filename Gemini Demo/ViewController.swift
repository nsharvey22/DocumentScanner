//
//  ViewController.swift
//  Gemini Demo
//
//  Start building your own apps today. Get my 7 day app action plan here:
//  https://codewithchris.com/actionplan/
//
//  Photos used: rawpixel.com, PixaSquare, Naveen Annam, Murilo Folgosi and Chloe Kala from Pexels 

import UIKit
import Gemini
import WeScan
import AVKit
import Photos
import CoreData
import MessageUI


class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ImageScannerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var targetIndex:Int = 0
    var activeCell: MyCell!
    var images = [Image]()
    var documents = [Document]()
    var pages = [UIImage]()
    var searchDoc = [Document]()
    var tempDoc: Document?
    var searching = false
    let collcetionViewSize = CGSize(width: 300, height: 400)
    var collectionViewBSize:CGSize?
    var columnLayout = true
    var selectedDoc:Document?
    let imagePicker = UIImagePickerController()

    var managedObjectContext:NSManagedObjectContext!
    var savedImagePath:String?
    var searchBar: UISearchBar!
    var effect:UIVisualEffect!
    var effectB:UIVisualEffect!
    @IBOutlet weak var collectionView: GeminiCollectionView!
    @IBOutlet weak var collectionViewB: UICollectionView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet var visualEffectViewB: UIVisualEffectView!
    
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet var rowAndColumnContainer: UIView!
    @IBOutlet weak var imageSearchBar: UISearchBar!
    @IBOutlet var searchContainer: UIView!
    @IBOutlet weak var addDocButton: UIBarButtonItem!
    @IBOutlet weak var switchViewButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var defaultAddDoc: UIButton!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpNavBar()
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        self.loadData()
        
        imagePicker.delegate = self
        
        effect = visualEffectView.effect
        visualEffectView.effect = nil

        
        setUpCollectionView()
        collectionViewBSize = CGSize(width: self.collectionViewB.frame.width/3, height: 120)
        let swipeLeft : UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.userDidSwipeLeft(_:)))
        swipeLeft.direction = .left
        collectionView?.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.userDidSwipeRight))
        swipeRight.direction = .right
        collectionView?.addGestureRecognizer(swipeRight)
        
        //self.collectionView?.backgroundColor = UIColor(patternImage: UIImage(named: "cork")!)
        
        self.collectionViewB.reloadData()
        self.collectionViewB.setNeedsLayout()
        self.collectionViewB.layoutIfNeeded()
        self.collectionViewB.reloadData()
        
        collectionView.dragDelegate = self
        collectionViewB.dragDelegate = self
        collectionView.dropDelegate = self
        collectionViewB.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionViewB.dragInteractionEnabled = true
        collectionViewB.reorderingCadence = .fast

    }
    
    func setUpCollectionView() {
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionViewB.dataSource = self
        collectionViewB.delegate = self
        
        // Configure the animation
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionView.gemini
            .customAnimation()
            .scale(x: 0.75, y: 0.75)
            .scaleEffect(.scaleUp) // or .scaleDown
            .rotationAngle(x: 3)
            .ease(.easeOutExpo)
            .shadowEffect(.fadeIn)
            .maxShadowAlpha(0.3)
        if #available(iOS 11.0, *) {
            // contentOffset was getting adjusted automatically, this fixes it to never get adjusted
            collectionView.contentInsetAdjustmentBehavior = .never
        }

        if documents == [] {
            collectionView?.isHidden = true
            collectionViewB?.isHidden = true
            defaultAddDoc.isHidden = false
        } else {
            collectionView?.isHidden = false
            collectionViewB?.isHidden = false
            defaultAddDoc.isHidden = true
        }
    }
    
    func setUpNavBar() {
        
        self.title = "Documents"
        //self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        addDocButton.isEnabled = !editing
        searchButton.isEnabled = !editing
        switchViewButton.isEnabled = !editing
        
        if let indexPaths = collectionViewB?.indexPathsForVisibleItems {
            for indexPath in indexPaths {
                if let cell = collectionViewB.cellForItem(at: indexPath) as? MyCollectionViewCell {
                    cell.isEditing = editing
                }
            }
        }
    }
    
    @IBAction func deleteCell(_ sender: Any) {

        let indexPath = collectionView?.indexPath(for: activeCell)
        self.saveChanges(document: documents[(indexPath?.row)!], action: "delete")
        documents.remove(at: (indexPath?.row)!)
        self.collectionView?.deleteItems(at: [indexPath!])
        
        if documents.count > 1 {
            if indexPath!.row  > 0 {
                if indexPath!.row != self.documents.count - 1 {
                    for document in self.documents[indexPath!.row..<self.documents.count] {
                        document.id -= 1
                    }
                }
                collectionView.scrollToItem(at: [0, (indexPath?.row)! - 1], at: .centeredVertically, animated: true)
            } else {
                for document in self.documents[0..<self.documents.count] {
                    document.id -= 1
                }
                collectionView.scrollToItem(at: [0, 0], at: .centeredVertically, animated: true)
            }
        } else {
            for document in self.documents[0..<self.documents.count] {
                document.id -= 1
            }
        }
        if documents == [] {
            collectionView?.isHidden = true
            collectionViewB?.isHidden = true
        }
        
    }
    
    func deleteDocument(selectedDoc: Document) {
 
        if let indexOfImage = documents.firstIndex(of: selectedDoc) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                self.saveChanges(document: self.documents[indexOfImage], action: "delete")
                self.documents.remove(at: indexOfImage)
                self.collectionView?.deleteItems(at: [[0, indexOfImage]])
                if !self.columnLayout {
                    self.collectionViewB.reloadData()
                }
                if self.documents.count > 1 {
                    if indexOfImage > 0 {
                        if indexOfImage != self.documents.count - 1 {
                            for document in self.documents[indexOfImage..<self.documents.count] {
                                document.id -= 1
                            }
                        }
                        if self.columnLayout {
                            self.collectionView.scrollToItem(at: [0, indexOfImage - 1], at: .centeredVertically, animated: true)
                        }
                    } else {
                        for document in self.documents[0..<self.documents.count] {
                            document.id -= 1
                        }
                        if self.columnLayout {
                            self.collectionView.scrollToItem(at: [0, 0], at: .centeredVertically, animated: true)
                        }
                    }
                } else {
                    for document in self.documents[0..<self.documents.count] {
                        document.id -= 1
                    }
                }
            })
            self.collectionViewB.reloadData()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
            if self.documents == [] {
                self.collectionView?.isHidden = true
                self.collectionViewB?.isHidden = true
            }
        })
    }
    
    @IBAction func cancelSearchButton(_ sender: UIButton) {
        
        animateOut()
        UIView.animate(withDuration: 2.5, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }, completion: nil)
        
    }
    
    @IBAction func defaultAddDocAction(_ sender: Any) {
        addDocument()
    }
    
    @IBAction func defaultAddDocAction2(_ sender: Any) {
        addDocument()
    }
    
    func addDocument() {
        
        let alert = UIAlertController(title: "Scan new document or pick from photos?", message: nil, preferredStyle: .alert)
        
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
    
    @IBAction func addDocButton(_ sender: UIBarButtonItem) {
        addDocument()
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            dismiss(animated: true, completion: nil)
            self.addName(with: pickedImage)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func searchButton(_ sender: UIBarButtonItem) {
        
        animateIn()
        UIView.animate(withDuration: 2.5, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }, completion: nil)
        
    }
    
    func saveChanges(document: Document, action: String) {
        if action == "delete" {
            managedObjectContext.delete(document)
            
        } else if action == "insert" {
           // managedObjectContext.insert(document)
        }
        do {
            try self.managedObjectContext.save()
            print("saving complete")
        }catch {
            print("could not save data for insertion \(error.localizedDescription)")
        }
    }
    
    func loadData() {

        let documentRequest:NSFetchRequest<Document> = Document.fetchRequest()
        do {
            documents = try managedObjectContext.fetch(documentRequest)
            documents = documents.sorted(by: { $0.id < $1.id })
            self.collectionView.reloadData()
            self.collectionViewB.reloadData()
        }catch {
            print("Could not load data from database \(error.localizedDescription)")
        }
        
        let imageRequest:NSFetchRequest<Image> = Image.fetchRequest()

        do {
            images = try managedObjectContext.fetch(imageRequest)
            self.collectionView.reloadData()
            self.collectionViewB.reloadData()
        }catch {
            print("Could not load data from database \(error.localizedDescription)")
        }
    }
    
    func animateOut() {
        print("animating out", columnLayout)
        searchContainer.alpha = 1
        if columnLayout == true {
            print("effect1")
            UIView.animate(withDuration: 0.4) {
                self.visualEffectView.effect = nil
                self.searchContainer.alpha = 0
                self.searchContainer.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
            }
        }else {
            print("effect2")
            UIView.animate(withDuration: 0.4) {
                self.visualEffectViewB.alpha = 0
                self.searchContainer.alpha = 0
                self.searchContainer.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
            }
        }
        searchContainer.removeFromSuperview()
        visualEffectViewB.removeFromSuperview()
    }
    
    func animateIn() {
        
        self.view.addSubview(visualEffectViewB)
        self.view.addSubview(searchContainer)
        let horizontalConstraint = searchContainer.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        let topConstraint = searchContainer.topAnchor.constraint(equalTo: self.view.topAnchor)
        NSLayoutConstraint.activate([horizontalConstraint, topConstraint])
        self.visualEffectViewB.frame = CGRect(x:0, y: 0, width:self.view.frame.width, height:self.view.frame.height)
        searchContainer.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        searchContainer.alpha = 0
        //visualEffectViewB.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        visualEffectViewB.alpha = 0

            if columnLayout == true {
                print("effect1")
                UIView.animate(withDuration: 0.4) {
                    self.visualEffectView.effect = self.effect
                    self.searchContainer.alpha = 1
                    self.searchContainer.transform = CGAffineTransform.identity
                }
            }else {
                print("effect2")
                UIView.animate(withDuration: 0.4) {
                    self.visualEffectViewB.alpha = 1
                    self.visualEffectViewB.transform = CGAffineTransform.identity
                    self.searchContainer.alpha = 1
                    self.searchContainer.transform = CGAffineTransform.identity
                }
                print(self.effectB)
            }
    }
    
    @IBAction func switchView(_ sender: UIBarButtonItem) {
        
        callSwitch()
    }
    
    func callSwitch() {
        
        if columnLayout == true {
            self.collectionViewB.reloadData()
            self.navigationItem.leftBarButtonItems = [switchViewButton, editButtonItem]
            self.columnLayout = false
            switchViewButton.image = UIImage(named: "column")
            self.collectionView.isUserInteractionEnabled = false
            self.view.addSubview(rowAndColumnContainer)
            let horizontalConstraint = rowAndColumnContainer.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
            // let topConstraint = rowAndColumnContainer.topAnchor.constraint(equalTo: self.collectionView.topAnchor)
            self.rowAndColumnContainer.frame = CGRect(x:0, y: 0, width:self.view.frame.width, height:self.view.frame.height)
            NSLayoutConstraint.activate([horizontalConstraint])
            
            rowAndColumnContainer.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            rowAndColumnContainer.alpha = 0
            
            UIView.animate(withDuration: 0.4) {
                self.rowAndColumnContainer.alpha = 1
                self.rowAndColumnContainer.transform = CGAffineTransform.identity
            }
        } else {
            self.collectionView.reloadData()
            self.navigationItem.leftBarButtonItems = [switchViewButton]
            self.columnLayout = true
            switchViewButton.image = UIImage(named: "layout")
            self.collectionView.isUserInteractionEnabled = true
            rowAndColumnContainer.alpha = 1
            UIView.animate(withDuration: 0.4) {
                self.rowAndColumnContainer.alpha = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                self.rowAndColumnContainer.removeFromSuperview()
            })
        }
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
        self.addName(with: newImage!)
    }
    
    func addName(with image:UIImage) {
        
        let documentItem = Document(context: managedObjectContext)
        let imageItem = Image(context: managedObjectContext)
        imageItem.data = NSData(data: image.jpegData(compressionQuality: 0.3)!) as Data
        imageItem.pageNumber = 1
        
        let inputAlert = UIAlertController(title: "New Document", message: "Enter name", preferredStyle: .alert)
        inputAlert.addTextField { (textfield:UITextField) in
            textfield.placeholder = "Name"
        }
        
        inputAlert.addAction(UIAlertAction(title: "Save", style: .default, handler:  { (action:UIAlertAction) in
            
            let nameTextField = inputAlert.textFields?.first
            
            if nameTextField?.text != "" {
                
                documentItem.name = nameTextField?.text
                documentItem.pages = 1
                documentItem.id = Int16(self.documents.count)
                documentItem.addToImage(imageItem)
                print("id :", documentItem.id)
                do {
                    try self.managedObjectContext.save()
                    self.loadData()
                    
                    let indexOfImage = self.documents.firstIndex(of: documentItem) as! Int
                    if self.columnLayout == true {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                            self.collectionView.scrollToItem(at: [0, indexOfImage], at: .centeredVertically, animated: true)
                        })
                    }
                }catch {
                    print("could not save data \(error.localizedDescription)")
                }
            }
            if self.collectionView?.isHidden == true {
                self.collectionView?.isHidden = false
                self.collectionViewB?.isHidden = false
            }
        }))
        
        inputAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(inputAlert, animated: true, completion: nil)
    }
    
    
    func addPage(with image:UIImage, to document:Document) {
        
        let imageItem = Image(context: managedObjectContext)
        imageItem.data = NSData(data: image.jpegData(compressionQuality: 0.3)!) as Data
        let arrayOfImages = document.image?.sortedArray(
            using: [NSSortDescriptor(key:"pageNumber", ascending: true)]) as! [Image]
        let pageNum = arrayOfImages.count + 1
        imageItem.pageNumber = Int16(pageNum)
        
        document.addToImage(imageItem)
        
        do {
            try self.managedObjectContext.save()
            self.loadData()
            let arrayOfImages = selectedDoc?.image?.sortedArray(
                using: [NSSortDescriptor(key:"pageNumber", ascending: true)]) as! [Image]
            let indexOfImage = arrayOfImages.count - 1
            
            let viewController = UIApplication.shared.windows[0].rootViewController?.children[1] as! FullScreenViewController
            viewController.collectionView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                viewController.collectionView.scrollToItem(at: [0, indexOfImage], at: .left, animated: true)
            })
            
        }catch {
            print("could not save data \(error.localizedDescription)")
        }
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
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>){
        
        if scrollView == self.collectionView {
            if let collectionView = collectionView {

                targetContentOffset.pointee = scrollView.contentOffset
                let pageHeight = 410
                var assistanceOffset : CGFloat = CGFloat(pageHeight/2)
                
                if velocity.y < 0 {
                    print("velocity-: ", velocity.y)
                    assistanceOffset = -assistanceOffset
                }
                if velocity.y > 0 {
                    print("velocity+: ", velocity.y)
                    assistanceOffset = abs(assistanceOffset)
                }
                if velocity.y == 0 {
                    assistanceOffset = 0
                }
                
                let assistedScrollPosition = (scrollView.contentOffset.y + assistanceOffset) / CGFloat(pageHeight)
                self.targetIndex = Int(round(assistedScrollPosition))
       
                if targetIndex < 0 {
                    targetIndex = 0
                }
                else if targetIndex >= collectionView.numberOfItems(inSection: 0) {
                    targetIndex = collectionView.numberOfItems(inSection: 0) - 1
                }
       
                let indexPath = NSIndexPath(item: targetIndex, section: 0)
                collectionView.scrollToItem(at: indexPath as IndexPath, at: .centeredVertically, animated: true)
            }
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // If clicked on another cell than the swiped cell
        let cell = collectionView.cellForItem(at: indexPath)
        if activeCell != nil && activeCell != cell {
            userDidSwipeRight()
        }
        self.selectedDoc = self.documents[indexPath.row]
        setEditing(false, animated: false)
        self.performSegue(withIdentifier: "goToDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetail" {
            print("seguing")
            if let detailViewController = segue.destination as? FullScreenViewController {
                    detailViewController.selectedDoc = self.selectedDoc
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.documents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gemCell", for: indexPath) as! MyCell

        let documentItem = documents[indexPath.row]
        let docImages = documents[indexPath.row].image?.sortedArray(
            using: [NSSortDescriptor(key:"pageNumber", ascending: true)]) as! [Image]
        let frontImage = docImages.first?.data

        if let cellImage = UIImage(data: frontImage!) {
            cell.setCellwithImage(image: cellImage)
        }
        if let cellTitle = documentItem.name {
            cell.setCellwithTitle(title: cellTitle)
        }

        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 10.0)
        cell.layer.shadowRadius = 12.0
        cell.layer.shadowOpacity = 0.3
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.mainImageView.layer.cornerRadius).cgPath
        cell.layer.backgroundColor = UIColor.clear.cgColor
        
        // Animate
        self.collectionView.animateCell(cell)

        return cell
            
        } else {
            let cellB = collectionView.dequeueReusableCell(withReuseIdentifier: "protoCell", for: indexPath) as! MyCollectionViewCell

            let documentItem = documents[indexPath.row]
            let docImages = documents[indexPath.row].image?.sortedArray(
                using: [NSSortDescriptor(key:"pageNumber", ascending: true)]) as! [Image]

            let frontImage = docImages.first?.data
            print(docImages.count)
  
            if let cellImage = UIImage(data: frontImage!) {
                cellB.setCellwithImage(image: cellImage)
                print("count: ", docImages.count)
                cellB.setCellwithExtraPages(num: docImages.count - 1)
            }
            if let cellTitle = documentItem.name {
                cellB.setCellwithTitle(title: cellTitle)
            }
            
            cellB.layer.shadowColor = UIColor.black.cgColor
            cellB.layer.shadowOffset = CGSize(width: 0, height: 10.0)
            cellB.layer.shadowRadius = 5.0
            cellB.layer.shadowOpacity = 0.5
            cellB.layer.masksToBounds = false
            cellB.layer.backgroundColor = UIColor.clear.cgColor
            
            cellB.delegate = self

            return cellB
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("contentoffset: ", scrollView.contentOffset.y)
        // Animate
        self.collectionView.animateVisibleCells()
        if(activeCell != nil){
            UIView.animate(withDuration: 0.2, animations: {
                self.activeCell.mainImageView.transform = CGAffineTransform.identity
                self.activeCell.documentTitle.transform = CGAffineTransform.identity
            }, completion: {
                (Void) in
                self.activeCell = nil
            })
            self.activeCell.deleteButton.isUserInteractionEnabled = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Animate
        if let cell = cell as? MyCell {
            self.collectionView.animateCell(cell)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = self.documents[sourceIndexPath.row]
        self.documents.remove(at: sourceIndexPath.row)
        self.documents.insert(item, at: destinationIndexPath.row)
    }
    
    func getCellAtPoint(_ point: CGPoint) -> MyCell? {
        // Function for getting item at point. Note optionals as it could be nil
        let indexPath = collectionView?.indexPathForItem(at: point)
        var cell : MyCell?
        
        if indexPath != nil {
            cell = collectionView?.cellForItem(at: indexPath!) as? MyCell
        } else {
            cell = nil
        }
        
        return cell
    }
    
    @objc func userDidSwipeLeft(_ gesture : UISwipeGestureRecognizer){
        
        let point = gesture.location(in: collectionView)
        //let tapPoint = tap.location(in: collectionView)
        let duration = animationDuration()
        
        if(activeCell == nil){
            
            activeCell = getCellAtPoint(point)
            print("user swipped left 1st time at: ", point)
            if activeCell != nil {
                UIView.animate(withDuration: duration, animations: {
                    self.activeCell.mainImageView.transform = CGAffineTransform(translationX: -self.activeCell.frame.width/2, y: 0)
                    self.activeCell.documentTitle.transform = CGAffineTransform(translationX: -self.activeCell.frame.width/2, y: 0)
                });
                self.activeCell.deleteButton.isUserInteractionEnabled = true
            }
        } else {
            // Getting the cell at the point
            let cell = getCellAtPoint(point)
            
            // If the cell is the previously swiped cell, or nothing assume its the previously one.
            if cell == nil || cell == activeCell {
                // To target the cell after that animation I test if the point of the swiping exists inside the now twice as tall cell frame
                let cellFrame = activeCell.frame
                let rect = CGRect(x: cellFrame.origin.x - cellFrame.width, y: cellFrame.origin.y, width: cellFrame.width*2, height: cellFrame.height)
                
                if rect.contains(point) {
                    print("Swiped inside cell")
                    // If swipe point is in the cell delete it
                    
                    let indexPath = collectionView?.indexPath(for: activeCell)
                    documents.remove(at: (indexPath?.row)!)
                    self.collectionView?.deleteItems(at: [indexPath!])
                    if documents.count > 1 {
                        if indexPath!.row  > 0 {
                            collectionView.scrollToItem(at: [0, (indexPath?.row)! - 1], at: .centeredVertically, animated: true)
                        }
                    }
                }
                // If another cell is swiped
            } else if activeCell != cell {
                // It's not the same cell that is swiped, so the previously selected cell will get unswiped and the new swiped.
                UIView.animate(withDuration: duration, animations: {
                    self.activeCell.mainImageView.transform = CGAffineTransform.identity
                    cell!.mainImageView.transform = CGAffineTransform(translationX: -cell!.frame.width/2, y: 0)
                }, completion: {
                    (Void) in
                    self.activeCell = cell
                })
            }
        }
    }
    
    @objc func userDidSwipeRight(){
        // Revert back
        if(activeCell != nil){
            let duration = animationDuration()
            print("user swiped right")
            UIView.animate(withDuration: duration, animations: {
                self.activeCell.mainImageView.transform = CGAffineTransform.identity
                self.activeCell.documentTitle.transform = CGAffineTransform.identity
            }, completion: {
                (Void) in
                self.activeCell = nil
            })
            self.activeCell.deleteButton.isUserInteractionEnabled = false
        }
    }

    
    func animationDuration() -> Double {
        return 0.2
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchDoc.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        if searching {
            if let images = searchDoc[indexPath.row].image?.allObjects as? [Image] {
                cell?.imageView!.image = UIImage(data: (images.first?.data)!)
            }
        }
        if searching {
            cell?.textLabel?.text = searchDoc[indexPath.row].name
            cell?.textLabel?.textColor = .white
        }
     
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        searchBarCancelButtonClicked(imageSearchBar)
        
        if columnLayout == false {
            self.callSwitch()
        }
        
        var selectedDoc = searchDoc[indexPath.row]
        
        let indexOfDoc = documents.firstIndex(of: selectedDoc) as! Int
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
            self.collectionView.scrollToItem(at: [0, indexOfDoc], at: .centeredVertically, animated: true)
        })
    }
}


extension ViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchBar.text != "" {
            searchDoc = documents.filter({$0.name!.lowercased().prefix(searchText.count) == searchText.lowercased()})
            searching = true
            searchTableView.reloadData()
        } else {
            searching = false

            searchTableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searching = false
        searchTableView.reloadData()
        searchBar.text = ""
        animateOut()
        UIView.animate(withDuration: 2.5, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }, completion: nil)
    }
}


extension ViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate, NSFetchedResultsControllerDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        let item = self.documents[indexPath.row].name
        self.tempDoc = self.documents[indexPath.row]
        let itemProvider = NSItemProvider(object: item as! NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath
        {
            destinationIndexPath = indexPath
        }
        else
        {
            // Get last index path of collection view.
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        switch coordinator.proposal.operation
        {
        case .move:
            //Add the code to reorder items
            self.reorderItems(coordinator: coordinator, destinationIndexPath:destinationIndexPath, collectionView: collectionView)
            break
            
        case .copy:
            //Add the code to copy items
            break
            
        default:
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if session.localDragSession != nil
        {
            if collectionView.hasActiveDrag
            {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
            else
            {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        }
        else
        {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }

    
    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView)
    {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath
        {
            var dIndexPath = destinationIndexPath
            if dIndexPath.row >= collectionView.numberOfItems(inSection: 0)
            {
                dIndexPath.row = collectionView.numberOfItems(inSection: 0) - 1
            }
            collectionView.performBatchUpdates({
              //  if collectionView === self.collectionViewB
               // {
                    if sourceIndexPath.row > dIndexPath.row {
                        for document in documents[dIndexPath.row..<documents.count] {
                            document.id += 1
                        }
                        documents[sourceIndexPath.row].id = Int16(dIndexPath.row)
                    } else if sourceIndexPath.row < dIndexPath.row {
                        for document in documents[dIndexPath.row..<documents.count].reversed() {
                            document.id += 1
                        }
                        documents[sourceIndexPath.row].id = Int16(dIndexPath.row)
                    }

                    self.documents.remove(at: sourceIndexPath.row)
                    self.documents.insert(tempDoc!, at: dIndexPath.row)
                    
                    self.saveChanges(document: tempDoc!, action: "insert")
              //  }
              //  else
               // {
//                    self.saveChanges(document: documents[sourceIndexPath.row], action: "delete")
//                    self.documents.remove(at: sourceIndexPath.row)
//                    self.saveChanges(document: tempDoc!, action: "insert")
//                    self.documents.insert(tempDoc!, at: dIndexPath.row)
              //  }
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [dIndexPath])
            })
            coordinator.drop(items.first!.dragItem, toItemAt: dIndexPath)
            if !addDocButton.isEnabled {
                setEditing(true, animated: true)
            }
        }
    }
}



extension ViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView {
            return collcetionViewSize
        }else {
            
            let width = ((UIScreen.main.bounds.width - 50)/3)
            
            let height = width * (297/210) + 40// A4 Size
            
            return CGSize(width: width, height: height);
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == self.collectionView {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
            
        switch layout.scrollDirection {
        case .horizontal:
            
            let verticalMargin: CGFloat = (collectionView.bounds.height - collcetionViewSize.height) / 2
            return UIEdgeInsets(top: 0,
                                left: 0,
                                bottom: 0,
                                right: 0)
        case .vertical:
            let horizontalMargin: CGFloat = (collectionView.bounds.width - collcetionViewSize.width) / 2
            return UIEdgeInsets(top: (collectionView.bounds.height - 400) / 4 + 105,
                                left: 50 + horizontalMargin,
                                bottom: (collectionView.bounds.height - 400) / 4 + 105,
                                right: 50 + horizontalMargin)
        }
        }else {
            return UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == self.collectionView{
            return 10
        }
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
  
        return 10
    }
    
}

extension ViewController: MyCollectionViewCellDelegate {
    
    func delete(cell: MyCollectionViewCell) {
        if let indexPath = collectionViewB.indexPath(for: cell) {
            
            self.saveChanges(document: self.documents[indexPath.item], action: "delete")
            self.documents.remove(at: indexPath.item)
            self.collectionViewB?.deleteItems(at: [indexPath])
            if self.documents.count > 1 {
                if indexPath.item > 0 {
                    if indexPath.item != self.documents.count - 1 {
                        for document in self.documents[indexPath.item..<self.documents.count] {
                            document.id -= 1
                        }
                    }
                } else {
                    for document in self.documents[0..<self.documents.count] {
                        document.id -= 1
                    }
                }
            } else {
                for document in self.documents[0..<self.documents.count] {
                    document.id -= 1
                }
            }
            if documents == [] {
                collectionView?.isHidden = true
                collectionViewB?.isHidden = true
            }
            self.setEditing(false, animated: false)
        }
    }
}

