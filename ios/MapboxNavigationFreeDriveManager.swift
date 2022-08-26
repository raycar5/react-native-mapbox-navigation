@objc(MapboxNavigationFreeDriveManager)
class MapboxNavigationFreeDriveManager: RCTViewManager {
  override func view() -> UIView! {
    return MapboxNavigationFreeDriveView();
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  func showRouteViaManager(_ node: NSNumber, _ origin: [NSNumber], _ destination: [NSNumber], _ waypoints: [[NSNumber]]) {
    DispatchQueue.main.async {
      let mapboxNavigationFreeDriveView = self.bridge.uiManager.view(forReactTag: node) as! MapboxNavigationFreeDriveView
      
      mapboxNavigationFreeDriveView.showRoute(origin: origin, destination: destination, waypoints: waypoints)
    }
  }
}
