import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var documentsPath = ""
  private var supportPath = ""
  private var platformChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    supportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0]
    migrateLegacyDocuments(from: documentsPath, to: supportPath)

    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerPlatformChannel()
    return ok
  }

  private func registerPlatformChannel() {
    guard let registrar = self.registrar(forPlugin: "PikapikaPlatform") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "pikapika/platform",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "dataLocal":
        result(self.supportPath)
      case "iosGetDocumentDir":
        result(self.documentsPath)
      case "fontList":
        result(UIFont.familyNames)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    platformChannel = channel
  }

  private func migrateLegacyDocuments(from source: String, to target: String) {
    let fm = FileManager.default
    try? fm.createDirectory(atPath: source, withIntermediateDirectories: true)
    try? fm.createDirectory(atPath: target, withIntermediateDirectories: true)
    let pairs = [
      ("databases", "databases"),
      ("pictures/remote", "pictures/remote"),
      ("download", "download"),
      ("tmp", "tmp"),
    ]
    for (srcRel, dstRel) in pairs {
      let src = (source as NSString).appendingPathComponent(srcRel)
      let dst = (target as NSString).appendingPathComponent(dstRel)
      var isDir: ObjCBool = false
      if fm.fileExists(atPath: src, isDirectory: &isDir), !fm.fileExists(atPath: dst) {
        let parent = (dst as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: parent, withIntermediateDirectories: true)
        try? fm.moveItem(atPath: src, toPath: dst)
      }
    }
  }
}
