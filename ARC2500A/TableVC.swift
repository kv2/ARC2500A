//
//  TableVC.swift
//  ARC2500A
//
//  Created by john doe on 12/3/18.
//  Copyright © 2018 Kirill Volchinskiy. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import ARKit
import ZIPFoundation


class TableVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let storyBoardSegue = "TableVCSegueToARViewVC"
    let serverURLString = "https://kirillvolchinskiy.com/apps/ARC2500A_Version_2/"
    let arrayStudents = NSMutableArray()
    var selectedStudent = DataModelStudent()
    let modelsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    var alert = UIAlertController()
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")
    
    var colorCustomBlue = UIColor()
    var colorCustomLightBlue = UIColor()
    var colorCustomRed = UIColor()
    var colorCustomLightRed = UIColor()
    
    @IBOutlet var reLoadButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    var refreshControl = UIRefreshControl()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
        tableView.register(TableCell.self, forCellReuseIdentifier: "TableVCCell1")
        //tableView.backgroundColor = UIColor.clear
        
        self.colorCustomBlue = colorWithHexString(hexString: "00AD78")
        self.colorCustomRed = colorWithHexString(hexString: "FF5A2C")
        self.colorCustomLightBlue = colorWithHexString(hexString: "00e09b")
        self.colorCustomLightRed = colorWithHexString(hexString: "ff825f")
        
        self.setupRefreshControl()
        self.startNetworkReachabilityObserver()
        
        self.retrieveData()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.endRefreshingSpinner()
        
        
    }
    
    func setupRefreshControl() {
        
        let attributes = [NSAttributedString.Key.foregroundColor: colorCustomRed]
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to reload AR Models", attributes: attributes)
        refreshControl.tintColor = colorCustomRed
        
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
    }
    
    @objc func refresh() {
        
        Alamofire.Session.default.session.getAllTasks { (tasks) in
            tasks.forEach{ $0.cancel() }
        }
        self.retrieveData()
        
    }
    
    func retrieveData(){
        
        NSLog("retrieve Data")
        
        arrayStudents.removeAllObjects()
        
       
        AF.request(serverURLString).responseJSON { (response) -> Void in
        
            
            guard (response.value as? [[String:String]]) != nil else{
                
                self.endRefreshingSpinner()
                
                print("Error: \(String(describing: response.error))")
                
                self.presentAlert(message: "Server Error. Please check your connection and try again.")
                return
            }
            
            // checking if result has value
            if let value = response.value {
                
                let json = JSON(value)
                var currentStudentIndex = 0
                
                for studentDictionary in json.array! {
                    
                    let studentObject = DataModelStudent()
                    
                    if let name = studentDictionary["name"].string {
        
                        studentObject.name = name
                        studentObject.fileID = studentDictionary["fileID"].string
                        studentObject.imagePath = studentDictionary["imagePath"].string
                        studentObject.modelPath = studentDictionary["modelPath"].string
                        
                    } else {
                        
                        self.endRefreshingSpinner()
                        
                        self.presentAlert(message: "Server Error. Please check your connection and try again.")
                        NSLog("Server Error")
                    }
                
                    // download the image
                    AF.request(studentObject.imagePath).responseData { (response) in if response.error == nil {
                        print(response.result)

                            // store the downloaded image:
                            if let data = response.data {
                                studentObject.image = UIImage(data: data)
                                NSLog("downloaded image %d of %d",currentStudentIndex,json.array!.count)
                                
                    
                                if(currentStudentIndex == json.array!.count-1){
                                                                   
                                   NSLog("last image downloaded")
                                   self.endRefreshingSpinner()
                                    
                                }
                                
                                currentStudentIndex += 1
                                self.arrayStudents .add(studentObject)
                                
                                DispatchQueue.main.async {self.tableView.reloadData()}
                                                                   
                                                            
                            }
                        }
                    }
                    
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            }
            
        }
        
    }
    

    
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return arrayStudents.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableVCCell", for: indexPath) as! TableCell
       
        
        if (indexPath.row > arrayStudents.count - 1) {
            
            return cell
        }
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = colorCustomLightRed
        cell.selectedBackgroundView = backgroundView
      
        let studentObject = arrayStudents .object(at: indexPath.row) as! DataModelStudent
        
        if((studentObject.modelPath) == nil){
            cell.textLabel?.textColor = colorCustomLightBlue
            cell.isUserInteractionEnabled = false
            
        } else {
            
            cell.textLabel?.textColor = colorCustomBlue
            cell.isUserInteractionEnabled = true
        }
        
        let imageviewSize = 32
        
        cell.imageView?.layer.borderColor = colorCustomBlue.cgColor
        cell.imageView?.layer.borderWidth = 1.0
        cell.imageView?.layer.cornerRadius = CGFloat(imageviewSize/2);
        cell.imageView?.clipsToBounds = true
        
        if((studentObject.image) != nil){
            
            self.roundedImage(image: studentObject.image, completion: { (roundImage) -> (Void) in
                
                cell.imageView?.image = roundImage
                
                let itemSize = CGSize.init(width: imageviewSize, height: imageviewSize)
                UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale);
                let imageRect = CGRect.init(origin: CGPoint.zero, size: itemSize)
                cell.imageView?.image!.draw(in: imageRect)
                cell.imageView?.image! = UIGraphicsGetImageFromCurrentImageContext()!;
                UIGraphicsEndImageContext();
                
            })
            
        } else {
            
            print("studentObject.image is nil")
        }
        
        cell.textLabel?.text = studentObject.name.uppercased()
        
//        let itemSize = CGSize.init(width: 35, height: 35)
//        UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale);
//        let imageRect = CGRect.init(origin: CGPoint.zero, size: itemSize)
//        cell?.imageView?.image!.draw(in: imageRect)
//        cell?.imageView?.image! = UIGraphicsGetImageFromCurrentImageContext()!;
//        UIGraphicsEndImageContext();
    
//        cell.textLabel?.textColor = UIColor.white
//        cell.backgroundColor = UIColor.clear
    
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        
        if (indexPath.row > arrayStudents.count - 1) {
            NSLog("broken")
            return nil
        }
        
        let student =  arrayStudents.object(at: indexPath.row) as! DataModelStudent
        
        if((student.modelPath) != nil){
            return indexPath
        }
        
        NSLog("model path is nil")
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        self.selectedStudent = arrayStudents[indexPath.row] as! DataModelStudent
        NSLog("%d",indexPath.row)
        
        self.performSegue(withIdentifier: storyBoardSegue, sender: self)
        
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
    override func prepare(for segue: UIStoryboardSegue,
                 sender: Any?){
        
        if segue.identifier == storyBoardSegue{
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            backItem.tintColor = colorCustomBlue
            navigationItem.backBarButtonItem = backItem
            
            let arViewVC = segue.destination as? ARViewVC
            arViewVC?.student = self.selectedStudent
            
        }
        
    }
    
    func endRefreshingSpinner () {
        
        tableView.reloadData()
        if self.refreshControl.isRefreshing == true {
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        }
        
    }
    
    func reachabilityStatusChanged() {
        
    }
    
    func startNetworkReachabilityObserver() {
        
        alert  = UIAlertController(title: "Network Alert", message: "Error", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")

            case .cancel:
                print("cancel")

            case .destructive:
                print("destructive")

            NSLog("dismissed UIAlert")

            @unknown default:

                NSLog("fail UIAlert")
            }}))
        
     
        self.reachabilityManager?.startListening(onUpdatePerforming: {networkStatusListener in
            
            print("Network Status Changed:", networkStatusListener)
            
               switch networkStatusListener {
               case .notReachable:
                   self.presentAlert(message: "The network is not reachable. Please reconnect to continue using the app.")
                           print("The network is not reachable.")
                   case .unknown :
                           self.presentAlert(message: "It is unknown whether the network is reachable. Please reconnect.")
                           print("It is unknown whether the network is reachable.")
                   case .reachable(.ethernetOrWiFi):
                           print("The network is reachable over the WiFi connection")
               
                   case .reachable(.cellular):
                           print("The network is reachable over the WWAN connection")
            }
   
        })
        
    }

    @IBAction func clearCacheRemoveAllModels(_ sender: UIBarItem) {
        
        alert  = UIAlertController(title: "Clear Cache",
                                   message: "Are you sure you would like to remove and reload all 3D models cached on your device?",
                                   preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                
                self.clearDiskofCache()

            case .cancel:
                print("cancel")

            case .destructive:
                print("dismissed UIAlert")

            @unknown default:
                print("fail UIAlert")
        }}))
        
        self.present(alert, animated: true, completion: nil)
    
    }
    
    func clearDiskofCache (){
    
        let fileManager = FileManager.default
    
        do {

            let arrayFiles = try fileManager.contentsOfDirectory(atPath: modelsDirectory.path)
           
            print ("current files on disk to delete", arrayFiles)
            
            for fileOrFolder in arrayFiles {

                do {
                    
                    try FileManager.default.removeItem(at: modelsDirectory.appendingPathComponent(fileOrFolder))
                    
                } catch {

                    print(error)
                }
            }
            
        } catch {
            
            print(error)
        }
    
    }
    
    func presentAlert(message: String){
        
        alert.dismiss(animated: true, completion: nil)
        alert.message = message
        self.present(alert, animated: true, completion: nil)
        
    }
//
//    func squareImage(from image: UIImage?) -> UIImage? {
//        // Get a square that the image will fit into
//        var maxSize = image!.size.height
//        if(fabsf(Float(image!.size.width)) > fabsf(Float(image!.size.height))){
//
//            maxSize  = image!.size.width
//        }
//
//        let squareSize = CGSize(width: maxSize, height: maxSize)
//
//        // Get our offset to center the image inside our new square frame
//        let dx: CGFloat = (maxSize - (image?.size.width ?? 0.0)) / 2.0
//        let dy: CGFloat = (maxSize - (image?.size.height ?? 0.0)) / 2.0
//
//        UIGraphicsBeginImageContext(squareSize)
//        var rect = CGRect(x: 0, y: 0, width: maxSize, height: maxSize)
//
//        // Draw a white background and set a magenta stroke around the entire square image (debugging only?)
//        let context = UIGraphicsGetCurrentContext()
//        context?.setFillColor(UIColor.white.cgColor)
//        context?.setStrokeColor(UIColor.magenta.cgColor)
//        context?.fill(rect)
//        context?.stroke(rect)
//
//        rect = rect.insetBy(dx: dx, dy: dy)
//        image!.draw(in: rect, blendMode: .normal, alpha: 1.0)
//
//        let squareImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return squareImage
//
//    }
//
    
    func roundedImage(image: UIImage, completion: @escaping ((UIImage?)->(Void))) {
        DispatchQueue.main.async {
            // Begin a new image that will be the new image with the rounded corners
            // (here with the size of an UIImageView)
            
            
            var maxDim = image.size.height
            if(fabsf(Float(image.size.width)) > fabsf(Float(image.size.height))){
                
                maxDim  = image.size.width
            }
            
            let maxSize  = CGSize(width: maxDim, height: maxDim)
            
            UIGraphicsBeginImageContextWithOptions(maxSize, false, image.scale)
            let rect = CGRect(x: 0, y: 0, width: maxDim, height: maxDim)
            
            // Add a clip before drawing anything, in the shape of an rounded rect
            UIBezierPath(roundedRect: rect, cornerRadius: image.size.width/2).addClip()
            
            // Draw your image
            image.draw(in: rect)
            
            // Get the image, here setting the UIImageView image
            guard let roundedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                print("UIGraphicsGetImageFromCurrentImageContext failed")
                completion(nil)
                return
            }
            
            // Lets forget about that we were drawing
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async {
                completion(roundedImage)
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    func colorWithHexString(hexString: String, alpha:CGFloat? = 1.0) -> UIColor {
        
        // Convert hex string to an integer
        let hexint = Int(self.intFromHexString(hexStr: hexString))
        let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
        let alpha = alpha!
        
        // Create color object, specifying alpha as well
        let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }
    
    func intFromHexString(hexStr: String) -> UInt32 {
        var hexInt: UInt32 = 0
        // Create scanner
        let scanner: Scanner = Scanner(string: hexStr)
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        // Scan hex value
        scanner.scanHexInt32(&hexInt)
        return hexInt
    }
    
}
