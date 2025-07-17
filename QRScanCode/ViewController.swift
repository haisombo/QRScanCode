
import UIKit
import BakongKHQR

class ViewController: UIViewController {

    @IBOutlet weak var qrCodeImage: UIImageView!
    @IBOutlet weak var qrCurrency: UIImageView!
    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var generate: UIButton!
    
    var qrCodeStrings   = ""
    var amount          = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        generate.layer.cornerRadius = 10
        generateKhqr()
        setupUI()
    }

    @IBAction func generateButton(_ sender: Any) {
        amount = Double(inputText.text ?? "") ?? 0.0
        qrCodeImage.image = nil
        qrCurrency.image = nil
        generateKhqr()
        setupUI()
    }
    
    
    func qrScan() {
        // Generate QR code image from the current string
        if let qrCodeImages = generateQRCodeWithLogo(from: qrCodeStrings) {
            qrCodeImage.image = qrCodeImages
            qrCurrency.image  = UIImage(named: "currency")!
        } else {
            print("Failed to generate QR code")
        }
    }
    func setupUI(){
        qrScan()
    }
    func generateQRCodeWithLogo(from string: String) -> UIImage? {
        guard let qrFilter  = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let qrData          = string.data(using: String.Encoding.ascii)
        qrFilter.setValue(qrData, forKey: "inputMessage")
        
        let qrTransform     = CGAffineTransform(scaleX: 12, y: 12)
        let qrImage         = qrFilter.outputImage?.transformed(by: qrTransform)

        return UIImage(ciImage: qrImage!)
    }
    
    func generateKhqr(){
        let info = IndividualInfo(accountId: "khqr@ppcb",
                                  merchantName: "WeCafe Top-up",
                                  accountInformation: "9700000000507",
                                  acquiringBank: "Phnom Penh Commercial Bank",
                                  currency: .Usd,
                                  amount: amount)
        let khqrResponse = BakongKHQR.generateIndividual(info!)
        if khqrResponse.status?.code == 0 {
            let khqrData = khqrResponse.data as? KHQRData
            qrCodeStrings = khqrData?.qr ?? ""
            print("data: \(khqrData?.qr)")
            print("md5: \(khqrData?.md5)")
        }
    }

}
extension CIImage {
    /// Combines the current image with the given image centered.
    func combined(with image: CIImage) -> CIImage? {
        guard let combinedFilter = CIFilter(name: "CISourceOverCompositing") else { return nil }
        let centerTransform = CGAffineTransform(translationX: extent.midX - (image.extent.size.width / 2), y: extent.midY - (image.extent.size.height / 2))
        combinedFilter.setValue(image.transformed(by: centerTransform), forKey: "inputImage")
        combinedFilter.setValue(self, forKey: "inputBackgroundImage")
        return combinedFilter.outputImage!
    }
    
}
extension CIImage {
    /// Inverts the colors and creates a transparent image by converting the mask to alpha.
    /// Input image should be black and white.
    var transparent: CIImage? {
        return inverted?.blackTransparent
    }

    /// Inverts the colors.
    var inverted: CIImage? {
        guard let invertedColorFilter = CIFilter(name: "CIColorInvert") else { return nil }

        invertedColorFilter.setValue(self, forKey: "inputImage")
        return invertedColorFilter.outputImage
    }

    /// Converts all black to transparent.
    var blackTransparent: CIImage? {
        guard let blackTransparentFilter = CIFilter(name: "CIMaskToAlpha") else { return nil }
        blackTransparentFilter.setValue(self, forKey: "inputImage")
        return blackTransparentFilter.outputImage
    }

    /// Applies the given color as a tint color.
    func tinted(using color: UIColor) -> CIImage?
    {
        guard
            let transparentQRImage = transparent,
            let filter = CIFilter(name: "CIMultiplyCompositing"),
            let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return nil }

        let ciColor = CIColor(color: color)
        colorFilter.setValue(ciColor, forKey: kCIInputColorKey)
        let colorImage = colorFilter.outputImage

        filter.setValue(colorImage, forKey: kCIInputImageKey)
        filter.setValue(transparentQRImage, forKey: kCIInputBackgroundImageKey)

        return filter.outputImage!
    }
}
