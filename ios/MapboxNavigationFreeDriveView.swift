import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps
import Turf

class MapboxNavigationFreeDriveView: UIView, NavigationMapViewDelegate, NavigationViewControllerDelegate {
  var navigationMapView: NavigationMapView!
  var navigationRouteOptions: NavigationRouteOptions!
  var passiveLocationManager: PassiveLocationManager!
  var passiveLocationProvider: PassiveLocationProvider!
  var speedLimitView: SpeedLimitView!
  var embedded: Bool
  var embedding: Bool
  var currentOrigin: [NSNumber] = []
  var currentDestination: [NSNumber] = []
  var currentWaypoints: [[NSNumber]] = []
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
  var waypointColors: [NSString] = []
  
  @objc var followZoomLevel: NSNumber = 16.0
  @objc var onLocationChange: RCTDirectEventBlock?
  @objc var onTrackingStateChange: RCTDirectEventBlock?
  @objc var showSpeedLimit: Bool = true {
    didSet {
      if (oldValue != showSpeedLimit) {
        if (showSpeedLimit) {
          addSpeedLimitView()
        } else {
          removeSpeedLimitView()
        }
      }
    }
  }
  @objc var speedLimitAnchor: [NSNumber] = [] {
    didSet {
      if (oldValue.count != speedLimitAnchor.count || oldValue != speedLimitAnchor) {
        if (showSpeedLimit) {
          addSpeedLimitView()
        } else {
          removeSpeedLimitView()
        }
      }
    }
  }
  @objc var userPuckImage: UIImage?
  @objc var userPuckScale: NSNumber = 1.0
  @objc var destinationImage: UIImage?
  @objc var mapPadding: [NSNumber] = []
  @objc var lineColor: NSString = "#1989FFFF"
  @objc var altLineColor: NSString = "#1989FF80"
  @objc var unknownLineColor: NSString = "#1989FFFF"
  @objc var waypointColor: NSString = "#000000FF"
  @objc var waypointRadius: NSNumber = 8
  @objc var waypointBorderWidth: NSNumber = 2
  @objc var waypointBorderColor: NSString = "#000000FF"
  @objc var logoVisible: Bool = true
  @objc var logoPadding: [NSNumber] = [] {
    didSet {
      if (oldValue.count != logoPadding.count || oldValue != logoPadding) {
        setLogoPadding()
      }
    }
  }
  @objc var attributionVisible: Bool = true
  @objc var attributionPadding: [NSNumber] = [] {
    didSet {
      if (oldValue.count != attributionPadding.count || oldValue != attributionPadding) {
        setAttributionPadding()
      }
    }
  }

  @objc func showRoute(origin: [NSNumber], destination: [NSNumber], waypoints: [[NSNumber]], padding: [NSNumber], colors: [NSString]) {
    currentOrigin = origin
    currentDestination = destination
    currentWaypoints = waypoints
    waypointColors = colors
    var routeWaypoints = [Waypoint]()

    if (origin != nil && origin.isEmpty == false) {
      let originWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: origin[1] as! CLLocationDegrees, longitude: origin[0] as! CLLocationDegrees))
      routeWaypoints.append(originWaypoint)
    }

    if (waypoints != nil && waypoints.isEmpty == false) {
      for waypoint in waypoints {
        if (waypoint != nil && waypoint.isEmpty == false) {
          routeWaypoints.append(Waypoint(coordinate: CLLocationCoordinate2D(latitude: waypoint[1] as! CLLocationDegrees, longitude: waypoint[0] as! CLLocationDegrees)))
        }
      }
    }

    if (destination != nil && destination.isEmpty == false) {
      let destinationWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: destination[1] as! CLLocationDegrees, longitude: destination[0] as! CLLocationDegrees))
      routeWaypoints.append(destinationWaypoint)
    }

    if (routeWaypoints.isEmpty == false) {
      let options = NavigationRouteOptions(waypoints: routeWaypoints, profileIdentifier: .automobileAvoidingTraffic)

      Directions.shared.calculate(options) { [weak self] (_, result) in
        switch result {
          case .failure(let error):
            print(error.localizedDescription)
          case .success(let response):
            guard let self = self else { return }

            self.navigationRouteOptions = options
            self.routeResponse = response
            
            if let routes = self.routes, let currentRoute = self.currentRoute {
              let newPadding = UIEdgeInsets(
                top: padding.indices.contains(0) ? CGFloat(padding[0].floatValue) : 0, 
                left: padding.indices.contains(1) ? CGFloat(padding[1].floatValue) : 0, 
                bottom: padding.indices.contains(2) ? CGFloat(padding[2].floatValue) : 0, 
                right: padding.indices.contains(3) ? CGFloat(padding[3].floatValue) : 0)
              self.showCurrentRoute(newPadding)
            }
          }
        }
    }
  }

  @objc func clearRoute() {
    routeResponse = nil
    waypointColors = []

    navigationMapView?.unhighlightBuildings()
    navigationMapView?.removeRoutes()
    navigationMapView?.removeRouteDurations()
    navigationMapView?.removeWaypoints()
    navigationMapView?.navigationCamera?.follow()
  }

  @objc func follow() {
    navigationMapView?.navigationCamera?.follow()
  }

  @objc func moveToOverview() {
    navigationMapView?.navigationCamera?.moveToOverview()
  }
  
  @objc func didUpdatePassiveLocation(_ notification: Notification) {
    let location = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.locationKey] as? CLLocation
    let roadName = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.roadNameKey] as? String
    
    speedLimitView?.signStandard = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey] as? SignStandard
    speedLimitView?.speedLimit = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>
    speedLimitView?.currentSpeed = location?.speed

    onLocationChange?(["longitude": location?.coordinate.longitude, "latitude": location?.coordinate.latitude, "roadName": roadName])
  }

  @objc func navigationCameraStateDidChange(_ notification: Notification) {
    let navigationCameraState = notification.userInfo?[NavigationCamera.NotificationUserInfoKey.state] as? NavigationCameraState
    
    var stateStr = "idle"

    if (navigationCameraState != nil) {
      if (navigationCameraState == NavigationCameraState.transitionToFollowing) {
        stateStr = "transitionToFollowing"
      } else if (navigationCameraState == NavigationCameraState.following) {
        stateStr = "following"
      } else if (navigationCameraState == NavigationCameraState.transitionToOverview) {
        stateStr = "transitionToOverview"
      } else if (navigationCameraState == NavigationCameraState.overview) {
        stateStr = "overview"
      }
    }

    onTrackingStateChange?(["state": stateStr])
  }
 
  func showCurrentRoute(_ padding: UIEdgeInsets? = nil) {
    guard let currentRoute = currentRoute else { return }
 
    var routes = [currentRoute]
    routes.append(contentsOf: self.routes!.filter {
      $0 != currentRoute
    })
    let defaultPadding = UIEdgeInsets(
      top: mapPadding.indices.contains(0) ? CGFloat(mapPadding[0].floatValue) : 0, 
      left: mapPadding.indices.contains(1) ? CGFloat(mapPadding[1].floatValue) : 0, 
      bottom: mapPadding.indices.contains(2) ? CGFloat(mapPadding[2].floatValue) : 0, 
      right: mapPadding.indices.contains(3) ? CGFloat(mapPadding[3].floatValue) : 0)
    let cameraOptions = CameraOptions(padding: padding ?? defaultPadding)
    navigationMapView.showcase(routes, routesPresentationStyle: .single(cameraOptions: cameraOptions), animated: true)
    //navigationMapView.show(routes)
    navigationMapView.showWaypoints(on: currentRoute)
    //navigationMapView.showRouteDurations(along: routes)
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

    if (speedLimitView == nil && showSpeedLimit) {
      addSpeedLimitView()
    } else if (speedLimitView != nil && showSpeedLimit == false) {
      removeSpeedLimitView()
    }
  }
  
  override func removeFromSuperview() {
    super.removeFromSuperview()
    // cleanup and teardown any existing resources
    NotificationCenter.default.removeObserver(self, name: .passiveLocationManagerDidUpdate, object: nil)
    NotificationCenter.default.removeObserver(self, name: .navigationCameraStateDidChange, object: navigationMapView?.navigationCamera)
    passiveLocationProvider.stopUpdatingLocation()
    passiveLocationProvider.stopUpdatingHeading()
    navigationMapView?.removeFromSuperview()
    navigationMapView = nil
    removeSpeedLimitView()
  }
  
  private func embed() {
    guard let parentVC = parentViewController else {
      return
    }

    embedding = true

    navigationMapView = NavigationMapView(frame: bounds)
    navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    navigationMapView.showsCongestionForAlternativeRoutes = true
    navigationMapView.showsRestrictedAreasOnRoute = true
    navigationMapView.routeCasingColor = UIColor(hex: lineColor as String)
    navigationMapView.trafficUnknownColor = UIColor(hex: unknownLineColor as String)
    navigationMapView.delegate = self
    navigationMapView.mapView.mapboxMap.loadStyleURI(StyleURI.light)
    navigationMapView.mapView.gestures.options.panEnabled = true
    navigationMapView.mapView.gestures.options.pinchEnabled = true
    navigationMapView.mapView.gestures.options.pinchRotateEnabled = false
    navigationMapView.mapView.gestures.options.pinchZoomEnabled = true
    navigationMapView.mapView.gestures.options.pinchPanEnabled = false
    navigationMapView.mapView.gestures.options.pitchEnabled = false

    setLogoPadding()
    setAttributionPadding()

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
    navigationViewportDataSource.options.followingCameraOptions.paddingUpdatesAllowed = false
    navigationViewportDataSource.followingMobileCamera.zoom = CGFloat(followZoomLevel.floatValue)
    navigationViewportDataSource.followingMobileCamera.padding = UIEdgeInsets(
      top: mapPadding.indices.contains(0) ? CGFloat(mapPadding[0].floatValue) : 0, 
      left: mapPadding.indices.contains(1) ? CGFloat(mapPadding[1].floatValue) : 0, 
      bottom: mapPadding.indices.contains(2) ? CGFloat(mapPadding[2].floatValue) : 0, 
      right: mapPadding.indices.contains(3) ? CGFloat(mapPadding[3].floatValue) : 0)
    navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
    navigationMapView.navigationCamera.follow()

    passiveLocationManager = PassiveLocationManager()
    passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
    let locationProvider: LocationProvider = passiveLocationProvider
    navigationMapView.mapView.location.overrideLocationProvider(with: locationProvider)
    passiveLocationProvider.startUpdatingLocation()

    addSubview(navigationMapView)

    NotificationCenter.default.addObserver(self,
      selector: #selector(didUpdatePassiveLocation),
      name: .passiveLocationManagerDidUpdate,
      object: nil)

    NotificationCenter.default.addObserver(self,
      selector: #selector(navigationCameraStateDidChange),
      name: .navigationCameraStateDidChange,
      object: navigationMapView?.navigationCamera)

    embedding = false
    embedded = true
  }

  func addSpeedLimitView() {
    if (navigationMapView != nil) {
      removeSpeedLimitView()

      if (showSpeedLimit) {
        speedLimitView = SpeedLimitView()

        speedLimitView.shouldShowUnknownSpeedLimit = true
        speedLimitView.translatesAutoresizingMaskIntoConstraints = false
      
        addSubview(speedLimitView)
        
        speedLimitView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: speedLimitAnchor.indices.contains(0) ? CGFloat(speedLimitAnchor[0].floatValue) : 10).isActive = true
        speedLimitView.widthAnchor.constraint(equalToConstant: speedLimitAnchor.indices.contains(2) ? CGFloat(speedLimitAnchor[2].floatValue) : 50).isActive = true
        speedLimitView.heightAnchor.constraint(equalToConstant: speedLimitAnchor.indices.contains(3) ? CGFloat(speedLimitAnchor[3].floatValue) : 50).isActive = true
        speedLimitView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: speedLimitAnchor.indices.contains(1) ? CGFloat(speedLimitAnchor[1].floatValue) : 10).isActive = true
      }
    }
  }

  func removeSpeedLimitView() {
    speedLimitView?.removeFromSuperview()
    speedLimitView = nil
  }

  func setLogoPadding() {
    if (navigationMapView != nil) {
      //navigationMapView.mapView.ornaments.options.logo.visibility = logoVisible ? OrnamentVisibility.visible : OrnamentVisibility.hidden
      navigationMapView.mapView.ornaments.options.logo.margins = CGPoint(
        x: logoPadding.indices.contains(0) ? CGFloat(logoPadding[0].floatValue) : 8.0, 
        y: logoPadding.indices.contains(1) ? CGFloat(logoPadding[1].floatValue) : 8.0)
    }
  }

  func setAttributionPadding() {
    if (navigationMapView != nil) {
      //navigationMapView.mapView.ornaments.options.attributionButton.visibility = attributionVisible ? OrnamentVisibility.visible : OrnamentVisibility.hidden
      navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(
        x: attributionPadding.indices.contains(0) ? CGFloat(attributionPadding[0].floatValue) : 8.0, 
        y: attributionPadding.indices.contains(1) ? CGFloat(attributionPadding[1].floatValue) : 8.0)
    }
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
  
  func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
    currentRouteIndex = routes?.firstIndex(of: route) ?? 0
  }

  // It's possible to change route line shape in preview mode by adding own implementation to either
  // `NavigationMapView.navigationMapView(_:shapeFor:)` or `NavigationMapView.navigationMapView(_:casingShapeFor:)`.
  func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor route: Route) -> LineString? {
    return route.shape
  }
 
  func navigationMapView(_ navigationMapView: NavigationMapView, casingShapeFor route: Route) -> LineString? {
    return route.shape
  }
 
  func navigationMapView(_ navigationMapView: NavigationMapView, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
    var lineLayer = LineLayer(id: identifier)
    lineLayer.source = sourceIdentifier
 
    // `identifier` parameter contains unique identifier of the route layer or its casing.
    // Such identifier consists of several parts: unique address of route object, whether route is
    // main or alternative, and whether route is casing or not. For example: identifier for
    // main route line will look like this: `0x0000600001168000.main.route_line`, and for
    // alternative route line casing will look like this: `0x0000600001ddee80.alternative.route_line_casing`.
    lineLayer.lineColor = .constant(.init(identifier.contains("main") ? UIColor(hex: lineColor as String) : UIColor(hex: altLineColor as String)))
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
    lineLayer.lineColor = .constant(.init(identifier.contains("main") ? UIColor(hex: lineColor as String) : UIColor(hex: altLineColor as String)))
    lineLayer.lineWidth = .expression(lineWidthExpression())
    lineLayer.lineJoin = .constant(.round)
    lineLayer.lineCap = .constant(.round)
    
    return lineLayer
  }

  func navigationMapView(_ navigationMapView: NavigationMapView, didAdd finalDestinationAnnotation: PointAnnotation, pointAnnotationManager: PointAnnotationManager) {
    var finalDestinationAnnotation = finalDestinationAnnotation

    if (destinationImage != nil) {
      finalDestinationAnnotation.image = .init(image: destinationImage!, name: "marker")
    } else {
      let image = UIImage(named: "default_marker", in: .mapboxNavigation, compatibleWith: nil)!
      finalDestinationAnnotation.image = .init(image: image, name: "marker")
    }
 
    // `PointAnnotationManager` is used to manage `PointAnnotation`s and is also exposed as
    // a property in `NavigationMapView.pointAnnotationManager`. After any modifications to the
    // `PointAnnotation` changes must be applied to `PointAnnotationManager.annotations`
    // array. To remove all annotations for specific `PointAnnotationManager`, set an empty array.
    pointAnnotationManager.annotations = [finalDestinationAnnotation]
  }

  func navigationMapView(_ navigationMapView: NavigationMapView, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer? {
    var circleLayer = CircleLayer(id: identifier)
    circleLayer.source = sourceIdentifier
    let opacity = Exp(.switchCase) {
      Exp(.any) {
        Exp(.get) {
          "waypointCompleted"
        }
      }
      0.6
      1
    }
    let color = Exp(.match) {
      Exp(.get) {
        "color"
      }
    }
    circleLayer.circleColor = .constant(.init(UIColor(hex: color.arguments[0])))
    circleLayer.circleOpacity = .expression(opacity)
    circleLayer.circleRadius = .constant(.init(CGFloat(waypointRadius.floatValue)))
    circleLayer.circleStrokeColor = .constant(.init(UIColor(hex: waypointBorderColor as String)))
    circleLayer.circleStrokeWidth = .constant(.init(CGFloat(waypointBorderWidth.floatValue)))
    circleLayer.circleStrokeOpacity = .expression(opacity)

    return circleLayer
  }
 
  func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
    var symbolLayer = SymbolLayer(id: identifier)
    symbolLayer.source = sourceIdentifier
    symbolLayer.textOpacity = 0.0
    
    return symbolLayer
  }

  func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
    var features = [Turf.Feature]()
    
    for (waypointIndex, waypoint) in waypoints.enumerated() {
      var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
      feature.properties = [
        "waypointCompleted": .boolean(waypointIndex < legIndex),
        "color": waypointColors.indices.contains(waypointIndex) ? waypointColors[waypointIndex] as String : waypointColor as String,
        "name": .number(Double(waypointIndex + 1))
      ]
      features.append(feature)
    }

    return FeatureCollection(features: features)
  }
}

extension UIColor {
  public convenience init(hex: String) {
    let r, g, b, a: CGFloat

    if hex.hasPrefix("#") {
      let start = hex.index(hex.startIndex, offsetBy: 1)
      let hexColor = String(hex[start...])

      if hexColor.count == 8 {
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
          r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
          g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
          b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
          a = CGFloat(hexNumber & 0x000000ff) / 255

          self.init(red: r, green: g, blue: b, alpha: a)
          
          return
        }
      }
    }

    return UIColor.Black
  }
}