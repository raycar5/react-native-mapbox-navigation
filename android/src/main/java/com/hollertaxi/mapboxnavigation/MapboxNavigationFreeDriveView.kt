package com.hollertaxi.mapboxnavigation

import android.annotation.SuppressLint
import android.content.res.Configuration
import android.content.res.Resources
import android.location.Location
import android.location.LocationManager
import android.view.LayoutInflater
import android.view.View
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.Toast
import android.graphics.Color
import android.net.Uri
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.views.imagehelper.ResourceDrawableIdHelper
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
import com.mapbox.maps.plugin.locationcomponent.LocationComponentPlugin
import com.mapbox.maps.plugin.locationcomponent.OnIndicatorPositionChangedListener
import com.mapbox.maps.plugin.locationcomponent.location
import com.mapbox.maps.plugin.compass.compass
import com.mapbox.maps.plugin.scalebar.scalebar
import com.mapbox.maps.plugin.gestures.*
import com.mapbox.maps.plugin.attribution.*
import com.mapbox.maps.plugin.logo.*
import com.mapbox.navigation.base.ExperimentalPreviewMapboxNavigationAPI
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
import com.mapbox.navigation.ui.maps.camera.data.debugger.MapboxNavigationViewportDataSourceDebugger
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
import com.mapbox.navigation.ui.maps.route.line.model.RouteLineColorResources
import com.mapbox.navigation.ui.maps.route.line.model.RouteLineResources
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

    private var followZoomLevel: Double = 16.0
    private var showSpeedLimit: Boolean = true
    private var speedLimitAnchor: Array<Double>? = null
    private var userPuckImage: String? = null
    private var userPuckScale: Double = 1.0
    private var destinationImage: String? = null
    private var mapPadding: Array<Double>? = null
    private var routeColor: String = "#56A8FB"
    private var routeCasingColor: String = "#2F7AC6"
    private var routeClosureColor: String = "#000000"
    private var alternateRouteColor: String = "#8694A5"
    private var alternateRouteCasingColor: String = "#727E8D"
    private var traversedRouteColor: String? = null
    private var traversedRouteCasingColor: String? = null
    private var trafficUnknownColor: String = "#56A8FB"
    private var trafficLowColor: String = "#56A8FB"
    private var trafficModerateColor: String = "#ff9500"
    private var trafficHeavyColor: String = "#ff4d4d"
    private var trafficSevereColor: String = "#8f2447"
    private var restrictedRoadColor: String = "#000000"
    private var waypointColor: String = "#2F7AC6"
    private var waypointRadius: Int = 8
    private var waypointOpacity: Int = 1
    private var waypointStrokeWidth: Int = 2
    private var waypointStrokeOpacity: Int = 1
    private var waypointStrokeColor: String = "#FFFFFF"
    private var logoVisible: Boolean = true
    private var logoPadding: Array<Double>? = null
    private var attributionVisible: Boolean = true
    private var attributionPadding: Array<Double>? = null
    private var debug: Boolean = false

    private var currentOrigin: Point? = null
    private var currentDestination: Point? = null
    private var currentWaypoints: Array<Point>? = null
    private var currentLegIndex: Int = -1

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
            0.0,
            0.0,
            0.0,
            0.0
        )
    }
    private val landscapeOverviewPadding: EdgeInsets by lazy {
        EdgeInsets(
            0.0,
            0.0,
            0.0,
            0.0
        )
    }
    private val followingPadding: EdgeInsets by lazy {
        EdgeInsets(
            0.0,
            0.0,
            0.0,
            0.0
        )
    }
    private val landscapeFollowingPadding: EdgeInsets by lazy {
        EdgeInsets(
            0.0,
            0.0,
            0.0,
            0.0
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
        var firstLocationUpdateReceived = false

        override fun onNewRawLocation(rawLocation: Location) {
            // not handled
        }

        override fun onNewLocationMatcherResult(locationMatcherResult: LocationMatcherResult) {
            val enhancedLocation = locationMatcherResult.enhancedLocation
            // update location puck's position on the map
            navigationLocationProvider.changePosition(
                location = enhancedLocation,
                keyPoints = locationMatcherResult.keyPoints
            )

            // update camera position to account for new location
            viewportDataSource.onLocationChanged(enhancedLocation)
            viewportDataSource.evaluate()

            // if this is the first location update the activity has received,
            // it's best to immediately move the camera to the current user location
            if (!firstLocationUpdateReceived) {
                firstLocationUpdateReceived = true

                navigationCamera.requestNavigationCameraToOverview(
                    stateTransitionOptions = NavigationCameraTransitionOptions.Builder()
                        .maxDuration(0) // instant transition
                        .build()
                )
            }

            // location event
            val event = Arguments.createMap()
            event.putDouble("longitude", enhancedLocation.longitude)
            event.putDouble("latitude", enhancedLocation.latitude)
            context
                .getJSModule(RCTEventEmitter::class.java)
                .receiveEvent(id, "onLocationChange", event)
        }
    }
    
    /**
     * Gets notified with progress along the currently active route.
     */
    private val routeProgressObserver = RouteProgressObserver { routeProgress ->
        // update the camera position to account for the progressed fragment of the route
        viewportDataSource.onRouteProgressChanged(routeProgress)
        viewportDataSource.evaluate()

        routeLineApi.updateWithRouteProgress(routeProgress) { result ->
            mapboxMap.getStyle()?.apply {
                routeLineView.renderRouteLineUpdate(this, result)
            }
        }
    }

    /**
     * Gets notified whenever the tracked routes change.
     *
     * A change can mean:
     * - routes get changed with [MapboxNavigation.setRoutes]
     * - routes annotations get refreshed (for example, congestion annotation that indicate the live traffic along the route)
     * - driver got off route and a reroute was executed
     */
    private val routesObserver = RoutesObserver { routeUpdateResult ->
        if (routeUpdateResult.routes.isNotEmpty()) {
            // generate route geometries asynchronously and render them
            val routeLines = routeUpdateResult.routes.map { RouteLine(it, null) }

            routeLineApi.setRoutes(
                routeLines
            ) { value ->
                mapboxMap.getStyle()?.apply {
                    routeLineView.renderRouteDrawData(this, value)
                }
            }

            // update the camera position to account for the new route
            viewportDataSource.onRouteChanged(routeUpdateResult.routes.first())
            viewportDataSource.evaluate()
        } else {
            // remove the route line and route arrow from the map
            val style = mapboxMap.getStyle()

            if (style != null) {
                routeLineApi.clearRouteLine { value ->
                    routeLineView.renderClearRouteLineValue(
                        style,
                        value
                    )
                }
            }

            // remove the route reference from camera position evaluations
            viewportDataSource.clearRouteData()
            viewportDataSource.evaluate()
        }
    }

    private val onPositionChangedListener = OnIndicatorPositionChangedListener { point ->
        val result = routeLineApi.updateTraveledRouteLine(point)
        
        mapboxMap.getStyle()?.apply {
            // Render the result to update the map.
            routeLineView.renderRouteLineUpdate(this, result)
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
        startingLocation.latitude = currentOrigin!!.latitude()
        startingLocation.longitude = currentOrigin!!.longitude()
        viewportDataSource.onLocationChanged(startingLocation)

        navigationCamera.requestNavigationCameraToFollowing(
            stateTransitionOptions = NavigationCameraTransitionOptions.Builder()
                .maxDuration(0) // instant transition
                .build()
        )
    }

    @OptIn(ExperimentalPreviewMapboxNavigationAPI::class)
    private fun addDebug() {
        // debugging
        val debugger = MapboxNavigationViewportDataSourceDebugger(
            context,
            binding.mapView,
            layerAbove = "road-label"
        ).apply {
            enabled = true
        }
        viewportDataSource.debugger = debugger
        navigationCamera.debugger = debugger
    }

    @SuppressLint("MissingPermission")
    fun onCreate() {
        if (accessToken == null) {
            sendErrorToReact("Mapbox access token is not set")
            return
        }

        mapboxMap = binding.mapView.getMapboxMap()

        updateLogoPadding()
        updateAttributionPadding()

        // initialize the location puck
        binding.mapView.location.apply {
            val puckImage = userPuckImage

            if (puckImage != null) {
                val contentUri = Uri.parse(puckImage!!)
                //contentUri.getPath()
                //var name = puckImage!!.toLowerCase().replace("-", "_")
                //val resourceId = context.getResources().getIdentifier(name.substring(name.lastIndexOf("/") + 1, name.lastIndexOf(".")), "drawable", context.getPackageName())

                this.locationPuck = LocationPuck2D(
                    bearingImage = ResourceDrawableIdHelper.getInstance().getResourceDrawable(context, contentUri.getPath())
                )
            } else {
                this.locationPuck = LocationPuck2D(
                    bearingImage = ContextCompat.getDrawable(
                        context,
                        R.drawable.mapbox_navigation_puck_icon
                    )
                )
            }
            
            setLocationProvider(navigationLocationProvider)

            enabled = true
        }
        binding.mapView.compass.enabled = false
        binding.mapView.scalebar.enabled = false
        binding.mapView.gestures.pitchEnabled = false
        binding.mapView.gestures.rotateEnabled = false

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
        viewportDataSource.followingPadding = getPadding(null)
        //viewportDataSource.options.followingFrameOptions.centerUpdatesAllowed = true
        //viewportDataSource.options.followingFrameOptions.zoomUpdatesAllowed = true
        //viewportDataSource.options.followingFrameOptions.bearingUpdatesAllowed = true
        //viewportDataSource.options.followingFrameOptions.paddingUpdatesAllowed = false
        //viewportDataSource.options.followingFrameOptions.minZoom = followZoomLevel
        //viewportDataSource.options.followingFrameOptions.maxZoom = followZoomLevel
        viewportDataSource.overviewPadding = getPadding(null)
        //viewportDataSource.options.overviewFrameOptions.paddingUpdatesAllowed = false
        
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
            var stateStr = "idle"

            if (navigationCameraState != null) {
                if (navigationCameraState == NavigationCameraState.TRANSITION_TO_FOLLOWING) {
                    stateStr = "transitionToFollowing"
                } else if (navigationCameraState == NavigationCameraState.FOLLOWING) {
                    stateStr = "following"
                } else if (navigationCameraState == NavigationCameraState.TRANSITION_TO_OVERVIEW) {
                    stateStr = "transitionToOverview"
                } else if (navigationCameraState == NavigationCameraState.OVERVIEW) {
                    stateStr = "overview"
                }
            }

            val event = Arguments.createMap()
            event.putString("state", stateStr)
            context
                .getJSModule(RCTEventEmitter::class.java)
                .receiveEvent(id, "onTrackingStateChange", event)
        }
        
        // add debug
        if (this.debug) {
            addDebug()
        }

        // make sure to use the same DistanceFormatterOptions across different features
        val distanceFormatterOptions = mapboxNavigation.navigationOptions.distanceFormatterOptions

        // initialize route line, the withRouteLineBelowLayerId is specified to place
        // the route line below road labels layer on the map
        // the value of this option will depend on the style that you are using
        // and under which layer the route line should be placed on the map layers stack
        val mapboxRouteLineOptions = MapboxRouteLineOptions.Builder(context)
            .withVanishingRouteLineEnabled(true)
            .withRouteLineResources(RouteLineResources.Builder()
                .routeLineColorResources(RouteLineColorResources.Builder()
                    .routeDefaultColor(Color.parseColor(routeColor))
                    .routeCasingColor(Color.parseColor(routeCasingColor))
                    .routeClosureColor(Color.parseColor(routeClosureColor))
                    .restrictedRoadColor(Color.parseColor(restrictedRoadColor))
                    .routeLineTraveledColor(if (traversedRouteColor != null) Color.parseColor(traversedRouteColor) else Color.TRANSPARENT)
                    .routeLineTraveledCasingColor(if (traversedRouteCasingColor != null) Color.parseColor(traversedRouteCasingColor) else Color.TRANSPARENT)
                    .routeUnknownCongestionColor(Color.parseColor(trafficUnknownColor))
                    .routeLowCongestionColor(Color.parseColor(trafficLowColor))
                    .routeModerateCongestionColor(Color.parseColor(trafficModerateColor))
                    .routeHeavyCongestionColor(Color.parseColor(trafficHeavyColor))
                    .routeSevereCongestionColor(Color.parseColor(trafficSevereColor))
                    .alternativeRouteDefaultColor(Color.parseColor(alternateRouteColor))
                    .alternativeRouteCasingColor(Color.parseColor(alternateRouteCasingColor))
                    .alternativeRouteClosureColor(Color.parseColor(routeClosureColor))
                    .alternativeRouteRestrictedRoadColor(Color.parseColor(restrictedRoadColor))
                    .alternativeRouteUnknownCongestionColor(Color.parseColor(trafficUnknownColor))
                    .alternativeRouteLowCongestionColor(Color.parseColor(trafficLowColor))
                    .alternativeRouteModerateCongestionColor(Color.parseColor(trafficModerateColor))
                    .alternativeRouteHeavyCongestionColor(Color.parseColor(trafficHeavyColor))
                    .alternativeRouteSevereCongestionColor(Color.parseColor(trafficSevereColor))
                    .inActiveRouteLegsColor(Color.parseColor(traversedRouteColor))
                    .build()
                )
                .build()
            )
            .withRouteLineBelowLayerId("road-label")
            .displayRestrictedRoadSections(true)
            .build()
        routeLineApi = MapboxRouteLineApi(mapboxRouteLineOptions)
        routeLineView = MapboxRouteLineView(mapboxRouteLineOptions)

        binding.mapView.location.addOnIndicatorPositionChangedListener(onPositionChangedListener)

        // start the trip session to being receiving location updates in free drive
        // and later when a route is set also receiving route progress updates
        mapboxNavigation.startTripSession()

        // load map style
        mapboxMap.loadStyleUri(
            Style.LIGHT
        ) {
        }

        mapboxNavigation.registerLocationObserver(locationObserver)
        mapboxNavigation.registerRoutesObserver(routesObserver)
        mapboxNavigation.registerRouteProgressObserver(routeProgressObserver)
    }

    private fun startRoute() {
        // register event listeners
        //mapboxNavigation.registerRoutesObserver(routesObserver)
        //mapboxNavigation.registerLocationObserver(locationObserver)
        //mapboxNavigation.registerRouteProgressObserver(routeProgressObserver)
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

        // move the camera to overview when new route is available
        navigationCamera.requestNavigationCameraToOverview()
    }

    private fun clearRouteAndStopNavigation() {
        // clear
        mapboxNavigation.setRoutes(listOf())
    }

    private fun getPadding(padding: Array<Double>?): EdgeInsets {
        val mainPadding = this.mapPadding
        var top = if (padding != null) {
            if (padding!!.size > 0) {
                padding!!.get(0) * pixelDensity
            } else if (mainPadding != null && mainPadding!!.size > 0) {
                mainPadding!!.get(0) * pixelDensity
            } else {
                0.0
            }
        } else if (mainPadding != null) {
            if (mainPadding!!.size > 0) {
                mainPadding!!.get(0) * pixelDensity
            } else {
                0.0
            }
        } else {
            0.0
        }
        var left = if (padding != null) {
            if (padding!!.size > 1) {
                padding!!.get(1) * pixelDensity
            } else if (mainPadding != null && mainPadding!!.size > 1) {
                mainPadding!!.get(1) * pixelDensity
            } else {
                0.0
            }
        } else if (mainPadding != null) {
            if (mainPadding!!.size > 1) {
                mainPadding!!.get(1) * pixelDensity
            } else {
                0.0
            }
        } else {
            0.0
        }
        var bottom = if (padding != null) {
            if (padding!!.size > 2) {
                padding!!.get(2) * pixelDensity
            } else if (mainPadding != null && mainPadding!!.size > 2) {
                mainPadding!!.get(2) * pixelDensity
            } else {
                0.0
            }
        } else if (mainPadding != null) {
            if (mainPadding!!.size > 2) {
                mainPadding!!.get(2) * pixelDensity
            } else {
                0.0
            }
        } else {
            0.0
        }
        var right = if (padding != null) {
            if (padding!!.size > 3) {
                padding!!.get(3) * pixelDensity
            } else if (mainPadding != null && mainPadding!!.size > 3) {
                mainPadding!!.get(3) * pixelDensity
            } else {
                0.0
            }
        } else if (mainPadding != null) {
            if (mainPadding!!.size > 3) {
                mainPadding!!.get(3) * pixelDensity
            } else {
                0.0
            }
        } else {
            0.0
        }

        return EdgeInsets(
            top,
            left,
            bottom,
            right
        )
    }
    
    private fun updateLogoPadding() {
        val padding = this.logoPadding

        if (padding != null) {
            binding.mapView.logo.updateSettings {
                marginLeft = if (padding!!.size > 0) (padding!!.get(0).toFloat() * pixelDensity) else 0.0f
                marginBottom = if (padding!!.size > 1) (padding!!.get(1).toFloat() * pixelDensity) else 0.0f
                position = Gravity.BOTTOM or Gravity.LEFT
            }
        } else {
            binding.mapView.logo.updateSettings {
                marginLeft = 0.0f
                marginBottom = 0.0f
                position = Gravity.BOTTOM or Gravity.LEFT
            }
        }
    }
    
    private fun updateAttributionPadding() {
        val padding = this.attributionPadding

        if (padding != null) {
            binding.mapView.attribution.updateSettings {
                marginBottom = if (padding!!.size > 1) (padding!!.get(1).toFloat() * pixelDensity) else 0.0f
                marginRight = if (padding!!.size > 0) (padding!!.get(0).toFloat() * pixelDensity) else 0.0f
                position = Gravity.BOTTOM or Gravity.RIGHT
            }
        } else {
            binding.mapView.attribution.updateSettings {
                marginBottom = 0.0f
                marginRight = 0.0f
                position = Gravity.BOTTOM or Gravity.RIGHT
            }
        }
    }

    private fun onDestroy() {
        MapboxNavigationProvider.destroy()
        routeLineApi.cancel()
        routeLineView.cancel()
        //binding.mapView.location.removeOnIndicatorPositionChangedListener(onPositionChangedListener)
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()

        if (::mapboxNavigation.isInitialized) {
            mapboxNavigation.unregisterRoutesObserver(routesObserver)
            mapboxNavigation.unregisterLocationObserver(locationObserver)
            mapboxNavigation.unregisterRouteProgressObserver(routeProgressObserver)
        }
    }

    fun onDropViewInstance() {
        this.onDestroy()
    }

    fun showRoute(origin: ReadableArray?, destination: ReadableArray?, waypoints: ReadableArray?, styles: ReadableArray?, legIndex: Int?, cameraType: String?, padding: ReadableArray?)  {
        try {
            var routeWaypoints = mutableListOf<Point>()
            var routeWaypointNames = mutableListOf<String>()

            if (origin != null) {
                currentOrigin = Point.fromLngLat(origin.getDouble(0), origin.getDouble(1))
                routeWaypoints.add(Point.fromLngLat(origin.getDouble(0), origin.getDouble(1)))
            }

            if (waypoints != null) {
                var newCurrentWaypoints = mutableListOf<Point>()

                for (ii in 0 until waypoints.size()) {
                    val waypoint = waypoints.getArray(ii)

                    if (waypoint != null) {
                        newCurrentWaypoints.add(Point.fromLngLat(waypoint.getDouble(0), waypoint.getDouble(1)))
                        routeWaypoints.add(Point.fromLngLat(waypoint.getDouble(0), waypoint.getDouble(1)))
                    }
                }

                currentWaypoints = newCurrentWaypoints.toTypedArray()
            }

            if (destination != null) {
                currentDestination = Point.fromLngLat(destination.getDouble(0), destination.getDouble(1))
                routeWaypoints.add(Point.fromLngLat(destination.getDouble(0), destination.getDouble(1)))
            }

            if (styles != null) {
                for (ii in 0 until styles.size()) {
                    val style = styles.getMap(ii)

                    if (style != null) {
                        if (style.hasKey("name")) {
                            routeWaypointNames.add(style.getString("name")!!)
                        }
                    }
                }
            }

            currentLegIndex = if (legIndex != null) legIndex!! else -1

            mapboxNavigation.requestRoutes(
                RouteOptions.builder()
                    .applyDefaultNavigationOptions()
                    //.applyLanguageAndVoiceUnitOptions(context)
                    .coordinatesList(routeWaypoints.toList())
                    .waypointNamesList(routeWaypointNames.toList())
                    //.steps(true)
                    .build(),
                object : RouterCallback {
                    override fun onRoutesReady(
                        routes: List<DirectionsRoute>,
                        routerOrigin: RouterOrigin
                    ) {
                        if (routes.isEmpty()) {
                            sendErrorToReact("No route found")
                            return;
                        }
                        
                        mapboxNavigation.setRoutes(routes)

                        if (cameraType == "follow") {
                            follow(padding)
                        } else if (cameraType == "overview") {
                            moveToOverview(padding)
                        }
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
            sendErrorToReact(ex.toString() + "||" + ex.getStackTrace().joinToString())
        }
    }

    fun clearRoute() {
        clearRouteAndStopNavigation()
    }
    
    fun follow(padding: ReadableArray?) {
        var newPadding = mutableListOf<Double>()

        if (padding != null) {
            for (ii in 0 until padding!!.size()) {
                newPadding.add(padding!!.getDouble(ii))
            }
        }

        viewportDataSource.followingPadding = getPadding(newPadding.toTypedArray())

        navigationCamera.requestNavigationCameraToFollowing()
    }
    
    fun moveToOverview(padding: ReadableArray?) {
        var newPadding = mutableListOf<Double>()

        if (padding != null) {
            for (ii in 0 until padding!!.size()) {
                newPadding.add(padding!!.getDouble(ii))
            }
        }

        viewportDataSource.overviewPadding = getPadding(newPadding.toTypedArray())

        navigationCamera.requestNavigationCameraToOverview()
    }
    
    fun fitCamera(padding: ReadableArray?) {
        var newPadding = mutableListOf<Double>()

        if (padding != null) {
            for (ii in 0 until padding!!.size()) {
                newPadding.add(padding!!.getDouble(ii))
            }
        }

        viewportDataSource.overviewPadding = getPadding(newPadding.toTypedArray())

        navigationCamera.requestNavigationCameraToOverview()
    }
    
    fun setShowSpeedLimit(showSpeedLimit: Boolean) {
        this.showSpeedLimit = showSpeedLimit
    }

    fun setSpeedLimitAnchor(speedLimitAnchor: ReadableArray?) {
        if (speedLimitAnchor != null) {
            var newAnchor = mutableListOf<Double>()

            for (ii in 0 until speedLimitAnchor.size()) {
                newAnchor.add(speedLimitAnchor.getDouble(ii))
            }

            this.speedLimitAnchor = newAnchor.toTypedArray()
        } else {
            this.speedLimitAnchor = null
        }
    }
    
    fun setFollowZoomLevel(followZoomLevel: Double) {
        this.followZoomLevel = followZoomLevel
    }
    
    fun setUserPuckImage(userPuckImage: String?) {
        this.userPuckImage = userPuckImage
    }
    
    fun setUserPuckScale(userPuckScale: Double) {
        this.userPuckScale = userPuckScale
    }
    
    fun setDestinationImage(destinationImage: String?) {
        this.destinationImage = destinationImage
    }
    
    fun setMapPadding(mapPadding: ReadableArray?) {
        if (mapPadding != null) {
            var newPadding = mutableListOf<Double>()

            for (ii in 0 until mapPadding!!.size()) {
                newPadding.add(mapPadding!!.getDouble(ii))
            }

            this.mapPadding = newPadding.toTypedArray()
        } else {
            this.mapPadding = null
        }
    }
    
    fun setLogoVisible(logoVisible: Boolean) {
        this.logoVisible = logoVisible

        binding.mapView.logo.updateSettings {
            enabled = logoVisible
        }
    }
    
    fun setLogoPadding(logoPadding: ReadableArray?) {
        if (logoPadding != null) {
            var newPadding = mutableListOf<Double>()

            for (ii in 0 until logoPadding!!.size()) {
                newPadding.add(logoPadding!!.getDouble(ii))
            }

            this.logoPadding = newPadding.toTypedArray()
        } else {
            this.logoPadding = null
        }

        updateLogoPadding()
    }
    
    fun setAttributionVisible(attributionVisible: Boolean) {
        this.attributionVisible = attributionVisible

        binding.mapView.attribution.updateSettings {
            enabled = attributionVisible
        }
    }
    
    fun setAttributionPadding(attributionPadding: ReadableArray?) {
        if (attributionPadding != null) {
            var newPadding = mutableListOf<Double>()

            for (ii in 0 until attributionPadding!!.size()) {
                newPadding.add(attributionPadding!!.getDouble(ii))
            }

            this.attributionPadding = newPadding.toTypedArray()
        } else {
            this.attributionPadding = null
        }

        updateAttributionPadding()
    }
    
    fun setRouteColor(routeColor: String) {
        this.routeColor = routeColor
    }
    
    fun setRouteCasingColor(routeCasingColor: String) {
        this.routeCasingColor = routeCasingColor
    }
    
    fun setRouteClosureColor(routeClosureColor: String) {
        this.routeClosureColor = routeClosureColor
    }
    
    fun setAlternateRouteColor(alternateRouteColor: String) {
        this.alternateRouteColor = alternateRouteColor
    }
    
    fun setAlternateRouteCasingColor(alternateRouteCasingColor: String) {
        this.alternateRouteCasingColor = alternateRouteCasingColor
    }
    
    fun setTraversedRouteColor(traversedRouteColor: String?) {
        this.traversedRouteColor = traversedRouteColor
    }
    
    fun setTraversedRouteCasingColor(traversedRouteCasingColor: String?) {
        this.traversedRouteCasingColor = traversedRouteCasingColor
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
    
    fun setTrafficSevereColor(trafficSevereColor: String) {
        this.trafficSevereColor = trafficSevereColor
    }
    
    fun setRestrictedRoadColor(restrictedRoadColor: String) {
        this.restrictedRoadColor = restrictedRoadColor
    }
    
    fun setWaypointColor(waypointColor: String) {
        this.waypointColor = waypointColor
    }
    
    fun setWaypointRadius(waypointRadius: Int) {
        this.waypointRadius = waypointRadius
    }
    
    fun setWaypointOpacity(waypointOpacity: Int) {
        this.waypointOpacity = waypointOpacity
    }
    
    fun setWaypointStrokeWidth(waypointStrokeWidth: Int) {
        this.waypointStrokeWidth = waypointStrokeWidth
    }
    
    fun setWaypointStrokeOpacity(waypointStrokeOpacity: Int) {
        this.waypointStrokeOpacity = waypointStrokeOpacity
    }
    
    fun setWaypointStrokeColor(waypointStrokeColor: String) {
        this.waypointStrokeColor = waypointStrokeColor
    }
    
    fun setDebug(debug: Boolean) {
        this.debug = debug
    }
}
