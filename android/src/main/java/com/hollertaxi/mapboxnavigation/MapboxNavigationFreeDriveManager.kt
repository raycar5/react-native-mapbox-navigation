package com.hollertaxi.mapboxnavigation

import android.content.pm.PackageManager
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.mapbox.geojson.Point
import com.mapbox.maps.ResourceOptionsManager
import com.mapbox.maps.TileStoreUsageMode
import javax.annotation.Nonnull

class MapboxNavigationFreeDriveManager(var mCallerContext: ReactApplicationContext) : SimpleViewManager<MapboxNavigationFreeDriveView>() {
    private var accessToken: String? = null

    init {
        mCallerContext.runOnUiQueueThread {
            try {
                val app = mCallerContext.packageManager.getApplicationInfo(mCallerContext.packageName, PackageManager.GET_META_DATA)
                val bundle = app.metaData
                val accessToken = bundle.getString("MAPBOX_ACCESS_TOKEN")
                this.accessToken = accessToken
                ResourceOptionsManager.getDefault(mCallerContext, accessToken).update {
                    tileStoreUsageMode(TileStoreUsageMode.READ_ONLY)
                }
            } catch (e: PackageManager.NameNotFoundException) {
                e.printStackTrace()
            }
        }
    }

    override fun getName(): String {
        return "MapboxNavigationFreeDrive"
    }

    public override fun createViewInstance(@Nonnull reactContext: ThemedReactContext): MapboxNavigationFreeDriveView {
        return MapboxNavigationFreeDriveView(reactContext, this.accessToken)
    }

    override fun onDropViewInstance(view: MapboxNavigationFreeDriveView) {
        view.onDropViewInstance()
        super.onDropViewInstance(view)
    }

    override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Map<String, String>>? {
        return MapBuilder.of<String, Map<String, String>>(
            "onLocationChange", MapBuilder.of("registrationName", "onLocationChange"),
            "onRouteProgressChange", MapBuilder.of("registrationName", "onRouteProgressChange"),
            "onRouteChangeEvent", MapBuilder.of("registrationName", "onRouteChangeEvent"),
            "onTrackingStateChangeEvent", MapBuilder.of("registrationName", "onTrackingStateChangeEvent"),
            "onErrorEvent", MapBuilder.of("registrationName", "onErrorEvent")
        )
    }

    override fun receiveCommand(view: MapboxNavigationFreeDriveView, commandId: String, args: ReadableArray?) {
        when (commandId) {
            "showRouteViaManager" -> view.showRoute(args.getArray(0), args.getArray(1), args.getArray(2), args.getArray(3), args.getInt(4), args.getString(5), args.getArray(6))
            "clearRouteViaManager" -> view.clearRoute()
            "followViaManager" -> view.follow()
            "moveToOverviewViaManager" -> view.moveToOverview(args.getArray(0))
            "fitCameraViaManager" -> view.fitCamera(args.getArray(0))
        }
    }

    @ReactProp(name = "showSpeedLimit")
    fun setShowSpeedLimit(view: MapboxNavigationFreeDriveView, showSpeedLimit: Boolean) {
        view.setShowSpeedLimit(showSpeedLimit)
    }

    @ReactProp(name = "speedLimitAnchor")
    fun setSpeedLimitAnchor(view: MapboxNavigationFreeDriveView, speedLimitAnchor: ReadableArray?) {
        view.setSpeedLimitAnchor(speedLimitAnchor)
    }
    
    @ReactProp(name = "followZoomLevel")
    fun setFollowZoomLevel(view: MapboxNavigationFreeDriveView, followZoomLevel: Double) {
        view.setFollowZoomLevel(followZoomLevel)
    }
    
    @ReactProp(name = "userPuckImage")
    fun serUserPuckImage(view: MapboxNavigationFreeDriveView, userPuckImage: String) {
        view.serUserPuckImage(userPuckImage)
    }
    
    @ReactProp(name = "userPuckScale")
    fun setUserPuckScale(view: MapboxNavigationFreeDriveView, userPuckScale: Double) {
        view.setUserPuckScale(userPuckScale)
    }
    
    @ReactProp(name = "destinationImage")
    fun setDestinationImage(view: MapboxNavigationFreeDriveView, destinationImage: String) {
        view.setDestinationImage(destinationImage)
    }
    
    @ReactProp(name = "mapPadding")
    fun setMapPadding(view: MapboxNavigationFreeDriveView, mapPadding: ReadableArray?) {
        view.setMapPadding(mapPadding)
    }
    
    @ReactProp(name = "logoVisible")
    fun setLogoVisible(view: MapboxNavigationFreeDriveView, logoVisible: Boolean) {
        view.setLogoVisible(logoVisible)
    }
    
    @ReactProp(name = "logoPadding")
    fun setLogoPadding(view: MapboxNavigationFreeDriveView, logoPadding: ReadableArray?) {
        view.setLogoPadding(logoPadding)
    }
    
    @ReactProp(name = "attributionVisible")
    fun setAttributionVisible(view: MapboxNavigationFreeDriveView, attributionVisible: Boolean) {
        view.setAttributionVisible(attributionVisible)
    }
    
    @ReactProp(name = "attributionPadding")
    fun setAttributionPadding(view: MapboxNavigationFreeDriveView, attributionPadding: ReadableArray?) {
        view.setAttributionPadding(attributionPadding)
    }
    
    @ReactProp(name = "routeCasingColor")
    fun setRouteCasingColor(view: MapboxNavigationFreeDriveView, routeCasingColor: String) {
        view.setRouteCasingColor(routeCasingColor)
    }
    
    @ReactProp(name = "traversedRouteColor")
    fun setTraversedRouteColor(view: MapboxNavigationFreeDriveView, traversedRouteColor: String) {
        view.setTraversedRouteColor(traversedRouteColor)
    }
    
    @ReactProp(name = "trafficUnknownColor")
    fun setTrafficUnknownColor(view: MapboxNavigationFreeDriveView, trafficUnknownColor: String) {
        view.setTrafficUnknownColor(trafficUnknownColor)
    }
    
    @ReactProp(name = "trafficLowColor")
    fun setTrafficLowColor(view: MapboxNavigationFreeDriveView, trafficLowColor: String) {
        view.setTrafficLowColor(trafficLowColor)
    }
    
    @ReactProp(name = "trafficModerateColor")
    fun setTrafficModerateColor(view: MapboxNavigationFreeDriveView, trafficModerateColor: String) {
        view.setTrafficModerateColor(trafficModerateColor)
    }
    
    @ReactProp(name = "trafficHeavyColor")
    fun setTrafficHeavyColor(view: MapboxNavigationFreeDriveView, trafficHeavyColor: String) {
        view.setTrafficHeavyColor(trafficHeavyColor)
    }
    
    @ReactProp(name = "trafficSevereColor")
    fun setTrafficSevereColor(view: MapboxNavigationFreeDriveView, trafficSevereColor: String) {
        view.setTrafficSevereColor(trafficSevereColor)
    }
    
    @ReactProp(name = "waypointColor")
    fun setWaypointColor(view: MapboxNavigationFreeDriveView, waypointColor: String) {
        view.setWaypointColor(waypointColor)
    }
    
    @ReactProp(name = "waypointRadius")
    fun setWaypointRadius(view: MapboxNavigationFreeDriveView, waypointRadius: Double) {
        view.setWaypointRadius(waypointRadius)
    }
    
    @ReactProp(name = "waypointOpacity")
    fun setWaypointOpacity(view: MapboxNavigationFreeDriveView, waypointOpacity: Double) {
        view.setWaypointOpacity(waypointOpacity)
    }
    
    @ReactProp(name = "waypointStrokeWidth")
    fun setWaypointStrokeWidth(view: MapboxNavigationFreeDriveView, waypointStrokeWidth: Double) {
        view.setWaypointStrokeWidth(waypointStrokeWidth)
    }
    
    @ReactProp(name = "waypointStrokeOpacity")
    fun setWaypointStrokeOpacity(view: MapboxNavigationFreeDriveView, waypointStrokeOpacity: Double) {
        view.setWaypointStrokeOpacity(waypointStrokeOpacity)
    }
    
    @ReactProp(name = "waypointStrokeColor")
    fun setWaypointStrokeColor(view: MapboxNavigationFreeDriveView, waypointStrokeColor: String) {
        view.setWaypointStrokeColor(waypointStrokeColor)
    }
}
