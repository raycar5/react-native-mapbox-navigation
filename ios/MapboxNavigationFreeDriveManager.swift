@objc(MapboxNavigationFreeDriveManager)
class MapboxNavigationFreeDriveManager: RCTViewManager {
  override func view() -> UIView! {
    return MapboxNavigationFreeDriveView();
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc func showRouteViaManager(_ node: NSNumber, origin: [NSNumber], destination: [NSNumber], waypoints: [[NSNumber]], padding: [NSNumber], colors: [NSString]) {
    DispatchQueue.main.async {
      let mapboxNavigationFreeDriveView = self.bridge.uiManager.view(forReactTag: node) as! MapboxNavigationFreeDriveView
      
      mapboxNavigationFreeDriveView.showRoute(origin: origin, destination: destination, waypoints: waypoints, padding: padding, colors: colors)
    }
  }

  @objc func clearRouteViaManager(_ node: NSNumber) {
    DispatchQueue.main.async {
      let mapboxNavigationFreeDriveView = self.bridge.uiManager.view(forReactTag: node) as! MapboxNavigationFreeDriveView
      
      mapboxNavigationFreeDriveView.clearRoute()
    }
  }

  @objc func followViaManager(_ node: NSNumber) {
    DispatchQueue.main.async {
      let mapboxNavigationFreeDriveView = self.bridge.uiManager.view(forReactTag: node) as! MapboxNavigationFreeDriveView
      
      mapboxNavigationFreeDriveView.follow()
    }
  }

  @objc func moveToOverviewViaManager(_ node: NSNumber) {
    DispatchQueue.main.async {
      let mapboxNavigationFreeDriveView = self.bridge.uiManager.view(forReactTag: node) as! MapboxNavigationFreeDriveView
      
      mapboxNavigationFreeDriveView.moveToOverview()
    }
  }
}
