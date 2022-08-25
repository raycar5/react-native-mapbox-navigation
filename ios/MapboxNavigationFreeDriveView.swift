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
  var routeResponse: RouteResponse!
  var embedded: Bool
  var embedding: Bool
  
  @objc var followZoomLevel: NSNumber = 16.0
  @objc var onLocationChange: RCTDirectEventBlock?
  @objc var showSpeedLimit: Bool = true
  @objc var userPuckImage: UIImage? = nil
  @objc var userPuckScale: NSNumber = 1.0
  @objc var origin: NSArray = []
  @objc var destination: NSArray = []
  @objc var stops: NSArray = []
  
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
    navigationMapView = nil
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
    navigationMapView.mapView?.panEnabled = true
    navigationMapView.mapView?.pinchEnabled = true
    navigationMapView.mapView?.pinchRotateEnabled = false
    navigationMapView.mapView?.rotateEnabled = false
    navigationMapView.mapView?.simultaneousRotateAndPinchZoomEnabled = false
    navigationMapView.mapView?.pinchZoomEnabled = true
    navigationMapView.mapView?.pinchPanEnabled = false
    navigationMapView.mapView?.pitchEnabled = false

    var puck2DConfiguration = Puck2DConfiguration()
    if (userPuckImage != nil) {
      puck2DConfiguration.topImage = userPuckImage
      puck2DConfiguration.scale = .constant(Double(exactly: userPuckScale ?? 1.0))
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

      speedLimitView.shouldShowUnknownSpeedLimit = true
    
      addSubview(speedLimitView)
    }

    NotificationCenter.default.addObserver(self,
      selector: #selector(didUpdatePassiveLocation),
      name: .passiveLocationManagerDidUpdate,
      object: nil)

    let originWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: origin[1] as! CLLocationDegrees, longitude: origin[0] as! CLLocationDegrees))
    let destinationWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: destination[1] as! CLLocationDegrees, longitude: destination[0] as! CLLocationDegrees))
    var waypoints = [originWaypoint]

    if (stops != nil && stops.count > 0) {
      for stop in stops {
        waypoints.append(Waypoint(coordinate: CLLocationCoordinate2D(latitude: stop[1] as! CLLocationDegrees, longitude: stop[0] as! CLLocationDegrees)))
      }
    }

    waypoints.append(destinationWaypoint)

    let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)

    Directions.shared.calculate(options) { [weak self] (_, result) in
      switch result {
        case .failure(let error):
          print(error.localizedDescription)
        case .success(let response):
          self.navigationRouteOptions = options
          self.routeResponse = response
          
          navigationMapView.showcase([response?.routes?.first], animated: true)
          //navigationMapView.showWaypoints(on: response?.routes?.first)
        }
      }

    embedding = false
    embedded = true
  }
  
  @objc func didUpdatePassiveLocation(_ notification: Notification) {
    speedLimitView.signStandard = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey] as? SignStandard
    speedLimitView.speedLimit = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>

    let location = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.locationKey] as? CLLocation
    let roadName = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.roadNameKey] as? String

    onLocationChange?(["longitude": location?.coordinate.longitude, "latitude": location?.coordinate.latitude, "roadName": roadName])
  }
 
  func navigationMapView(_ navigationMapView: NavigationMapView, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
    var lineLayer = LineLayer(id: identifier)
    lineLayer.source = sourceIdentifier
 
    // `identifier` parameter contains unique identifier of the route layer or its casing.
    // Such identifier consists of several parts: unique address of route object, whether route is
    // main or alternative, and whether route is casing or not. For example: identifier for
    // main route line will look like this: `0x0000600001168000.main.route_line`, and for
    // alternative route line casing will look like this: `0x0000600001ddee80.alternative.route_line_casing`.
    lineLayer.lineColor = .constant(.init(identifier.contains("main") ? #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1) : #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)))
    lineLayer.lineWidth = .expression(lineWidthExpression())
    lineLayer.lineJoin = .constant(.round)
    lineLayer.lineCap = .constant(.round)
    
    return lineLayer
  }
 
  func navigationMapView(_ navigationMapView: NavigationMapView, routeCasingLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
    var lineLayer = LineLayer(id: identifier)
    lineLayer.source = sourceIdentifier
 
    // Based on information stored in `identifier` property (whether route line is main or not)
    // route line will be colored differently.
    lineLayer.lineColor = .constant(.init(identifier.contains("main") ? #colorLiteral(red: 0.1843137255, green: 0.4784313725, blue: 0.7764705882, alpha: 1) : #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)))
    lineLayer.lineWidth = .expression(lineWidthExpression(1.2))
    lineLayer.lineJoin = .constant(.round)
    lineLayer.lineCap = .constant(.round)
    
    return lineLayer
  }
}