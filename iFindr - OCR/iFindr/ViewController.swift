import UIKit
import Foundation

class ViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate {
  
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var findTextField: UITextField!
  @IBOutlet weak var replaceTextField: UITextField!
  @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
  
  var activityIndicator:UIActivityIndicatorView!
  var originalTopMargin:CGFloat!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    originalTopMargin = topMarginConstraint.constant
  }
  
  @IBAction func takePhoto(_ sender: AnyObject) {
    view.endEditing(true)
    moveViewDown()
    
    let imagePickerActionSheet = UIAlertController(title: "Upload Photo",
                                                   message: nil,
                                                   preferredStyle: .actionSheet)
    
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      let cameraButton = UIAlertAction(title: "Take Photo",
                                       style: .default) { (alert) -> Void in
                                        let imagePicker = UIImagePickerController()
                                        imagePicker.delegate = self
                                        imagePicker.sourceType = .camera
                                        self.present(imagePicker,
                                                     animated: true,
                                                     completion: nil)
      }
      imagePickerActionSheet.addAction(cameraButton)
    }
    
    let libraryButton = UIAlertAction(title: "Choose from Existing", style: .default) { (alert) -> Void in
      
      let imagePicker = UIImagePickerController()
      imagePicker.delegate = self
      imagePicker.sourceType = .photoLibrary
      self.present(imagePicker, animated: true, completion: nil)
  }
    
    imagePickerActionSheet.addAction(libraryButton)
    
    let cancelButton = UIAlertAction(title: "cancel", style: .cancel) { (alert) -> Void in
      
    }
    imagePickerActionSheet.addAction(cancelButton)
    present(imagePickerActionSheet, animated: true, completion: nil)
}
  
  @IBAction func swapText(_ sender: AnyObject) {
    if let text = textView.text, let findText = findTextField.text, let replaceText = replaceTextField.text {
      textView.text = text.replacingOccurrences(of: findText,with: replaceText, options: [], range: nil)
      findTextField.text = nil
      replaceTextField.text = nil
      view.endEditing(true)
      moveViewDown()
    }
  }
  
  @IBAction func sharePoem(_ sender: AnyObject) {
    if textView.text.isEmpty {
      return
    }
    let activityViewController = UIActivityViewController(activityItems:
      [textView.text], applicationActivities: nil)
    let excludeActivities = [
      UIActivityType.assignToContact, UIActivityType.saveToCameraRoll, UIActivityType.addToReadingList, UIActivityType.postToFlickr,UIActivityType.postToVimeo]
    activityViewController.excludedActivityTypes = excludeActivities
    present(activityViewController, animated: true, completion: nil)
  }
  
  
func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
  
  var scalingSize = CGSize(width: maxDimension, height: maxDimension)
  var scaleFactor: CGFloat
  
  if image.size.width > image.size.height {
  scaleFactor = image.size.height / image.size.width
  scalingSize.width = maxDimension
  scalingSize.height = scalingSize.width * scaleFactor
  } else {
  scaleFactor = image.size.width / image.size.height
  scalingSize.height = maxDimension
  scalingSize.width = scalingSize.height * scaleFactor
  }
  
  UIGraphicsBeginImageContext(scalingSize)
  image.draw(in: CGRect(x: 0, y: 0, width: scalingSize.width, height: scalingSize.height))
  let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  
  return scaledImage!
  }

  
  // Activity Indicator methods
  
  func addActivityIndicator() {
    activityIndicator = UIActivityIndicatorView(frame: view.bounds)
    activityIndicator.activityIndicatorViewStyle = .whiteLarge
    activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
    activityIndicator.startAnimating()
    view.addSubview(activityIndicator)
  }
  
  func removeActivityIndicator() {
    activityIndicator.removeFromSuperview()
    activityIndicator = nil
  }
  
  
  // The remaining methods handle the keyboard resignation/
  // move the view so that the first responders aren't hidden
  
  func moveViewUp() {
    if topMarginConstraint.constant != originalTopMargin {
      return
    }
    
    topMarginConstraint.constant -= 135
    UIView.animate(withDuration: 0.3, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })
  }
  
  func moveViewDown() {
    if topMarginConstraint.constant == originalTopMargin {
      return
    }

    topMarginConstraint.constant = originalTopMargin
    UIView.animate(withDuration: 0.3, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })

  }
  
  @IBAction func backgroundTapped(_ sender: AnyObject) {
    view.endEditing(true)
    moveViewDown()
  }


func performImageRecognition(_image: UIImage) {
  let tesseract = G8Tesseract()
  tesseract.language = "eng+fra"
  tesseract.engineMode = .tesseractCubeCombined
  tesseract.pageSegmentationMode = .auto
  tesseract.maximumRecognitionTime = 60.0
  tesseract.image = _image.g8_blackAndWhite()
  tesseract.recognize()
  textView.text = tesseract.recognizedText
  textView.isEditable = true
  removeActivityIndicator()
  }
}

extension ViewController: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    moveViewUp()
  }
  
  @IBAction func textFieldEndEditing(_ sender: AnyObject) {
    view.endEditing(true)
    moveViewDown()
  }
  
  func textViewDidBeginEditing(_ textView: UITextView) {
    moveViewDown()
  }
}



extension ViewController: UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [String : Any]) {
    let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
    let scaledImage = scaleImage(image: selectedPhoto, maxDimension: 640)
    
    addActivityIndicator()
    
    dismiss(animated: true, completion: {
      self.performImageRecognition(_image: scaledImage)
    })
  }
}



