package com.hollertaxi.mapboxnavigation

import android.annotation.SuppressLint
import android.content.res.Configuration
import android.content.res.Resources
import android.location.Location
import android.location.LocationManager
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import android.widget.Toast
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.mapbox.api.directions.v5.models.DirectionsRoute
import com.mapbox.api.directions.v5.models.RouteOptions
import com.mapbox.bindgen.Expected
import com.mapbox.geojson.Point
import com.mapbox.maps.EdgeInsets
import com.mapbox.maps.MapView
import com.mapbox.maps.MapboxMap
import com.mapbox.maps.Style
import com.mapbox.maps.plugin.LocationPuck2D
import com.mapbox.maps.plugin.animation.camera
import com.mapbox.maps.plugin.locationcomponent.location
import com.mapbox.navigation.base.TimeFormat
import com.mapbox.navigation.base.extensions.applyDefaultNavigationOptions
import com.mapbox.navigation.base.extensions.applyLanguageAndVoiceUnitOptions
import com.mapbox.navigation.base.options.NavigationOptions
import com.mapbox.navigation.base.route.RouterCallback
import com.mapbox.navigation.base.route.RouterFailure
import com.mapbox.navigation.base.route.RouterOrigin
import com.mapbox.navigation.core.MapboxNavigation
import com.mapbox.navigation.core.MapboxNavigationProvider
import com.mapbox.navigation.core.directions.session.RoutesObserver
import com.mapbox.navigation.core.formatter.MapboxDistanceFormatter
import com.mapbox.navigation.core.replay.MapboxReplayer
import com.mapbox.navigation.core.replay.ReplayLocationEngine
import com.mapbox.navigation.core.replay.route.ReplayProgressObserver
import com.mapbox.navigation.core.replay.route.ReplayRouteMapper
import com.mapbox.navigation.core.trip.session.LocationMatcherResult
import com.mapbox.navigation.core.trip.session.LocationObserver
import com.mapbox.navigation.core.trip.session.RouteProgressObserver
import com.mapbox.navigation.core.trip.session.VoiceInstructionsObserver
import com.hollertaxi.mapboxnavigation.databinding.NavigationViewBinding
import com.mapbox.api.directions.v5.DirectionsCriteria
import com.mapbox.navigation.base.trip.model.RouteLegProgress
import com.mapbox.navigation.base.trip.model.RouteProgress
import com.mapbox.navigation.core.arrival.ArrivalObserver
import com.mapbox.navigation.ui.base.util.MapboxNavigationConsumer
import com.mapbox.navigation.ui.maneuver.api.MapboxManeuverApi
import com.mapbox.navigation.ui.maneuver.view.MapboxManeuverView
import com.mapbox.navigation.ui.maps.camera.NavigationCamera
import com.mapbox.navigation.ui.maps.camera.data.MapboxNavigationViewportDataSource
import com.mapbox.navigation.ui.maps.camera.lifecycle.NavigationBasicGesturesHandler
import com.mapbox.navigation.ui.maps.camera.state.NavigationCameraState
import com.mapbox.navigation.ui.maps.camera.transition.NavigationCameraTransitionOptions
import com.mapbox.navigation.ui.maps.location.NavigationLocationProvider
import com.mapbox.navigation.ui.maps.route.arrow.api.MapboxRouteArrowApi
import com.mapbox.navigation.ui.maps.route.arrow.api.MapboxRouteArrowView
import com.mapbox.navigation.ui.maps.route.arrow.model.RouteArrowOptions
import com.mapbox.navigation.ui.maps.route.line.api.MapboxRouteLineApi
import com.mapbox.navigation.ui.maps.route.line.api.MapboxRouteLineView
import com.mapbox.navigation.ui.maps.route.line.model.MapboxRouteLineOptions
import com.mapbox.navigation.ui.maps.route.line.model.RouteLine
import com.mapbox.navigation.ui.tripprogress.api.MapboxTripProgressApi
import com.mapbox.navigation.ui.tripprogress.model.DistanceRemainingFormatter
import com.mapbox.navigation.ui.tripprogress.model.EstimatedTimeToArrivalFormatter
import com.mapbox.navigation.ui.tripprogress.model.PercentDistanceTraveledFormatter
import com.mapbox.navigation.ui.tripprogress.model.TimeRemainingFormatter
import com.mapbox.navigation.ui.tripprogress.model.TripProgressUpdateFormatter
import com.mapbox.navigation.ui.tripprogress.view.MapboxTripProgressView
import com.mapbox.navigation.ui.voice.api.MapboxSpeechApi
import com.mapbox.navigation.ui.voice.api.MapboxVoiceInstructionsPlayer
import com.mapbox.navigation.ui.voice.model.SpeechAnnouncement
import com.mapbox.navigation.ui.voice.model.SpeechError
import com.mapbox.navigation.ui.voice.model.SpeechValue
import com.mapbox.navigation.ui.voice.model.SpeechVolume
import java.util.Locale
import com.facebook.react.uimanager.events.RCTEventEmitter

class MapboxNavigationFreeDriveView(private val context: ThemedReactContext, private val accessToken: String?) : FrameLayout(context.baseContext) {
    private companion object {
        private const val BUTTON_ANIMATION_DURATION = 1500L
    }

    private val followZoomLevel: Double = 16.0
    private val showSpeedLimit: Boolean = true
    private val speedLimitAnchor: ReadableArray? = null
    private val userPuckImage = null
    private val userPuckScale: Double = 1.0
    private val destinationImage = null
    private val mapPadding: ReadableArray? = null
    private val routeCasingColor: String = "#2F7AC6"
    private val traversedRouteColor: String = "#FFFFFF"
    private val trafficUnknownColor: String = "#56A8FB"
    private val trafficLowColor: String = "#56A8FB"
    private val trafficModerateColor: String = "#FF9500"
    private val trafficHeavyColor: String = "#FF4D4D"
    private val trafficSevereColor: String = "#8F2447"
    private val waypointColor: String = "#2F7AC6"
    private val waypointRadius: Double = 8
    private val waypointOpacity: Double = 1
    private val waypointStrokeWidth: Double = 2
    private val waypointStrokeOpacity: Double = 1
    private val waypointStrokeColor: String = "#FFFFFF"
    private val logoVisible: Boolean = true
    private val logoPadding: ReadableArray? = null
    private val attributionVisible: Boolean = true
    private val attributionPadding: ReadableArray? = []

    /**
     * Bindings to the example layout.
     */
    private var binding: NavigationViewBinding =
        NavigationViewBinding.inflate(LayoutInflater.from(context), this, true)

    /**
     * Mapbox Maps entry point obtained from the [MapView].
     * You need to get a new reference to this object whenever the [MapView] is recreated.
     */
    private lateinit var mapboxMap: MapboxMap

    /**
     * Mapbox Navigation entry point. There should only be one instance of this object for the app.
     * You can use [MapboxNavigationProvider] to help create and obtain that instance.
     */
    private lateinit var mapboxNavigation: MapboxNavigation

    /**
     * Used to execute camera transitions based on the data generated by the [viewportDataSource].
     * This includes transitions from route overview to route following and continuously updating the camera as the location changes.
     */
    private lateinit var navigationCamera: NavigationCamera

    /**
     * Produces the camera frames based on the location and routing data for the [navigationCamera] to execute.
     */
    private lateinit var viewportDataSource: MapboxNavigationViewportDataSource
    
    /**
     * Generates updates for the [routeLineView] with the geometries and properties of the routes that should be drawn on the map.
     */
    private lateinit var routeLineApi: MapboxRouteLineApi

    /**
     * Draws route lines on the map based on the data from the [routeLineApi]
     */
    private lateinit var routeLineView: MapboxRouteLineView

    /*
     * Below are generated camera padding values to ensure that the route fits well on screen while
     * other elements are overlaid on top of the map (including instruction view, buttons, etc.)
     */
    private val pixelDensity = Resources.getSystem().displayMetrics.density
    private val overviewPadding: EdgeInsets by lazy {
        EdgeInsets(
            140.0 * pixelDensity,
            40.0 * pixelDensity,
            120.0 * pixelDensity,
            40.0 * pixelDensity
        )
    }
    private val landscapeOverviewPadding: EdgeInsets by lazy {
        EdgeInsets(
            30.0 * pixelDensity,
            380.0 * pixelDensity,
            110.0 * pixelDensity,
            20.0 * pixelDensity
        )
    }
    private val followingPadding: EdgeInsets by lazy {
        EdgeInsets(
            180.0 * pixelDensity,
            40.0 * pixelDensity,
            150.0 * pixelDensity,
            40.0 * pixelDensity
        )
    }
    private val landscapeFollowingPadding: EdgeInsets by lazy {
        EdgeInsets(
            30.0 * pixelDensity,
            380.0 * pixelDensity,
            110.0 * pixelDensity,
            40.0 * pixelDensity
        )
    }

    /**
    * [NavigationLocationProvider] is a utility class that helps to provide location updates generated by the Navigation SDK
    * to the Maps SDK in order to update the user location indicator on the map.
    */
    private val navigationLocationProvider = NavigationLocationProvider()

    /**
     * Gets notified with location updates.
     *
     * Exposes raw updates coming directly from the location services
     * and the updates enhanced by the Navigation SDK (cleaned up and matched to the road).
     */
    private val locationObserver = object : LocationObserver {
        override fun onNewRawLocation(rawLocation: Location) {
            // not handled
        }

        override fun onNewLocationMatcherResult(locationMatcherResult: LocationMatcherResult) {
            val enhancedLocation = locationMatcherResult.enhancedLocation
            // update location puck's position on the map
            navigationLocationProvider.changePosition(
                location = enhancedLocation,
                keyPoints = locationMatcherResult.keyPoints,
            )

            // update camera position to account for new location
            viewportDataSource.onLocationChanged(enhancedLocation)
            viewportDataSource.evaluate()

            val event = Arguments.createMap()
            event.putDouble("longitude", enhancedLocation.longitude)
            event.putDouble("latitude", enhancedLocation.latitude)
            context
                .getJSModule(RCTEventEmitter::class.java)
                .receiveEvent(id, "onLocationChange", event)
        }
    }


    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        onCreate()
    }

    override fun requestLayout() {
        super.requestLayout()
        post(measureAndLayout)
    }

    private val measureAndLayout = Runnable {
        measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
        layout(left, top, right, bottom)
    }

    private fun setCameraPositionToOrigin() {
        val startingLocation = Location(LocationManager.GPS_PROVIDER)
        startingLocation.latitude = origin!!.latitude()
        startingLocation.longitude = origin!!.longitude()
        viewportDataSource.onLocationChanged(startingLocation)

        navigationCamera.requestNavigationCameraToFollowing(
            stateTransitionOptions = NavigationCameraTransitionOptions.Builder()
                .maxDuration(0) // instant transition
                .build()
        )
    }

    @SuppressLint("MissingPermission")
    fun onCreate() {
        if (accessToken == null) {
            sendErrorToReact("Mapbox access token is not set")
            return
        }

        mapboxMap = binding.mapView.getMapboxMap()

        // initialize the location puck
        binding.mapView.location.apply {
            this.locationPuck = LocationPuck2D(
                bearingImage = ContextCompat.getDrawable(
                    context,
                    R.drawable.mapbox_navigation_puck_icon
                )
            )
            setLocationProvider(navigationLocationProvider)
            enabled = true
        }

        // initialize Mapbox Navigation
        mapboxNavigation = if (MapboxNavigationProvider.isCreated()) {
            MapboxNavigationProvider.retrieve()
        } else {
            MapboxNavigationProvider.create(
                NavigationOptions.Builder(context)
                    .accessToken(accessToken)
                    .build()
            )
        }

        // initialize Navigation Camera
        viewportDataSource = MapboxNavigationViewportDataSource(mapboxMap)

        navigationCamera = NavigationCamera(
            mapboxMap,
            binding.mapView.camera,
            viewportDataSource
        )
        // set the animations lifecycle listener to ensure the NavigationCamera stops
        // automatically following the user location when the map is interacted with
        binding.mapView.camera.addCameraAnimationsLifecycleListener(
            NavigationBasicGesturesHandler(navigationCamera)
        )
        navigationCamera.registerNavigationCameraStateChangeObserver { navigationCameraState ->
            // shows/hide the recenter button depending on the camera state
            when (navigationCameraState) {
                NavigationCameraState.TRANSITION_TO_FOLLOWING,
                NavigationCameraState.FOLLOWING -> binding.recenter.visibility = View.INVISIBLE
                NavigationCameraState.TRANSITION_TO_OVERVIEW,
                NavigationCameraState.OVERVIEW,
                NavigationCameraState.IDLE -> binding.recenter.visibility = View.VISIBLE
            }
        }
        
        viewportDataSource.overviewPadding = overviewPadding
        viewportDataSource.followingPadding = followingPadding

        // make sure to use the same DistanceFormatterOptions across different features
        val distanceFormatterOptions = mapboxNavigation.navigationOptions.distanceFormatterOptions


        // initialize route line, the withRouteLineBelowLayerId is specified to place
        // the route line below road labels layer on the map
        // the value of this option will depend on the style that you are using
        // and under which layer the route line should be placed on the map layers stack
        val mapboxRouteLineOptions = MapboxRouteLineOptions.Builder(context)
            .withRouteLineBelowLayerId("road-label")
            .build()
        routeLineApi = MapboxRouteLineApi(mapboxRouteLineOptions)
        routeLineView = MapboxRouteLineView(mapboxRouteLineOptions)

        // start the trip session to being receiving location updates in free drive
        // and later when a route is set also receiving route progress updates
        mapboxNavigation.startTripSession()

        // load map style
        mapboxMap.loadStyleUri(
            Style.MAPBOX_LIGHT
        ) {
            // only once the style is loaded expose an ability to add and draw a route
            binding.routeButton.setOnClickListener {
                if (mapboxNavigation.getNavigationRoutes().isEmpty()) {
                    // disable navigation camera
                    navigationCamera.requestNavigationCameraToIdle()
                    // set a route to receive route progress updates and provide a route reference
                    // to the viewport data source (via RoutesObserver)
                    mapboxNavigation.setNavigationRoutes(listOf(route))
                    // enable the camera back
                    navigationCamera.requestNavigationCameraToOverview()

                    binding.routeButton.text = "clear route"
                } else {
                    // clear the routes
                    mapboxNavigation.setNavigationRoutes(listOf())
                    binding.routeButton.text = "set route"
                }
            }
        }
    }

    private fun startRoute() {
        // register event listeners
        mapboxNavigation.registerRoutesObserver(routesObserver)
        mapboxNavigation.registerLocationObserver(locationObserver)
        mapboxNavigation.registerRouteProgressObserver(replayProgressObserver)
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        mapboxNavigation.unregisterRoutesObserver(routesObserver)
        mapboxNavigation.unregisterLocationObserver(locationObserver)
        mapboxNavigation.unregisterRouteProgressObserver(replayProgressObserver)
    }

    private fun onDestroy() {
        MapboxNavigationProvider.destroy()
        routeLineApi.cancel()
        routeLineView.cancel()
    }

    private fun findRoute(origin: Point, destination: Point) {
        try {
            mapboxNavigation.requestRoutes(
                RouteOptions.builder()
                    .applyDefaultNavigationOptions()
                    .applyLanguageAndVoiceUnitOptions(context)
                    .coordinatesList(listOf(origin, destination))
                    .profile(DirectionsCriteria.PROFILE_DRIVING)
                    .steps(true)
                    .build(),
                object : RouterCallback {
                    override fun onRoutesReady(
                        routes: List<DirectionsRoute>,
                        routerOrigin: RouterOrigin
                    ) {
                        setRouteAndStartNavigation(routes)
                    }

                    override fun onFailure(
                        reasons: List<RouterFailure>,
                        routeOptions: RouteOptions
                    ) {
                        sendErrorToReact("Error finding route $reasons")
                    }

                    override fun onCanceled(routeOptions: RouteOptions, routerOrigin: RouterOrigin) {
                        // no impl
                    }
                }
            )
        } catch (ex: Exception) {
            sendErrorToReact(ex.toString())
        }

    }

    private fun sendErrorToReact(error: String?) {
        val event = Arguments.createMap()
        event.putString("error", error)
        context
            .getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, "onError", event)
    }

    private fun setRouteAndStartNavigation(routes: List<DirectionsRoute>) {
        if (routes.isEmpty()) {
            sendErrorToReact("No route found")
            return;
        }
        // set routes, where the first route in the list is the primary route that
        // will be used for active guidance
        mapboxNavigation.setRoutes(routes)

        // start location simulation along the primary route
        if (shouldSimulateRoute) {
            startSimulation(routes.first())
        }

        // show UI elements
        binding.soundButton.visibility = View.VISIBLE
        binding.routeOverview.visibility = View.VISIBLE
        binding.tripProgressCard.visibility = View.VISIBLE

        // move the camera to overview when new route is available
        navigationCamera.requestNavigationCameraToFollowing()
    }

    private fun clearRouteAndStopNavigation() {
        // clear
        mapboxNavigation.setRoutes(listOf())

        // stop simulation
        mapboxReplayer.stop()

        // hide UI elements
        binding.soundButton.visibility = View.INVISIBLE
        binding.maneuverView.visibility = View.INVISIBLE
        binding.routeOverview.visibility = View.INVISIBLE
        binding.tripProgressCard.visibility = View.INVISIBLE
    }

    private fun startSimulation(route: DirectionsRoute) {
        mapboxReplayer.run {
            stop()
            clearEvents()
            val replayEvents = ReplayRouteMapper().mapDirectionsRouteGeometry(route)
            pushEvents(replayEvents)
            seekTo(replayEvents.first())
            play()
        }
    }

    fun showRoute(origin: ReadableArray?, destination: ReadableArray?, waypoints: ReadableArray?, styles: ReadableMap?, legIndex: Double?, cameraType: String?, padding: ReadableArray?)  {
        //
    }

    fun clearRoute() {
        //
    }
    
    fun follow() {
        //
    }
    
    fun moveToOverview(padding: ReadableArray?) {
        //
    }
    
    fun fitCamera(padding: ReadableArray?) {
        //
    }

    fun onDropViewInstance() {
        this.onDestroy()
    }
    
    fun setShowSpeedLimit(showSpeedLimit: Boolean) {
        this.showSpeedLimit = showSpeedLimit
    }

    fun setSpeedLimitAnchor(speedLimitAnchor: ReadableArray?) {
        this.speedLimitAnchor = speedLimitAnchor
    }
    
    fun setFollowZoomLevel(followZoomLevel: Double) {
        this.followZoomLevel = followZoomLevel
    }
    
    fun serUserPuckImage(userPuckImage: String) {
        this.userPuckImage = userPuckImage
    }
    
    fun setUserPuckScale(userPuckScale: Double) {
        this.userPuckScale = userPuckScale
    }
    
    fun setDestinationImage(destinationImage: String) {
        this.destinationImage = destinationImage
    }
    
    fun setMapPadding(mapPadding: ReadableArray?) {
        this.mapPadding = mapPadding
    }
    
    fun setLogoVisible(logoVisible: Boolean) {
        this.logoVisible = logoVisible
    }
    
    fun setLogoPadding(logoPadding: ReadableArray?) {
        this.logoPadding = logoPadding
    }
    
    fun setAttributionVisible(attributionVisible: Boolean) {
        this.attributionVisible = attributionVisible
    }
    
    fun setAttributionPadding(attributionPadding: ReadableArray?) {
        this.attributionPadding = attributionPadding
    }
    
    fun setRouteCasingColor(routeCasingColor: String) {
        this.routeCasingColor = routeCasingColor
    }
    
    fun setTraversedRouteColor(traversedRouteColor: String) {
        this.traversedRouteColor = traversedRouteColor
    }
    
    fun setTrafficUnknownColor(trafficUnknownColor: String) {
        this.trafficUnknownColor = trafficUnknownColor
    }
    
    fun setTrafficLowColor(trafficLowColor: String) {
        this.trafficLowColor = trafficLowColor
    }
    
    fun setTrafficModerateColor(trafficModerateColor: String) {
        this.trafficModerateColor = trafficModerateColor
    }
    
    fun setTrafficHeavyColor(trafficHeavyColor: String) {
        this.trafficHeavyColor = trafficHeavyColor
    }
}
