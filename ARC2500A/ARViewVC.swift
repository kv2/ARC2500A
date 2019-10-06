import UIKit
import SpriteKit
import Alamofire
import ARKit
import ZIPFoundation
import AudioToolbox.AudioServices


struct ImageInformation {
    let name: String
    let description: String
    let image: UIImage
}



class ARViewVC: UIViewController, ARSCNViewDelegate {
    
    var student: DataModelStudent!
    let modelsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    @IBOutlet var labelInstructions: UILabel!
    @IBOutlet var imageViewOverlay: UIImageView!
    @IBOutlet var sceneView: ARSCNView!
    
    var alert = UIAlertController()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupImageViewOverlay()
        
        self.loadNodeWithID(student.fileID, url: student.modelPath) { (arrayStudentSCNNodes) in
            
            //initiate AR setup after downloading model
            self.requestCameraPermissions()
                
            
        }
               
    }
     
    
    func setupImageViewOverlay(){
    
    
        self.imageViewOverlay.image = student.image
        self.imageViewOverlay.contentMode = .scaleAspectFit
        self.imageViewOverlay.alpha = 0.3;
    
    
    }
 
    
    func setupSceneRecognitionSession(){
        
        sceneView.delegate = self
        
//        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
//            fatalError("Missing expected asset catalog resources.")
//        }
//
      
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        //1. Get The Image From The Folder
        guard let imageForRecognition = student.image,
            //2. Convert It To A CIImage
            let imageToCIImage = CIImage(image: imageForRecognition),
            //3. Then Convert The CIImage To A CGImage
            let cgImage = convertCIImageToCGImage(inputImage: imageToCIImage)else { return }
        
        //4. Create An ARReference Image (Remembering Physical Width Is In Metres)
        let arImage = ARReferenceImage(cgImage, orientation: CGImagePropertyOrientation.up, physicalWidth: 0.45)
        
        //5. Name The Image
        arImage.name = student.name
        
        //5. Set The ARWorldTrackingConfiguration Detection Images
        
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = [arImage]
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    
        
    }
    
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        labelInstructions.isHidden = false
        
        
    
        
    }
    


    func loadNodeWithID(_ id: String, url: String, completion: @escaping (Array<SCNNode>?) -> Void) {
           // Check that assets for that model are not already downloaded
           let fileManager = FileManager.default
           let dirForModel = modelsDirectory.appendingPathComponent(id)
           let dirExists = fileManager.fileExists(atPath: dirForModel.path)
    
        
           if dirExists {
               print("directory exists")
               completion(loadNodeWithIdFromDisk(id))
           } else {
               downloadZip(from: url, at: id) {
                   if let url = $0 {
                       print("Downloaded and unzipped at: \(url.absoluteString)")
                       completion(self.loadNodeWithIdFromDisk(id))
                   } else {
                       print("Something went wrong!")
                       completion(nil)
                   }
               }
           }
       }
       
    func loadNodeWithIdFromDisk(_ id: String) -> Array<SCNNode>? {
           let fileManager = FileManager.default
           let dirForModel = modelsDirectory.appendingPathComponent(id)
           do {
               let files = try fileManager.contentsOfDirectory(atPath: dirForModel.path)
               if let scnFile = files.first(where: { $0.hasSuffix(".dae") }) {
               
                   let scene = try? SCNScene(url: dirForModel.appendingPathComponent(scnFile), options: nil)
                   
                         
                    for childNode in (scene?.rootNode.childNodes)! {
                                    
                        self.student.arraySCNNodes.append(childNode)
                        
                    }

                    return self.student.arraySCNNodes
                
               } else {
                   print("No .dae file in directory: \(dirForModel.path)")
                   return nil
               }
           } catch {
               print("Could not enumarate files or load scene: \(error)")
               return nil
           }
        
       }
       
       func downloadZip(from urlString: String, at destFileName: String, completion: ((URL?) -> Void)?) {
           print("Downloading \(urlString)")
           let fullDestName = destFileName + ".zip"
           
        
           let destination: DownloadRequest.Destination = { _, _ in
               let fileURL = self.modelsDirectory.appendingPathComponent(fullDestName)
               return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
           }
           
           AF.download(urlString, to: destination).response { response in
               let error = response.error
               if error == nil {
                if let filePath = response.fileURL?.path {
                       let nStr = NSString(string: filePath)
                       let id = NSString(string: nStr.lastPathComponent).deletingPathExtension
                       //print(response)
                       print("file downloaded at: \(filePath)")
                       let fileManager = FileManager()
                       let sourceURL = URL(fileURLWithPath: filePath)
                       var destinationURL = self.modelsDirectory
                       destinationURL.appendPathComponent(id)
                       do {
                           try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                           try fileManager.unzipItem(at: sourceURL, to: destinationURL)
                           completion?(destinationURL)
                       } catch {
                           completion?(nil)
                           print("Extraction of ZIP archive failed with error: \(error)")
                       }
                   } else {
                       completion?(nil)
                       print("File path not found")
                   }
               } else {
                   // Handle error
                   completion?(nil)
               }
           }
       }
    
       
    
    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
        NSLog("did remove node")
        self.imageIsNotInView ()
        
        
    }
        
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        //let referenceImage = imageAnchor.referenceImage
        
        self.imageIsInView()
        
        NSLog("didAdd node")
    
        let imageAnchorCoordinates = imageAnchor.transform
        print(imageAnchorCoordinates.columns.3.x, imageAnchorCoordinates.columns.3.y , imageAnchorCoordinates.columns.3.z)

       // let imageWidth = imageAnchor.referenceImage.physicalSize.width
       // let imageHeight = imageAnchor.referenceImage.physicalSize.height

        // 2
//
//        let planeNode = SCNNode()
//        let planeGeometry = SCNPlane(width: imageWidth, height: imageHeight)
//        planeGeometry.firstMaterial?.diffuse.contents = UIColor.red
//        planeNode.opacity = 0.25
//        planeNode.geometry = planeGeometry
//
//        //5. Rotate The PlaneNode To Horizontal
//        planeNode.eulerAngles.x = -.pi/2
//
//        //The Node Is Centered In The Anchor (0,0,0)
//        //node.addChildNode(planeNode)
//
//
//        //6. Create AN SCNBox
//        let boxNode = SCNNode()
//        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
//
//        //7. Create A Different Colour For Each Face
//        let faceColours = [UIColor.red, UIColor.green, UIColor.blue, UIColor.cyan, UIColor.yellow, UIColor.gray]
//        var faceMaterials = [SCNMaterial]()
//
//        //8. Apply It To Each Face
//        for face in 0 ..< 5{
//            let material = SCNMaterial()
//            material.diffuse.contents = faceColours[face]
//            faceMaterials.append(material)
//        }
//        boxGeometry.materials = faceMaterials
//        boxNode.geometry = boxGeometry
//
//        //9. Set The Boxes Position To Be Placed On The Plane (node.x + box.height)
//        boxNode.position = SCNVector3(0 , 0.05, 0)
        
        //10. Add The Box To The Node
        //node.addChildNode(boxNode)
        
//
//        let scene1 = SCNScene(named: "art.scnassets/arkit_dae.scn")!
//
//        let node1 = scene1.rootNode.childNode(withName: "test1", recursively: true)!
//
        //let shipNode = scene.rootNode.childNode(withName: "arkit", recursively: false) as! SCNNode
    
        //shipNode.position = SCNVector3(-0.2 , 0, 0)
        
        
        for childNode in (student.arraySCNNodes) {
                                           
            NSLog("loadedNodeWithID %@", childNode.name ?? "nil")
            node.addChildNode(childNode)
            
        }
        
        
        

    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                           didUpdate node: SCNNode,
                           for anchor: ARAnchor){
        
        //NSLog("didUpdate node")
        
    }
    
//    var imageHighlightAction: SCNAction {
//        return .sequence([
//            .wait(duration: 0.25),
//            .fadeOpacity(to: 0.85, duration: 0.25),
//            .fadeOpacity(to: 0.15, duration: 0.25),
//            .fadeOpacity(to: 0.85, duration: 0.25),
//            .fadeOut(duration: 0.5),
//            .removeFromParentNode()
//            ])
//    }
//
    
    
    func requestCameraPermissions () {
        alert  = UIAlertController(title: "Permissions Alert", message: "Error", preferredStyle: .alert)
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
        
        
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            
            self.setupSceneRecognitionSession()
            
            
            
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    self.setupSceneRecognitionSession()
                } else {
                    self.presentAlert(message: "Camera permissions are required to use the augemented reality capabilities of the app. Please go to settings, privacy, and enable camera permissions.")

                }
            })
        }
        
    }
    
    func presentAlert(message: String){
        
        DispatchQueue.main.async {
            
            self.alert.dismiss(animated: true, completion: nil)
            self.alert.message = message
            self.present(self.alert, animated: true, completion: nil)
        }
      
        
    }
    
    
    func imageIsNotInView () {
        
        DispatchQueue.main.async {
            self.labelInstructions.isHidden = false
            self.imageViewOverlay.isHidden = false
        }
    }
    
    
    func imageIsInView () {
        
        DispatchQueue.main.async {
            self.labelInstructions.isHidden = true
            self.imageViewOverlay.isHidden = true
            
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
        
        
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }

}
