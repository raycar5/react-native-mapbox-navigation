import UIKit
import Foundation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps
import Turf

// // adapted from https://pspdfkit.com/blog/2017/native-view-controllers-and-react-native/ and https://github.com/mslabenyak/react-native-mapbox-navigation/blob/master/ios/Mapbox/MapboxNavigationView.swift
extension UIView {
  var parentViewController: UIViewController? {
    var parentResponder: UIResponder? = self
    while parentResponder != nil {
      parentResponder = parentResponder!.next
      if let viewController = parentResponder as? UIViewController {
        return viewController
      }
    }
    return nil
  }
}

class MapboxNavigationFreeDriveView: UIView, NavigationMapViewDelegate, NavigationViewControllerDelegate {
  @objc var followZoomLevel: NSNumber = 16.0
  @objc var onLocationChange: RCTDirectEventBlock?
  @objc var onTrackingStateChange: RCTDirectEventBlock?
  @objc var onRouteChange: RCTDirectEventBlock?
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
  @objc var maneuverAnchor: [NSNumber] = []
  @objc var maneuverRadius: NSNumber = 26
  @objc var maneuverBackgroundColor: NSString = "#303030"
  @objc var userPuckImage: UIImage?
  @objc var userPuckScale: NSNumber = 1.0
  @objc var originImage: UIImage?
  @objc var destinationImage: UIImage?
  @objc var mapPadding: [NSNumber] = []
  @objc var routeColor: NSString = "#56A8FB"
  @objc var routeCasingColor: NSString = "#2F7AC6" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.routeCasingColor = UIColor(hex: routeCasingColor as String)
      }
    }
  }
  @objc var routeClosureColor: NSString = "#000000"
  @objc var alternateRouteColor: NSString = "#8694A5" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.routeAlternateColor = UIColor(hex: alternateRouteColor as String)
      }
    }
  }
  @objc var alternateRouteCasingColor: NSString = "#727E8D" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.routeAlternateCasingColor = UIColor(hex: alternateRouteCasingColor as String)
      }
    }
  }
  @objc var traversedRouteColor: NSString? {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        if (traversedRouteColor != nil) {
          navigationView.navigationMapView.traversedRouteColor = UIColor(hex: traversedRouteColor! as String)
        } else {
          navigationView.navigationMapView.traversedRouteColor = UIColor.clear
        }
      }
    }
  }
  @objc var traversedRouteCasingColor: NSString?
  @objc var trafficUnknownColor: NSString = "#56A8FB" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.trafficUnknownColor = UIColor(hex: trafficUnknownColor as String)
      }
    }
  }
  @objc var trafficLowColor: NSString = "#56A8FB" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.trafficLowColor = UIColor(hex: trafficLowColor as String)
      }
    }
  }
  @objc var trafficModerateColor: NSString = "#ff9500" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.trafficModerateColor = UIColor(hex: trafficModerateColor as String)
      }
    }
  }
  @objc var trafficHeavyColor: NSString = "#ff4d4d" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.trafficHeavyColor = UIColor(hex: trafficHeavyColor as String)
      }
    }
  }
  @objc var trafficSevereColor: NSString = "#8f2447" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.trafficSevereColor = UIColor(hex: trafficSevereColor as String)
      }
    }
  }
  @objc var restrictedRoadColor: NSString = "#000000" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.routeRestrictedAreaColor = UIColor(hex: restrictedRoadColor as String)
      }
    }
  }
  @objc var routeArrowColor: NSString = "#FFFFFF" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.maneuverArrowColor = UIColor(hex: routeArrowColor as String)
      }
    }
  }
  @objc var routeArrowCasingColor: NSString = "#2D3F53" {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        navigationView.navigationMapView.maneuverArrowStrokeColor = UIColor(hex: routeArrowCasingColor as String)
      }
    }
  }
  @objc var waypointColor: NSString = "#2F7AC6"
  @objc var waypointRadius: NSNumber = 8
  @objc var waypointOpacity: NSNumber = 1
  @objc var waypointStrokeWidth: NSNumber = 2
  @objc var waypointStrokeOpacity: NSNumber = 1
  @objc var waypointStrokeColor: NSString = "#FFFFFF"
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
  @objc var mute: Bool = false
  @objc var darkMode: Bool = false {
    didSet {
      if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil) {
        if (darkMode) {
          navigationView.navigationMapView.mapView.mapboxMap.loadStyleURI(StyleURI.dark)
        } else {
          navigationView.navigationMapView.mapView.mapboxMap.loadStyleURI(StyleURI.light)
        }
      }
    }
  }
  @objc var debug: Bool = false

  var navigationService: NavigationService!
  var navigationView: NavigationView!
  var passiveLocationManager: PassiveLocationManager!
  var passiveLocationProvider: PassiveLocationProvider!
  var speedLimitView: SpeedLimitView!
  var embedded: Bool
  var embedding: Bool
  var isMapStyleLoaded: Bool = false
  var currentOrigin: [NSNumber] = []
  var currentDestination: [NSNumber] = []
  var currentWaypoints: [[NSNumber]] = []
  var currentLegIndex: NSNumber = -1
  var currentActiveRoutes: [Route]? = nil
  var currentPreviewRoutes: [Route]? = nil
  var currentRouteResponse: RouteResponse? = nil
  var waypointStyles: [[String: Any]] = []

  @objc func showRoute(origin: [NSNumber], destination: [NSNumber], waypoints: [[NSNumber]], styles: [NSDictionary], legIndex: NSNumber, cameraType: NSString, padding: [NSNumber])  {
    currentOrigin = origin
    currentDestination = destination
    currentWaypoints = waypoints
    currentLegIndex = legIndex
    waypointStyles = (styles as? [[String: Any]]) ?? []

    var routeWaypoints = [Waypoint]()
    var routeWaypointNames = []

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

    if (waypointStyles.isEmpty == false) {
      for waypointStyle in waypointStyles {
        routeWaypointNames.append((waypointStyle["name"]! as? NSString) ?? waypointColor)
      }
    }

    if (routeWaypoints.isEmpty == false) {
      fetchRoutes(routeWaypoints, routeWaypointNames, onSuccess: {(routes: [Route]) -> Void in
        self.moveToOverview(padding)
        self.previewRoutes(routes)
        self.onRouteChange?(["distance": routes?.first?.distance, "expectedTravelTime": routes?.first?.expectedTravelTime, "typicalTravelTime": routes?.first?.typicalTravelTime])
      })
    }
  }

  @objc func clearRoute() {
    clearRouteAndStopActiveGuidance()
  }

  @objc func follow(padding: [NSNumber]) {
    navigationView?.navigationMapView?.navigationCamera?.viewportDataSource?.followingMobileCamera.padding = getPadding(padding)
    navigationView?.navigationMapView?.navigationCamera?.follow()
  }

  @objc func moveToOverview(padding: [NSNumber]) {
    navigationView?.navigationMapView?.navigationCamera?.viewportDataSource?.overviewMobileCamera.padding = getPadding(padding)
    navigationView?.navigationMapView?.navigationCamera?.moveToOverview()
  }

  @objc func fitCamera(padding: [NSNumber]) {
    navigationView?.navigationMapView?.navigationCamera?.viewportDataSource?.overviewMobileCamera.padding = getPadding(padding)
    navigationView?.navigationMapView?.navigationCamera?.moveToOverview()
  }

  @objc func startNavigation(origin: [NSNumber], destination: [NSNumber], waypoints: [[NSNumber]], styles: [NSDictionary], legIndex: NSNumber, cameraType: NSString, padding: [NSNumber])  {
    if (currentActiveRoutes != nil) {
      startActiveGuidance(false)

      if (cameraType != nil && cameraType == "overview") {
        moveToOverview(padding)
      } else {
        follow(padding)
      }
    } else {
      try {
        currentOrigin = origin
        currentDestination = destination
        currentWaypoints = waypoints
        currentLegIndex = legIndex
        waypointStyles = (styles as? [[String: Any]]) ?? []

        var routeWaypoints = [Waypoint]()
        var routeWaypointNames = []

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

        if (waypointStyles.isEmpty == false) {
          for waypointStyle in waypointStyles {
            routeWaypointNames.append((waypointStyle["name"]! as? NSString) ?? waypointColor)
          }
        }

        fetchRoutes(routeWaypoints, routeWaypointNames, onSuccess: {(routes: [Route]) -> Void in
            self.currentActiveRoutes = routes
            self.onRouteChange?(["distance": routes?.first?.distance, "expectedTravelTime": routes?.first?.expectedTravelTime, "typicalTravelTime": routes?.first?.typicalTravelTime])

            self.startActiveGuidance(false)
            self.follow(padding)
        })
      } catch (ex: Exception) {
          sendErrorToReact(ex.toString())
      }
    }
  }

  @objc func pauseNavigation() {
    clearActiveGuidance()
    clearMap()

    navigationView?.navigationMapView?.navigationCamera?.follow()
  }

  @objc func stopNavigation() {
    clearRouteAndStopActiveGuidance()
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

  func getPadding(_ padding: [NSNumber]) -> UIEdgeInsets {
    let newPadding = UIEdgeInsets(
      top: padding.indices.contains(0) ? CGFloat(padding[0].floatValue) : (mapPadding.indices.contains(0) ? CGFloat(mapPadding[0].floatValue) : 0),
      left: padding.indices.contains(1) ? CGFloat(padding[1].floatValue) : (mapPadding.indices.contains(1) ? CGFloat(mapPadding[1].floatValue) : 0), 
      bottom: padding.indices.contains(2) ? CGFloat(padding[2].floatValue) : (mapPadding.indices.contains(2) ? CGFloat(mapPadding[2].floatValue) : 0), 
      right: padding.indices.contains(3) ? CGFloat(padding[3].floatValue) : (mapPadding.indices.contains(3) ? CGFloat(mapPadding[3].floatValue) : 0))

    return newPadding
  }

  func fetchRoutes(routeWaypoints: [Waypoint], routeWaypointNames: [String], onSuccess: (_ routes: [Route]) -> Void) {
    let options = NavigationRouteOptions(waypoints: routeWaypoints, profileIdentifier: .automobileAvoidingTraffic)
    options.includesAlternativeRoutes = true

    Directions.shared.calculate(options) { [weak self] (session, result) in
      switch result {
        case .failure(let error):
          sendErrorToReact(error.localizedDescription)
        case .success(let response):
          guard let routeResponse = response, let routes = response.routes, let route = response.routes?.first, let strongSelf = self else {
            return
          }

          self.currentRouteResponse = routeResponse

          onSuccess(routes)
        }
      }
  }

  func previewRoutes(routes: [Route]) {
    pauseNavigation()

    currentPreviewRoutes = routes

    navigationView?.navigationMapView?.showcase(routes)
    //navigationView?.navigationMapView?.showRouteDurations(along: routes)
  }

  func startActiveGuidance(updateCamera: Bool) {
    currentPreviewRoutes = nil
    var routes = currentActiveRoutes

    if (routes != nil) {
      let navigationService = MapboxNavigationService(
        indexedRouteResponse: IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0),
        credentials: NavigationSettings.shared.directions.credentials
      )

      let instructionsCardCollection = InstructionsCardViewController()
                
      let navigationOptions = NavigationOptions(navigationService: navigationService, topBanner: instructionsCardCollection)
                
      let navigationViewController = NavigationViewController(
        for: IndexedRouteResponse(routeResponse: routeResponse, routeIndex: 0),
        navigationOptions: navigationOptions
      )
      navigationViewController.delegate = parentVC
      navigationViewController.transitioningDelegate = self

      instructionsCardCollection.navigationViewController = navigationViewController

      removeSpeedLimitView()
                
      navigationViewController.navigationView.bottomBannerContainerView.dismiss(animated: false)
      navigationViewController.navigationView.topBannerContainerView.show(animated: true)

      parentVC.present(navigationViewController, animated: true, completion: { [weak self] in
        guard let self = self else { return }

        var puck2DConfiguration = Puck2DConfiguration()
        if (userPuckImage != nil) {
          puck2DConfiguration.topImage = userPuckImage
          puck2DConfiguration.scale = .constant(Double(exactly: userPuckScale)!)
        }

        navigationViewController.navigationMapView?.userLocationStyle = .puck2D(configuration: puck2DConfiguration)
      })

      NotificationCenter.default.removeObserver(self, name: .passiveLocationManagerDidUpdate, object: nil)

      if (updateCamera) {
        navigationView?.navigationMapView?.navigationCamera?.follow()
      }
    }
  }
  
  func clearRouteAndStopActiveGuidance() {
    // clear
    currentActiveRoutes = nil
    currentPreviewRoutes = nil

    clearActiveGuidance()
    clearMap()

    moveToOverview()
  }

  func clearActiveGuidance() {
    waypointStyles = []

    navigationViewController.navigationView.topBannerContainerView.dismiss(animated: true)
    navigationViewController.dismiss(animated: true) { [weak self] in 
      guard let self = self else { return }

      let navigationMapView = self.viewController.navigationMapView

      let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView, viewportDataSourceType: .passive)

      navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(didUpdatePassiveLocation),
        name: .passiveLocationManagerDidUpdate,
        object: nil
      )

      showSpeedLimit()
    }
  }

  func clearMap() {
    navigationView?.navigationMapView?.unhighlightBuildings()
    navigationView?.navigationMapView?.removeRoutes()
    navigationView?.navigationMapView?.removeRouteDurations()
    navigationView?.navigationMapView?.removeWaypoints()
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
    
    if (navigationView == nil && !embedding && !embedded) {
      embed()
    } else {
      navigationView?.frame = bounds
    }
  }
  
  override func removeFromSuperview() {
    super.removeFromSuperview()
    // cleanup and teardown any existing resources
    NotificationCenter.default.removeObserver(self, name: .passiveLocationManagerDidUpdate, object: nil)
    NotificationCenter.default.removeObserver(self, name: .navigationCameraStateDidChange, object: navigationView?.navigationMapView?.navigationCamera)
    passiveLocationProvider.stopUpdatingLocation()
    passiveLocationProvider.stopUpdatingHeading()
    navigationViewController?.dismiss()
    navigationView?.removeFromSuperview()
    removeSpeedLimitView()
  }

  private func embed() {
    guard let parentVC = parentViewController else {
      return
    }

    embedding = true

    navigationView = NavigationView(frame: view.bounds)
    navigationView.translatesAutoresizingMaskIntoConstraints = false

    navigationView.navigationMapView.showsCongestionForAlternativeRoutes = true
    navigationView.navigationMapView.showsRestrictedAreasOnRoute = true
    navigationView.navigationMapView.routeCasingColor = UIColor(hex: routeCasingColor as String)
    navigationView.navigationMapView.routeAlternateColor = UIColor(hex: alternateRouteColor as String)
    navigationView.navigationMapView.routeAlternateCasingColor = UIColor(hex: alternateRouteCasingColor as String)

    if (traversedRouteColor != nil) {
      navigationView.navigationMapView.traversedRouteColor = UIColor(hex: traversedRouteColor! as String)
    } else {
      navigationView.navigationMapView.traversedRouteColor = UIColor.clear
    }

    navigationView.navigationMapView.trafficUnknownColor = UIColor(hex: trafficUnknownColor as String)
    navigationView.navigationMapView.trafficLowColor = UIColor(hex: trafficLowColor as String)
    navigationView.navigationMapView.trafficModerateColor = UIColor(hex: trafficModerateColor as String)
    navigationView.navigationMapView.trafficHeavyColor = UIColor(hex: trafficHeavyColor as String)
    navigationView.navigationMapView.trafficSevereColor = UIColor(hex: trafficSevereColor as String)
    navigationView.navigationMapView.routeRestrictedAreaColor = UIColor(hex: restrictedRoadColor as String)
    navigationView.navigationMapView.maneuverArrowColor = UIColor(hex: routeArrowColor as String)
    navigationView.navigationMapView.maneuverArrowStrokeColor = UIColor(hex: routeArrowCasingColor as String)

    if (darkMode) {
      navigationView.navigationMapView.mapView.mapboxMap.loadStyleURI(StyleURI.dark)
    } else {
      navigationView.navigationMapView.mapView.mapboxMap.loadStyleURI(StyleURI.light)
    }

    navigationView.navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
    navigationView.navigationMapView.mapView.ornaments.options.scalebar.visibility = .hidden
    navigationView.navigationMapView.mapView.gestures.options.pinchRotateEnabled = false
    navigationView.navigationMapView.mapView.gestures.options.pinchPanEnabled = false
    navigationView.navigationMapView.mapView.gestures.options.pitchEnabled = false

    var puck2DConfiguration = Puck2DConfiguration()
    if (userPuckImage != nil) {
      puck2DConfiguration.topImage = userPuckImage
      puck2DConfiguration.scale = .constant(Double(exactly: userPuckScale)!)
    }
    navigationView.navigationMapView.userLocationStyle = UserLocationStyle.puck2D(configuration: puck2DConfiguration)

    let navigationViewportDataSource = NavigationViewportDataSource(navigationView.navigationMapView.mapView, viewportDataSourceType: .raw)
    navigationViewportDataSource.followingMobileCamera.padding = getPadding([])
    navigationViewportDataSource.overviewMobileCamera.padding = getPadding([])

    navigationView.navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
    navigationView.navigationMapView.navigationCamera.follow()

    passiveLocationManager = PassiveLocationManager()
    passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
    let locationProvider: LocationProvider = passiveLocationProvider
    navigationView.navigationMapView.mapView.location.overrideLocationProvider(with: locationProvider)
    passiveLocationProvider.startUpdatingLocation()

    parentVC.addChild(navigationView)
    navigationView.frame = bounds
    addSubview(navigationView)
    navigationView.didMove(toParentViewController: parentVC)

    setLogoPadding()
    setAttributionPadding()

    if (speedLimitView == nil && showSpeedLimit) {
      addSpeedLimitView()
    } else if (speedLimitView != nil && showSpeedLimit == false) {
      removeSpeedLimitView()
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didUpdatePassiveLocation),
      name: .passiveLocationManagerDidUpdate,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(navigationCameraStateDidChange),
      name: .navigationCameraStateDidChange,
      object: navigationView.navigationMapView?.navigationCamera
    )

    embedding = false
    embedded = true
  }

  func addSpeedLimitView() {
    removeSpeedLimitView()

    if (navigationView != nil) {
      if (showSpeedLimit) {
        speedLimitView = SpeedLimitView()

        speedLimitView.shouldShowUnknownSpeedLimit = true
        speedLimitView.translatesAutoresizingMaskIntoConstraints = false
      
        parentVC.addChild(speedLimitView)
        speedLimitView.frame = bounds
        addSubview(speedLimitView)
        speedLimitView.didMove(toParentViewController: parentVC)
        
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
    if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil && navigationView.navigationMapView.mapView != nil) {
      //navigationView.navigationMapView.mapView.ornaments.options.logo.visibility = logoVisible ? OrnamentVisibility.visible : OrnamentVisibility.hidden
      navigationView.navigationMapView.mapView.ornaments.options.logo.margins = CGPoint(
        x: logoPadding.indices.contains(0) ? CGFloat(logoPadding[0].floatValue) : 8.0, 
        y: logoPadding.indices.contains(1) ? CGFloat(logoPadding[1].floatValue) : 8.0)
    }
  }

  func setAttributionPadding() {
    if (embedded == true && navigationView != nil && navigationView.navigationMapView != nil && navigationView.navigationMapView.mapView != nil) {
      //navigationView.navigationMapView.mapView.ornaments.options.attributionButton.visibility = attributionVisible ? OrnamentVisibility.visible : OrnamentVisibility.hidden
      navigationView.navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(
        x: attributionPadding.indices.contains(0) ? CGFloat(attributionPadding[0].floatValue) : 8.0, 
        y: attributionPadding.indices.contains(1) ? CGFloat(attributionPadding[1].floatValue) : 8.0)
    }
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
      Exp(.toNumber) {
        Exp(.get) {
          "opacity"
        }
      }
    }
    let color = Exp(.toColor) {
      Exp(.get) {
        "color"
      }
    }
    let radius = Exp(.toNumber) {
      Exp(.get) {
        "radius"
      }
    }
    let strokeColor = Exp(.toColor) {
      Exp(.get) {
        "strokeColor"
      }
    }
    let strokeOpacity = Exp(.switchCase) {
      Exp(.any) {
        Exp(.get) {
          "waypointCompleted"
        }
      }
      0.6
      Exp(.toNumber) {
        Exp(.get) {
          "strokeOpacity"
        }
      }
    }
    let strokeWidth = Exp(.toNumber) {
      Exp(.get) {
        "strokeWidth"
      }
    }
    circleLayer.circleColor = .expression(color)
    circleLayer.circleOpacity = .expression(opacity)
    circleLayer.circleRadius = .expression(radius)
    circleLayer.circleStrokeColor = .expression(strokeColor)
    circleLayer.circleStrokeOpacity = .expression(strokeOpacity)
    circleLayer.circleStrokeWidth = .expression(strokeWidth)

    return circleLayer
  }
 
  func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
    var symbolLayer = SymbolLayer(id: identifier)
    symbolLayer.source = sourceIdentifier
    symbolLayer.textOpacity = .expression(Exp(.switchCase) {
      Exp(.any) {
        Exp(.get) {
          "waypointCompleted"
        }
      }
      0
      0
    })
    
    return symbolLayer
  }

  func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
    var features = [Turf.Feature]()
    
    for (waypointIndex, waypoint) in waypoints.enumerated() {
      var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
      feature.properties = [
        "waypointCompleted": .boolean(waypointIndex < legIndex),
        "color": .string(
          ((waypointStyles.indices.contains(waypointIndex) && waypointStyles[waypointIndex]["color"] != nil) 
            ? ((waypointStyles[waypointIndex]["color"]! as? NSString) ?? waypointColor)
            : waypointColor) as String),
        "radius": .number(
          Double(exactly: (waypointStyles.indices.contains(waypointIndex) && waypointStyles[waypointIndex]["radius"] != nil) 
            ? ((waypointStyles[waypointIndex]["radius"]! as? NSNumber) ?? waypointRadius)
            : waypointRadius)!),
        "opacity": .number(
          Double(exactly: (waypointStyles.indices.contains(waypointIndex) && waypointStyles[waypointIndex]["opacity"] != nil) 
            ? ((waypointStyles[waypointIndex]["opacity"]! as? NSNumber) ?? waypointOpacity) 
            : waypointOpacity)!),
        "strokeColor": .string(
          ((waypointStyles.indices.contains(waypointIndex) && waypointStyles[waypointIndex]["strokeColor"] != nil) 
            ? ((waypointStyles[waypointIndex]["strokeColor"]! as? NSString) ?? waypointStrokeColor)
            : waypointStrokeColor) as String),
        "strokeWidth": .number(
          Double(exactly: (waypointStyles.indices.contains(waypointIndex) && waypointStyles[waypointIndex]["strokeWidth"] != nil) 
            ? ((waypointStyles[waypointIndex]["strokeWidth"]! as? NSNumber) ?? waypointStrokeWidth) 
            : waypointStrokeWidth)!),
        "strokeOpacity": .number(
          Double(exactly: (waypointStyles.indices.contains(waypointIndex) && waypointStyles[waypointIndex]["strokeOpacity"] != nil) 
            ? ((waypointStyles[waypointIndex]["strokeOpacity"]! as? NSNumber) ?? waypointStrokeOpacity)
            : waypointStrokeOpacity)!),
        "name": .number(Double(waypointIndex + 1))
      ]
      features.append(feature)
    }

    return FeatureCollection(features: features)
  }
}

// Transition that is used for `NavigationViewController` presentation.
class PresentationTransition: NSObject, UIViewControllerAnimatedTransitioning {
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.0
  }
    
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    guard let fromViewController = transitionContext.viewController(forKey: .from) as? ViewController,
          let toViewController = transitionContext.viewController(forKey: .to) as? NavigationViewController else {
            transitionContext.completeTransition(false)
            return
          }
        
    toViewController.navigationMapView = fromViewController.navigationView.navigationMapView
        
    transitionContext.containerView.addSubview(toViewController.view)
    transitionContext.completeTransition(true)
  }
}

// Transition that is used for `NavigationViewController` dismissal.
class DismissalTransition: NSObject, UIViewControllerAnimatedTransitioning {
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.0
  }
    
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    guard let fromViewController = transitionContext.viewController(forKey: .from) as? NavigationViewController,
          let navigationMapView = fromViewController.navigationMapView,
          let toViewController = transitionContext.viewController(forKey: .to) as? ViewController else {
            transitionContext.completeTransition(false)
            return
          }
        
    toViewController.navigationView.navigationMapView = navigationMapView
        
    transitionContext.containerView.addSubview(toViewController.view)
    transitionContext.completeTransition(true)
  }
}

extension MapboxNavigationFreeDriveView: UIViewControllerTransitioningDelegate {
  public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return PresentationTransition()
  }

  public func animationController(forDismissed dismissed: UIViewController) -> 
    UIViewControllerAnimatedTransitioning? {
        return DismissalTransition()
    }
}

extension UIColor {
  convenience init(hex: String) {
    let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int = UInt64()
    Scanner(string: hexString).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hexString.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
  }

  var RGBAString: String {
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0

    guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return "rgba(0,0,0,1)"
    }
    
    return "rgba(\(Double(red * 255)),\(Double(green * 255)),\(Double(blue * 255)),\(Double(alpha)))"
  }
}