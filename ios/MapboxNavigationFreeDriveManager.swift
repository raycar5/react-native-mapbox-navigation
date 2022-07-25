@objc(MapboxNavigationFreeDriveManager)
class MapboxNavigationFreeDriveManager: RCTViewManager {
  override func view() -> UIView! {
    return MapboxNavigationFreeDriveView();
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
