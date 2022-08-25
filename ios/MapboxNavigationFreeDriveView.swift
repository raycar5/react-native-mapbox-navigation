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
  var currentRouteIndex = 0 {
    didSet {
      showCurrentRoute()
    }
  }
  var currentRoute: Route? {
    return routes?[currentRouteIndex]
  }
  var routes: [Route]? {
    return routeResponse?.routes
  }
  var routeResponse: RouteResponse? {
    didSet {
      guard currentRoute != nil else {
        navigationMapView.removeRoutes()
        return
      }
      currentRouteIndex = 0
    }
  }
  
  @objc var followZoomLevel: NSNumber = 16.0
  @objc var onLocationChange: RCTDirectEventBlock?
  @objc var showSpeedLimit: Bool = true
  @objc var userPuckImage: UIImage? = nil
  @objc var userPuckScale: NSNumber = 1.0
  @objc var origin: NSArray = []
  @objc var destination: NSArray = []
  @objc var stops: NSArray = []
 
  func showCurrentRoute() {
    guard let currentRoute = currentRoute else { return }
 
    var routes = [currentRoute]
    routes.append(contentsOf: self.routes!.filter {
      $0 != currentRoute
    })
    navigationMapView.showcase(routes)
    //navigationMapView.show(routes)
    //navigationMapView.showWaypoints(on: currentRoute)
  }
  
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
    navigationMapView.mapView.mapboxMap.loadStyleURI(StyleURI.light)
    navigationMapView.mapView.gestures.options.panEnabled = true
    navigationMapView.mapView.gestures.options.pinchEnabled = true
    navigationMapView.mapView.gestures.options.pinchRotateEnabled = false
    navigationMapView.mapView.gestures.options.rotateEnabled = false
    navigationMapView.mapView.gestures.options.simultaneousRotateAndPinchZoomEnabled = false
    navigationMapView.mapView.gestures.options.pinchZoomEnabled = true
    navigationMapView.mapView.gestures.options.pinchPanEnabled = false
    navigationMapView.mapView.gestures.options.pitchEnabled = false

    var puck2DConfiguration = Puck2DConfiguration()
    if (userPuckImage != nil) {
      puck2DConfiguration.topImage = userPuckImage
      puck2DConfiguration.scale = .constant(Double(exactly: userPuckScale)!)
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
    
    var waypoints = []

    if (origin != nil && origin.count > 0) {
      let originWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: origin[1] as! CLLocationDegrees, longitude: origin[0] as! CLLocationDegrees))
      waypoints.append(originWaypoint)
    }

    if (stops != nil && stops.count > 0) {
      for stop in stops {
        if ((stop as NSArray) != nil && (stop as NSArray).count > 0) {
          waypoints.append(Waypoint(coordinate: CLLocationCoordinate2D(latitude: (stop as NSArray)[1] as! CLLocationDegrees, longitude: (stop as NSArray)[0] as! CLLocationDegrees)))
        }
      }
    }

    if (destination != nil && destination.count > 0) {
      let destinationWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: destination[1] as! CLLocationDegrees, longitude: destination[0] as! CLLocationDegrees))
      waypoints.append(destinationWaypoint)
    }

    if (!waypoints.isEmpty) {
      let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)

      Directions.shared.calculate(options) { [weak self] (_, result) in
        switch result {
          case .failure(let error):
            print(error.localizedDescription)
          case .success(let response):
            guard let self = self else { return }

            self.navigationRouteOptions = navigationRouteOptions
            self.routeResponse = response
            
            if let routes = self.routes, let currentRoute = self.currentRoute {
              self.navigationMapView.showcase(routes)
              //self.navigationMapView.show(routes)
              //self.navigationMapView.showWaypoints(on: currentRoute)
            }
          }
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

  func lineWidthExpression(_ multiplier: Double = 1.0) -> Expression {
    let lineWidthExpression = Exp(.interpolate) {
      Exp(.linear)
      Exp(.zoom)
      // It's possible to change route line width depending on zoom level, by using expression
      // instead of constant. Navigation SDK for iOS also exposes `RouteLineWidthByZoomLevel`
      // public property, which contains default values for route lines on specific zoom levels.
      RouteLineWidthByZoomLevel.multiplied(by: multiplier)
    }
 
    return lineWidthExpression
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