//
//  DirectionsCell.swift
//  MiAR
//
//  Created by Phan, Ngan on 10/27/17.
//  Copyright © 2017 MiAR. All rights reserved.
//

import UIKit

class DirectionsCell: UITableViewCell {

    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
