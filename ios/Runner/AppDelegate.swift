import Flutter
import UIKit

// MARK: - UPI platform channel (iOS)

private struct UpiWallet {
  let id: String
  let androidPackage: String
  let probeSchemes: [String]
  let payPath: String
}

private let upiWallets: [UpiWallet] = [
  UpiWallet(
    id: "gpay",
    androidPackage: "com.google.android.apps.nbu.paisa.user",
    probeSchemes: ["tez", "gpay", "googlepay"],
    payPath: "upi/pay"
  ),
  UpiWallet(
    id: "phonepe",
    androidPackage: "com.phonepe.app",
    probeSchemes: ["phonepe"],
    payPath: "pay"
  ),
  UpiWallet(
    id: "paytm",
    androidPackage: "net.one97.paytm",
    probeSchemes: ["paytmmp", "paytm"],
    payPath: "pay"
  ),
  UpiWallet(
    id: "cred",
    androidPackage: "com.dreamplug.androidapp",
    probeSchemes: ["credpay", "cred"],
    payPath: "pay"
  ),
  UpiWallet(
    id: "jupiter",
    androidPackage: "money.jupiter",
    probeSchemes: ["jupiter"],
    payPath: "pay"
  ),
  UpiWallet(
    id: "bhim",
    androidPackage: "in.org.npci.upiapp",
    probeSchemes: ["bhim"],
    payPath: "pay"
  ),
  UpiWallet(
    id: "amazonpay",
    androidPackage: "in.amazon.mShop.android.shopping",
    probeSchemes: ["amazonpay"],
    payPath: "pay"
  ),
]

final class UpiPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.upitracker/upi",
      binaryMessenger: registrar.messenger()
    )
    let instance = UpiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getInstalledUpiApps":
      result(installedAndroidPackages())
    case "launchUpiIntent":
      guard let args = call.arguments as? [String: Any],
            let uri = args["uri"] as? String
      else {
        result(false)
        return
      }
      let package = args["package"] as? String
      let appId = args["appId"] as? String
      result(launchExplicit(upiUri: uri, androidPackage: package, appId: appId))
    case "launchUpiChooser":
      guard let args = call.arguments as? [String: Any],
            let uri = args["uri"] as? String
      else {
        result(false)
        return
      }
      result(openUrl(uri))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Returns Android package ids so Dart can map to [UpiAppInfo.knownApps].
  private func installedAndroidPackages() -> [String] {
    upiWallets.compactMap { wallet in
      if wallet.probeSchemes.contains(where: { canOpenScheme($0) }) {
        return wallet.androidPackage
      }
      return nil
    }
  }

  private func launchExplicit(
    upiUri: String,
    androidPackage: String?,
    appId: String?
  ) -> Bool {
    let wallet = upiWallets.first {
      $0.androidPackage == androidPackage || $0.id == appId
    }

    if let wallet = wallet {
      for scheme in wallet.probeSchemes {
        if let url = buildWalletUrl(scheme: scheme, payPath: wallet.payPath, upiUri: upiUri),
           open(url) {
          return true
        }
      }
    }

    return openUrl(upiUri)
  }

  private func buildWalletUrl(scheme: String, payPath: String, upiUri: String) -> URL? {
    guard let query = extractQuery(from: upiUri) else { return nil }

    let segments = payPath.split(separator: "/").map(String.init)
    var components = URLComponents()
    components.scheme = scheme

    if segments.isEmpty {
      components.host = "pay"
    } else if segments.count == 1 {
      components.host = segments[0]
    } else {
      components.host = segments[0]
      components.path = "/" + segments.dropFirst().joined(separator: "/")
    }
    components.query = query
    return components.url
  }

  private func extractQuery(from upiUri: String) -> String? {
    guard let url = URL(string: upiUri),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return nil }
    if let q = components.query, !q.isEmpty { return q }
    if let q = components.percentEncodedQuery, !q.isEmpty { return q }
    return nil
  }

  private func canOpenScheme(_ scheme: String) -> Bool {
    guard let url = URL(string: "\(scheme)://") else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private func openUrl(_ uriString: String) -> Bool {
    guard let url = URL(string: uriString) else { return false }
    return open(url)
  }

  private func open(_ url: URL) -> Bool {
    guard UIApplication.shared.canOpenURL(url) else { return false }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
    return true
  }
}

// MARK: - App delegate

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "UpiPlugin") {
      UpiPlugin.register(with: registrar)
    }
  }
}
