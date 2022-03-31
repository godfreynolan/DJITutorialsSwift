//
//  StitchingViewController.swift
//  PanoDemo
//
//  Created by Samuel Scherer on 4/30/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit

class StitchingViewController : UIViewController {
    @objc var imageArray : NSMutableArray?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async { [weak self] in
            guard let self = self else { return }
            guard let imageArray = self.imageArray else { return }
            guard let stitchedImage = Stitching.image(with: imageArray) else {
                self.showAlertWith(title: "Processing", message: "Stitching and cropping failed")
                return
            }
            UIImageWriteToSavedPhotosAlbum(stitchedImage, nil, nil, nil)
            
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = stitchedImage
            }
        }
        super.viewDidLoad()
    }
    
    //show the alert view in main thread
    func showAlertWith(title:String, message:String) {
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel) { UIAlertAction in
                alertController.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(cancelAction)
            self?.activityIndicator.stopAnimating()
        }
    }
}

