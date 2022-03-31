//
//  MediaManagerViewController.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/16/21.
//  Copyright © 2021 RIIS. All rights reserved.
//

import Foundation
import DJISDK
import DJIWidget

class MediaManagerViewController : UIViewController, DJICameraDelegate, DJIMediaManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var displayImageView: UIImageView!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mediaTableView: UITableView!
    @IBOutlet weak var positionTextField: UITextField!
    @IBOutlet weak var reloadBtn: UIButton!
    @IBOutlet weak var videoPreviewContainerView: UIView!
    
    var videoPreviewView: UIView?
    var previewerAdapter: VideoPreviewerAdapter?
    
    weak var mediaManager : DJIMediaManager?
    var mediaList : [DJIMediaFile]?
    var statusAlertView : AlertView?
    var selectedMedia : DJIMediaFile?
    var previousOffset = UInt(0)
    var fileData : Data?
    var statusView : DJIScrollView?
    var selectedCellIndexPath : IndexPath?
    var renderView : DJIRTPlayerRenderView?
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let optionalCamera = fetchCamera()
        guard let camera = optionalCamera else {
            print("Couldn't fetch camera")
            return
        }
        camera.delegate = self
        self.mediaManager = camera.mediaManager
        self.mediaManager?.delegate = self
        camera.setMode(DJICameraMode.mediaDownload) { (error : Error?) in
            if let error = error {
                print("setMode failed: %@", error.localizedDescription)
            }
        }
        self.loadMediaList()
        
        if self.hasPlaybackFor(cameraName: camera.displayName) {
            self.setupRenderViewPlaybacker()
        } else {
            self.setupVideoPreviewer()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let camera = fetchCamera() else { return }
        
        camera.setMode(DJICameraMode.shootPhoto, withCompletion: { (error: Error?) in
            if let error = error {
                showAlertWith("Set CameraWorkModeShootPhoto Failed, \(error.localizedDescription)")
            }
        })
            
        if self.hasPlaybackFor(cameraName: camera.displayName) {
            self.cleanupRenderViewPlaybacker()
        } else {
            self.cleanupVideoPreviewer()
        }
        
        guard let cameraDelegate = camera.delegate else {
            return
        }
        if cameraDelegate.isEqual(self) {
            camera.delegate = nil
            self.mediaManager?.delegate = nil
        }
    }
    
    func hasPlaybackFor(cameraName:String) -> Bool {
        return cameraName == DJICameraDisplayNamePhantom4Camera ||
               cameraName == DJICameraDisplayNamePhantom4ProCamera ||
               cameraName == DJICameraDisplayNamePhantom4AdvancedCamera ||
               cameraName == DJICameraDisplayNameX4S ||
               cameraName == DJICameraDisplayNameX5S ||
               cameraName == DJICameraDisplayNameX7 ||
               cameraName == DJICameraDisplayNameX3 ||
               cameraName == DJICameraDisplayNameXT ||
               cameraName == DJICameraDisplayNameZ3 ||
               cameraName == DJICameraDisplayNameZ30 ||
               cameraName == DJICameraDisplayNameXT2Visual ||
               cameraName == DJICameraDisplayNameXT2Thermal ||
               cameraName == DJICameraDisplayNamePhantom3AdvancedCamera
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initData()
    }
    
    //MARK: - Custom Methods
    func initData() {
        self.mediaList = [DJIMediaFile]()
        self.cancelBtn.isEnabled = false
        self.reloadBtn.isEnabled = false
        self.editBtn.isEnabled = false
        
        self.fileData = nil
        self.selectedMedia = nil
        self.previousOffset = 0
        
        self.statusView = DJIScrollView.viewWith(viewController: self)
        self.statusView?.isHidden = true
    }
    
    func setupRenderViewPlaybacker() {
        //Support Video Playback for Phantom 4 Professional, Inspire 2
        var encoderType = H264EncoderType._unknown
        if let camera = fetchCamera() {
            if camera.displayName == DJICameraDisplayNamePhantom4ProCamera ||
               camera.displayName == DJICameraDisplayNamePhantom4AdvancedCamera ||
               camera.displayName == DJICameraDisplayNameX4S ||
               camera.displayName == DJICameraDisplayNameX5S { //Phantom 4 Professional, Phantom 4 Advanced and Inspire 2
                encoderType = H264EncoderType._H1_Inspire2
            }
        }
        self.renderView = DJIRTPlayerRenderView(decoderType: LiveStreamDecodeType.vtHardware,
                                                encoderType: encoderType)
        guard self.renderView != nil else {
            return
        }
        self.renderView!.frame = self.videoPreviewContainerView.bounds
        self.videoPreviewContainerView.addSubview(self.renderView!)
        self.renderView?.isHidden = true
    }
    
    func cleanupRenderViewPlaybacker() {
        self.videoPreviewContainerView.removeFromSuperview()
        self.renderView = nil
    }
    
    func setupVideoPreviewer() {
        self.videoPreviewView = UIView(frame: self.videoPreviewContainerView.bounds)
        self.videoPreviewContainerView.addSubview(self.videoPreviewView!)
        DJIVideoPreviewer.instance().type = DJIVideoPreviewerType.autoAdapt
        DJIVideoPreviewer.instance()?.start()
        DJIVideoPreviewer.instance()?.reset()
        DJIVideoPreviewer.instance()?.setView(self.videoPreviewView)
        self.previewerAdapter = VideoPreviewerAdapter()
        self.previewerAdapter?.start()

        #if targetEnvironment(simulator)
        DJIVideoPreviewer.instance().enableHardwareDecode = true
        #endif
        
        self.previewerAdapter?.setupFrameControlHandler()
    }
    
    func cleanupVideoPreviewer() {
        if let showVideoPreviewView = self.videoPreviewView {
            showVideoPreviewView.removeFromSuperview()
            self.videoPreviewView = nil
        }
        DJIVideoPreviewer.instance()?.unSetView()
    }


    func loadMediaList() {
        self.loadingIndicator.isHidden = false
        self.view.bringSubviewToFront(self.loadingIndicator)
        if self.mediaManager?.sdCardFileListState == DJIMediaFileListState.syncing ||
           self.mediaManager?.sdCardFileListState == DJIMediaFileListState.deleting {
            print("Media Manager is busy. ")
        } else {
            self.mediaManager?.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: {[weak self] (error:Error?) in
                if let error = error {
                    print("Fetch Media File List Failed: %@", error.localizedDescription)
                } else {
                    print("Fetch Media File List Success.")
                    if let mediaFileList = self?.mediaManager?.sdCardFileListSnapshot() {
                        self?.updateMediaList(mediaList:mediaFileList)
                        self?.loadingIndicator.isHidden = true
                        
                    }
                }
            })
        }
    }
    
    func updateMediaList(mediaList:[DJIMediaFile]) {
        self.mediaList?.removeAll()
        self.mediaList?.append(contentsOf: mediaList)
        
        if let mediaTaskScheduler = fetchCamera()?.mediaManager?.taskScheduler {
            mediaTaskScheduler.suspendAfterSingleFetchTaskFailure = false
            mediaTaskScheduler.resume(completion: nil)
            self.mediaList?.forEach({ (file:DJIMediaFile) in
                if file.thumbnail == nil {
                    let task = DJIFetchMediaTask(file: file, content: DJIFetchMediaTaskContent.thumbnail) {[weak self] (file: DJIMediaFile, content: DJIFetchMediaTaskContent, error: Error?) in
                        self?.mediaTableView.reloadData()
                    }
                    mediaTaskScheduler.moveTask(toEnd: task)
                }
            })
        }
        self.reloadBtn.isEnabled = true
        self.editBtn.isEnabled = true
    }

    func showPhotoWithData(data:Data?) {
        if let data = data {
            self.displayImageView.image = UIImage(data: data)
            self.displayImageView.isHidden = false
        }
    }
    
    func statusToString(status:DJIMediaVideoPlaybackStatus) -> String? {
        switch status {
        case DJIMediaVideoPlaybackStatus.paused:
            return "Paused"
        case DJIMediaVideoPlaybackStatus.playing:
            return "Playing"
        case DJIMediaVideoPlaybackStatus.stopped:
            return "Stopped"
        default:
            return nil
        }
    }
    
    func orientationToString(orientation: DJICameraOrientation) -> String? {
        switch orientation {
        case DJICameraOrientation.landscape:
            return "Landscape"
        case DJICameraOrientation.portrait:
            return "Portrait"
        default:
            return nil
        }
    }
    
    @objc func dismissStatusAlertView() {
        self.statusAlertView?.dismissAlertView()
        self.statusAlertView = nil
    }
    
    //MARK: - IBAction Methods
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    
    @IBAction func editBtnAction(_ sender: Any) {
        self.mediaTableView.setEditing(true, animated: true)
        self.cancelBtn.isEnabled = true
        self.editBtn.isEnabled = false
    }
    
    @IBAction func cancelBtnAction(_ sender: Any) {
        self.mediaTableView.setEditing(false, animated: true)
        self.editBtn.isEnabled = true
        self.cancelBtn.isEnabled = false
    }
    
    @IBAction func reloadBtnAction(_ sender: Any) {
        self.loadMediaList()
    }

    @IBAction func statusBtnAction(_ sender: Any) {
        self.statusView?.isHidden = false
        self.statusView?.show()
    }
    
    
    @IBAction func downloadBtnAction(_ sender: Any) {
        guard self.selectedMedia != nil else {
            return
        }
        let isPhoto = self.selectedMedia?.mediaType == DJIMediaType.JPEG || self.selectedMedia?.mediaType == DJIMediaType.TIFF
        if (self.statusAlertView == nil) {
            let message = "Fetch Media Data \n 0.0"
            self.statusAlertView = AlertView.showAlertWith(message: message, titles: ["Cancel"], actionClosure:{[weak self] (buttonIndex: Int) -> () in
                if (buttonIndex == 0) {
                    self?.selectedMedia?.stopFetchingFileData(completion: {[weak self] (error: Error?) in
                        self?.statusAlertView = nil
                    })
                }
            })
        }
        self.selectedMedia?.fetchData(withOffset: previousOffset, update: DispatchQueue.main, update: {[weak self] (data:Data?, isComplete: Bool, error:Error?) in
            if let error = error {
                self?.statusAlertView?.update(message: "Download Media Failed: \(error.localizedDescription)")
                if let unwrappedSelf = self {
                    unwrappedSelf.perform(#selector(unwrappedSelf.dismissStatusAlertView), with: nil, afterDelay: 2.0)
                }
            } else {
                if isPhoto {
                    if let data = data {
                        if self?.fileData == nil {
                            self?.fileData = data
                        } else {
                            self?.fileData?.append(data)
                        }
                    }
                }
                if let data = data, let self = self {
                    self.previousOffset = self.previousOffset + UInt(data.count)
                }
                if let selectedFileSizeBytes = self?.selectedMedia?.fileSizeInBytes {
                    let progress = Float(self?.previousOffset ?? 0) * 100.0 / Float(selectedFileSizeBytes)
                    self?.statusAlertView?.update(message: String(format: "Downloading: %0.1f%%", progress))
                    if isComplete {
                        self?.dismissStatusAlertView()
                        if (isPhoto) {
                            self?.showPhotoWithData(data: self?.fileData)
                            self?.savePhotoWithData(data: self?.fileData)
                        }
                    }
                }
            }
        })
    }
    
    @IBAction func playBtnAction(_ sender: Any) {
        self.displayImageView.isHidden = true
        self.renderView?.isHidden = false
        
        if let mediaType = self.selectedMedia?.mediaType {
            if (mediaType == DJIMediaType.MOV || mediaType == DJIMediaType.MP4) {
                if let selectedMedia = self.selectedMedia {
                    self.positionTextField.placeholder = "\(Int(selectedMedia.durationInSeconds)) sec"
                    self.mediaManager?.playVideo(selectedMedia, withCompletion: { (error:Error?) in
                        if let error = error {
                            showAlertWith("Play Video Failed: \(error.localizedDescription)")
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func resumeBtnAction(_ sender: Any) {
        self.mediaManager?.resume(completion: { (error:Error?) in
            if let error = error {
                showAlertWith("Resume failed: \(error.localizedDescription)")
            }
        })
    }
    
    @IBAction func pauseBtnAction(_ sender: Any) {
        self.mediaManager?.pause(completion: { (error:Error?) in
            if let error = error {
                showAlertWith("Pause failed: \(error.localizedDescription)")
            }
        })
    }
    
    @IBAction func stopBtnAction(_ sender: Any) {
        self.mediaManager?.stop(completion: { (error: Error?) in
            if let error = error {
                showAlertWith("Stop failed: \(error.localizedDescription)")
            }
        })
    }
    
    @IBAction func moveToPositionAction(_ sender: Any) {
        var desiredPosition : Float?
        if let inputText = self.positionTextField.text {
            if let positionInteger = Float(inputText) {
                desiredPosition = positionInteger
            }
        }
        guard let desiredPosition = desiredPosition else { return }
        self.mediaManager?.move(toPosition: desiredPosition, withCompletion: { [weak self] (error:Error?) in
            if let error = error {
                showAlertWith("Move to position failed: \(error.localizedDescription)")
            }
            self?.positionTextField.text = ""
        })
    }

    @IBAction func showStatusBtnAction(_ sender: Any) {
        self.statusView?.isHidden = false
        self.statusView?.show()
    }

    //MARK: - Save Download Images
    
    func savePhotoWithData(data:Data?) {
        if let data = data {
            let tmpDir = NSTemporaryDirectory() as NSString
            let tmpImageFilePath = tmpDir.appendingPathComponent("tmpimage.jpg")
            let url = URL(fileURLWithPath:tmpImageFilePath)
            do {
                try data.write(to: url)
            } catch {
                print("failed to write data to file. Error: \(error)")
            }
            
            guard let imageURL = URL(string: tmpImageFilePath) else {
                print("Failed to load a filepath to save to")
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageURL)
            } completionHandler: { (success:Bool, error: Error?) in
                print("success = \(success), error = \(error?.localizedDescription ?? "no")")
            }
        }
    }
    
    func imageDidFinishSaving(error:NSError?, contextInfo:Any) {
        var message = ""
        if let error = error {
            //Show message when save image failed
            message = "Save Image Failed! Error: \(error.description)"
        } else {
            //Show message when save image successfully
            message = "Saved to Photo Album";
        }

        if self.statusAlertView == nil {
            self.statusAlertView = AlertView.showAlertWith(message:message, titles:["Dismiss"], actionClosure:{[weak self] (buttonIndex:Int) in
                if buttonIndex == 0 {
                    self?.dismissStatusAlertView()
                }
            })
        }
    }

    //MARK: - DJIMediaManagerDelegate Method
    
    func manager(_ manager: DJIMediaManager, didUpdate state: DJIMediaVideoPlaybackState) {
        var stateString = ""
        stateString.append("Media: \(state.playingMedia.fileName)\n")
        stateString.append("Total: \(state.playingMedia.durationInSeconds)\n")
        let orientationString = self.orientationToString(orientation: state.playingMedia.videoOrientation) ?? "nil"
        stateString.append("Orientation: \(orientationString)")
        stateString.append("Status: \(self.statusToString(status:state.playbackStatus) ?? "nil")\n")
        stateString.append("Position: \(state.playingPosition)\n")
    
        self.statusView?.write(status: stateString)
    }
    
    func manager(_ manager: DJIMediaManager, didUpdateVideoPlaybackData data: UnsafeMutablePointer<UInt8>, length: Int, forRendering: Bool) {
        self.renderView?.decodeH264RawData(data, length: UInt(length))
    }

    //MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return self.mediaList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaFileCell", for:indexPath)
        
        if self.selectedCellIndexPath == indexPath {
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }
        
        if let media = self.mediaList?[indexPath.row] {
            cell.textLabel?.text = media.fileName
            var detailText = "Create Date: \(media.timeCreated)"
            detailText.append(String(format: " Size: %0.1fMB", Double(media.fileSizeInBytes) / 1024.0 / 1024.0))
            detailText.append(" Duration: \(media.durationInSeconds)")
            detailText.append(" CustomInfo: \(media.customInformation ?? "none")")
            cell.detailTextLabel?.text = detailText
            if let thumbnail = media.thumbnail {
                cell.imageView?.image = thumbnail
            } else {
                cell.imageView?.image = UIImage(named: "dji.png")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.mediaTableView.isEditing {
            return
        }
        
        self.selectedCellIndexPath = indexPath
        
        if let currentMedia = self.mediaList?[indexPath.row] {
            if currentMedia !== self.selectedMedia {
                self.previousOffset = 0
                self.selectedMedia = currentMedia
                self.fileData = nil
            }
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if let currentMedia = self.mediaList?[indexPath.row] {
            self.mediaManager?.delete([currentMedia], withCompletion: { (failedFiles: [DJIMediaFile], error: Error?) in
                if let error = error {
                    showAlertWith("Delete File Failed: \(error.localizedDescription)")
                    for media:DJIMediaFile in failedFiles {
                        print("%@ delete failed",media.fileName)
                    }
                } else {
                    showAlertWith("Delete File Successfully")
                    self.mediaList?.remove(at: indexPath.row)
                    self.mediaTableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.left)
                }
            })
        }
    }
}
