//
//  DJIScrollView.swift
//  DJIGeoSample
//
//  Created by Samuel Scherer on 4/14/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit

class DJIScrollView : UIView, UIScrollViewDelegate {
    
    var fontSize : Float?
    var title : NSString?
    var statusTextView : UILabel?

    @IBOutlet var view: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    init(parentViewController: UIViewController) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        parentViewController.view.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setup()
        self.setDefaultSize()

        self.centerXAnchor.constraint(equalTo: parentViewController.view.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: parentViewController.view.centerYAnchor).isActive = true

        self.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setup() {
        Bundle.main.loadNibNamed("DJIScrollView", owner: self, options: nil)
        self.addSubview(self.view)
        
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1.2
        self.layer.borderColor = UIColor.gray.cgColor
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let statusTextViewRect = CGRect(x: 10,
                                        y: 0,
                                        width: self.scrollView.frame.size.width - 15,
                                        height: self.scrollView.frame.size.height)
        
        self.statusTextView = UILabel(frame: statusTextViewRect)
        self.statusTextView?.numberOfLines = 0
        self.statusTextView?.font = UIFont.systemFont(ofSize: 15)
        self.statusTextView?.textAlignment = NSTextAlignment.left
        self.statusTextView?.backgroundColor = UIColor.clear
        self.statusTextView?.textColor = UIColor.white
        
        if let statusTextView = self.statusTextView {
            self.scrollView.contentSize = statusTextView.bounds.size
            self.scrollView.addSubview(statusTextView)
        }
        self.scrollView.layer.borderColor = UIColor.black.cgColor
        self.scrollView.layer.borderWidth = 1.3
        self.scrollView.layer.cornerRadius = 3.0
        self.scrollView.layer.masksToBounds = true
        self.scrollView.isPagingEnabled = false
    }
    
    public func write(status: String) {
        self.statusTextView?.text = status
    }
    
    public func show() {
        self.superview?.bringSubviewToFront(self)
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1.0
            self.scrollView.contentOffset = CGPoint(x: 0, y: 0)
        }
    }
    
    @IBAction func onCloseButtonClicked(_ sender: Any) {
        UIView.animate(withDuration: 0.25) {
            self.alpha = 0;
        }
    }
    
    public func setDefaultSize() {
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        let heightOffset = CGFloat(UIDevice().userInterfaceIdiom == UIUserInterfaceIdiom.pad ? 120.0 : 60.0)
        
        let screenRect = UIScreen.main.bounds
        let height = screenRect.size.height - heightOffset
        let width = screenRect.size.width
  
        self.view.heightAnchor.constraint(equalToConstant: height).isActive = true
        self.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        self.view.widthAnchor.constraint(equalToConstant: width).isActive = true
        self.widthAnchor.constraint(equalToConstant: width).isActive = true
        
        self.statusLabel.rightAnchor.constraint(equalTo: self.scrollView.leftAnchor).isActive = true
        
        self.statusTextView?.translatesAutoresizingMaskIntoConstraints = false
        self.statusTextView?.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor).isActive = true
        self.statusTextView?.topAnchor.constraint(equalTo: self.scrollView.topAnchor).isActive = true
    }

    
}
