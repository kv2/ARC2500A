//
//  DataModelStudent.swift
//  ARC2500A
//
//  Created by john doe on 12/4/18.
//  Copyright © 2018 Kirill Volchinskiy. All rights reserved.
//

import UIKit
import ARKit

class DataModelStudent: NSObject {

    var name: String!
    var fileID: String!
    var imageSizeInInches: CGFloat!
    var imagePath: String!
    var modelPath: String!
    
    var modelSCNNode: SCNNode!
    
    var image: UIImage!

    var arraySCNNodes = [SCNNode]()
    

}
