//
//  GSButtonViewController.swift
//  GSDemo
//
//  Created by Samuel Scherer on 4/26/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import UIKit

enum GSViewMode {
    case view
    case edit
}

protocol GSButtonViewControllerDelegate : AnyObject {
    func stopBtnActionIn(gsBtnVC:GSButtonViewController)
    func clearBtnActionIn(gsBtnVC:GSButtonViewController)
    func focusMapBtnActionIn(gsBtnVC:GSButtonViewController)
    func startBtnActionIn(gsBtnVC:GSButtonViewController)
    func add(button:UIButton, actionIn gsBtnVC:GSButtonViewController)
    func configBtnActionIn(gsBtnVC:GSButtonViewController)
    func switchTo(mode:GSViewMode, inGSBtnVC:GSButtonViewController)
}

class GSButtonViewController : UIViewController {
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var focusMapBtn: UIButton!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var configBtn: UIButton!
    var mode = GSViewMode.view
    var delegate : GSButtonViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    init() {
        super.init(nibName:"GSButtonViewController", bundle:Bundle.main)
    }
    
    convenience override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init()
    }
    
    convenience required init?(coder: NSCoder) {
        self.init()
    }
    
    //MARK - Property Method
    func setMode(mode:GSViewMode) {
        self.mode = mode
        self.editBtn.isHidden = (mode == GSViewMode.edit)
        self.focusMapBtn.isHidden = (mode == GSViewMode.edit)
        self.backBtn.isHidden = (mode == GSViewMode.view)
        self.clearBtn.isHidden = (mode == GSViewMode.view)
        self.startBtn.isHidden = (mode == GSViewMode.view)
        self.stopBtn.isHidden = (mode == GSViewMode.view)
        self.addBtn.isHidden = (mode == GSViewMode.view)
        self.configBtn.isHidden = (mode == GSViewMode.view)
    }
        
    //MARK: - IBAction Methods
    @IBAction func backBtnAction(_ sender: Any) {
        self.setMode(mode: GSViewMode.view)
        self.delegate?.switchTo(mode: self.mode, inGSBtnVC: self)
    }
    
    @IBAction func stopBtnAction(_ sender: Any) {
        self.delegate?.stopBtnActionIn(gsBtnVC: self)
    }
    
    @IBAction func clearBtnAction(_ sender: Any) {
        self.delegate?.clearBtnActionIn(gsBtnVC: self)
    }
    
    @IBAction func focusMapBtnAction(_ sender: Any) {
        self.delegate?.focusMapBtnActionIn(gsBtnVC: self)
    }
    
    @IBAction func editBtnAction(_ sender: Any) {
        self.setMode(mode: GSViewMode.edit)
        self.delegate?.switchTo(mode: self.mode, inGSBtnVC: self)
    }
    
    @IBAction func startBtnAction(_ sender: Any) {
        self.delegate?.startBtnActionIn(gsBtnVC: self)
    }
    
    @IBAction func addBtnAction(_ sender: Any) {
        self.delegate?.add(button: self.addBtn, actionIn: self)
    }
    
    @IBAction func configBtnAction(_ sender: Any) {
        self.delegate?.configBtnActionIn(gsBtnVC: self)
    }
}
