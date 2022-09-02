@objc(MapboxNavigationFreeDriveManager)
class MapboxNavigationFreeDriveManager: RCTViewManager {
  override func view() -> UIView! {
    return MapboxNavigationFreeDriveView();
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc func showRouteViaManager(_ node: NSNumber, origin: [NSNumber], destination: [NSNumber], waypoints: [[NSNumber]], styles: [NSDictionary], legIndex: NSNumber, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      let mapboxNavigationFreeDriveView = self.bridge.uiManager.view(forReactTag: node) as! MapboxNavigationFreeDriveView
      
      mapboxNavigationFreeDriveView.showRoute(origin: origin, destination: destination, waypoints: waypoints, styles: styles, legIndex: legIndex, resolver: resolver, rejecter: rejecter)
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

  @objc func moveToOverviewViaManager(_ node: NSNumber, padding: [NSNumber]) {
    DispatchQueue.main.async {
      let mapboxNavigationFreeDriveView = self.bridge.uiManager.view(forReactTag: node) as! MapboxNavigationFreeDriveView
      
      mapboxNavigationFreeDriveView.moveToOverview(padding: padding)
    }
  }

  @objc func fitCameraViaManager(_ node: NSNumber, padding: [NSNumber]) {
    DispatchQueue.main.async {
      let mapboxNavigationFreeDriveView = self.bridge.uiManager.view(forReactTag: node) as! MapboxNavigationFreeDriveView
      
      mapboxNavigationFreeDriveView.fitCamera(padding: padding)
    }
  }
}
