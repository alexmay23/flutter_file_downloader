import Flutter
import UIKit

struct PluginMethods {
    static let downloadFile = "download_file"
}

enum PluginError: Error {
    case invalidURL
    case invalidInput;
    case download(String)

    func asFlutterError() -> FlutterError {
        switch self {
        case .invalidURL:
            return FlutterError(code: "flutter_downloader_error.invalid_url", message: "Invalid URL", details: nil)
        case .download(let details):
            return FlutterError(code: "flutter_downloader_error.download_error", message: "Download error :\(details)", details: nil)
        case .invalidInput:
            return FlutterError(code: "flutter_downloader_error.invalid_input", message: "Invalid input", details: nil)
        }
    }
}


class DocumentPickerViewController : UIDocumentPickerViewController {
    
    var closed: (() -> Void)?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        closed?()
    }
}


public class SwiftFlutterFileDownloaderPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_file_downloader", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterFileDownloaderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private lazy var transparentController: UIViewController = {
        let controller = UIViewController()
        controller.view.isOpaque = true
        controller.view.backgroundColor = .clear
        controller.modalPresentationStyle = .overCurrentContext
        return controller
    }()

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch (call.method) {
        case PluginMethods.downloadFile:
            guard let map = call.arguments as? [String: Any] else {
                result(PluginError.invalidInput.asFlutterError())
                return
            }
            guard let urlString = map["url"] as? String, let url = URL(string: urlString) else {
                result(PluginError.invalidURL.asFlutterError())
                return
            }
            downloadFile(url: url, headers: map["headers"] as? [String: String], result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func downloadFile(url: URL, headers: [String: String]?, result: @escaping FlutterResult) {
        let saveURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(url.lastPathComponent)
        if (FileManager.default.fileExists(atPath: saveURL.path)){
            self.saveFileToFileSystem(tempURL: saveURL, result: result)
            return
        }
        let session = URLSession.shared
        var request = URLRequest(url: url)
        for (field, value) in headers ?? [:] {
            request.addValue(value, forHTTPHeaderField: field)
        }
        let dataDask = session.downloadTask(with: request) { [weak self] (tempURL: URL?, response: URLResponse?, error: Error?)  in
            if let error = error {
                result(PluginError.download(error.localizedDescription))
                return
            } else if let tempURL = tempURL {
                try? FileManager.default.moveItem(at: tempURL, to: saveURL)
                DispatchQueue.main.async {
                    self?.saveFileToFileSystem(tempURL: saveURL, result: result)
                }
            } else {
                result(PluginError.download("undefined"))
            }
        }
        dataDask.resume()
    }

    func saveFileToFileSystem(tempURL: URL, result: @escaping FlutterResult) {
        let root = UIApplication.shared.keyWindow!.rootViewController!
        let document = DocumentPickerViewController(url: tempURL, in: .moveToService)
        document.closed = { result("ok") }
        root.present(document, animated: true, completion: nil)
    }

}
