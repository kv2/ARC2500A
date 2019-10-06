//
//  TableCell.swift
//  ARC2500A
//
//  Created by john doe on 12/4/18.
//  Copyright © 2018 Kirill Volchinskiy. All rights reserved.
//

import UIKit

class TableCell: UITableViewCell {

    @IBOutlet var labelTitle: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
