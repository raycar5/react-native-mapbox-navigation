import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

class MapboxNavigationFreeDriveView: UIView, NavigationMapViewDelegate, NavigationViewControllerDelegate {
  var navigationMapView: NavigationMapView!
  var navigationRouteOptions: NavigationRouteOptions!
  var passiveLocationManager: PassiveLocationManager!
  var passiveLocationProvider: PassiveLocationProvider!
  var speedLimitView: SpeedLimitView!
  var embedded: Bool
  var embedding: Bool
  
  @objc var followZoomLevel: NSNumber = 16.0
  @objc var onLocationChange: RCTDirectEventBlock?
  @objc var showSpeedLimit: Bool = true
  @objc var userPuckImage: UIImage? = nil
  
  override init(frame: CGRect) {
    self.embedded = false
    self.embedding = false
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    if (navigationMapView == nil && !embedding && !embedded) {
      embed()
    } else {
      navigationMapView?.frame = bounds
    }
  }
  
  override func removeFromSuperview() {
    super.removeFromSuperview()
    // cleanup and teardown any existing resources
    NotificationCenter.default.removeObserver(self, name: .passiveLocationManagerDidUpdate, object: nil)
    passiveLocationProvider.stopUpdatingLocation()
    passiveLocationProvider.stopUpdatingHeading()
    navigationMapView?.removeFromSuperview()
  }
  
  private func embed() {
    guard let parentVC = parentViewController else {
      return
    }

    embedding = true

    navigationMapView = NavigationMapView(frame: bounds)
    navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    navigationMapView.delegate = self
    navigationMapView.mapView?.mapboxMap.loadStyleURI(StyleURI.light)

    var puck2DConfiguration = Puck2DConfiguration()
    if (userPuckImage != nil) {
      puck2DConfiguration.topImage = userPuckImage
      puck2DConfiguration.scale = .constant(1.0)
    }
    navigationMapView.userLocationStyle = UserLocationStyle.puck2D(configuration: puck2DConfiguration)

    let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView, viewportDataSourceType: .raw)
    navigationViewportDataSource.options.followingCameraOptions.centerUpdatesAllowed = true
    navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
    navigationViewportDataSource.options.followingCameraOptions.bearingUpdatesAllowed = false
    navigationViewportDataSource.followingMobileCamera.zoom = CGFloat(followZoomLevel.floatValue)
    navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
    navigationMapView.navigationCamera.follow()

    passiveLocationManager = PassiveLocationManager()
    passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
    let locationProvider: LocationProvider = passiveLocationProvider
    navigationMapView.mapView.location.overrideLocationProvider(with: locationProvider)
    passiveLocationProvider.startUpdatingLocation()

    addSubview(navigationMapView)

    if (showSpeedLimit) {
      speedLimitView = SpeedLimitView()
    
      addSubview(speedLimitView)
    }

    NotificationCenter.default.addObserver(self,
      selector: #selector(didUpdatePassiveLocation),
      name: .passiveLocationManagerDidUpdate,
      object: nil)

    embedding = false
    embedded = true
  }
  
  @objc func didUpdatePassiveLocation(_ notification: Notification) {
    speedLimitView.signStandard = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey] as? SignStandard
    speedLimitView.speedLimit = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>

    let location = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.locationKey] as? CLLocation

    onLocationChange?(["longitude": location?.coordinate.longitude, "latitude": location?.coordinate.latitude])
  }
}