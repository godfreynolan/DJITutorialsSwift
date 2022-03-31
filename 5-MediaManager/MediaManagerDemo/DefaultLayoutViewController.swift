//
//  DefaultLayoutViewController.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/13/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import DJIUXSDK

class DefaultLayoutViewController: DUXDefaultLayoutViewController {
    
    @IBOutlet weak var playbackBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad) {
            self.playbackBtn.setImage(UIImage.init(named: "mediaDownload_icon_iPad"), for: UIControl.State.normal)
        } else {
            self.playbackBtn.setImage(UIImage.init(named: "mediaDownload_icon"), for: UIControl.State.normal)
        }
    }
}
