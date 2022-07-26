import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

class MapboxNavigationFreeDriveView: UIView, NavigationMapViewDelegate, NavigationViewControllerDelegate {
  var navigationMapView: NavigationMapView!
  var navigationRouteOptions: NavigationRouteOptions!
  var embedded: Bool
  var embedding: Bool
  
  @objc var onLocationChange: RCTDirectEventBlock?
  
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
    navigationMapView?.removeFromSuperview()
  }
  
  private func embed() {
    //guard let parentVC = parentViewController else {
      //return
    //}

    embedding = true

    navigationMapView = NavigationMapView(frame: bounds)
    navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    navigationMapView.delegate = self
    navigationMapView.userLocationStyle = .puck2D()

    let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView, viewportDataSourceType: .raw)
    navigationViewportDataSource.options.followingCameraOptions.zoomUpdatesAllowed = false
    navigationViewportDataSource.followingMobileCamera.zoom = 13.0
    navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource

    //parentVC.addChild(navigationMapView)
    addSubview(navigationMapView)
    //navigationMapView.frame = bounds
    //navigationMapView.didMove(toParentViewController: parentVC)

    embedding = false
    embedded = true

    //guard origin.count == 2 && destination.count == 2 else { return }
    
    //embedding = true

    //let originWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: origin[1] as! CLLocationDegrees, longitude: origin[0] as! CLLocationDegrees))
    //let destinationWaypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: destination[1] as! CLLocationDegrees, longitude: destination[0] as! CLLocationDegrees))

    // let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint])
    //let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint], profileIdentifier: .automobileAvoidingTraffic)

    //Directions.shared.calculate(options) { [weak self] (_, result) in
      //guard let strongSelf = self, let parentVC = strongSelf.parentViewController else {
        //return
      //}
      
      //switch result {
        //case .failure(let error):
          //strongSelf.onError!(["message": error.localizedDescription])
        //case .success(let response):
          //guard let weakSelf = self else {
            //return
          //}
          
          //let navigationService = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: options, simulating: strongSelf.shouldSimulateRoute ? .always : .never)
          
          //let navigationOptions = NavigationOptions(navigationService: navigationService)
          //let vc = NavigationViewController(for: response, routeIndex: 0, routeOptions: options, navigationOptions: navigationOptions)

          //vc.showsEndOfRouteFeedback = strongSelf.showsEndOfRouteFeedback
          //StatusView.appearance().isHidden = strongSelf.hideStatusView

          //NavigationSettings.shared.voiceMuted = strongSelf.mute;
          
          //vc.delegate = strongSelf
        
          //parentVC.addChild(vc)
          //strongSelf.addSubview(vc.view)
          //vc.view.frame = strongSelf.bounds
          //vc.didMove(toParent: parentVC)
          //strongSelf.navViewController = vc
      //}
      
      //strongSelf.embedding = false
      //strongSelf.embedded = true
    //}
  }
  
  func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
    onLocationChange?(["longitude": location.coordinate.longitude, "latitude": location.coordinate.latitude])
  }
}