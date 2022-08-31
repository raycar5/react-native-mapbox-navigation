#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(MapboxNavigationFreeDriveManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(onLocationChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onTrackingStateChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRouteChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(showSpeedLimit, BOOL)
RCT_EXPORT_VIEW_PROPERTY(speedLimitAnchor, NSArray)
RCT_EXPORT_VIEW_PROPERTY(followZoomLevel, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(userPuckImage, UIImage)
RCT_EXPORT_VIEW_PROPERTY(userPuckScale, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(destinationImage, UIImage)
RCT_EXPORT_VIEW_PROPERTY(mapPadding, NSArray)
RCT_EXPORT_VIEW_PROPERTY(logoVisible, NSArray)
RCT_EXPORT_VIEW_PROPERTY(logoPadding, NSArray)
RCT_EXPORT_VIEW_PROPERTY(attributionVisible, NSArray)
RCT_EXPORT_VIEW_PROPERTY(attributionPadding, NSArray)
RCT_EXPORT_VIEW_PROPERTY(lineColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(altLineColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(waypointColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(waypointRadius, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(waypointOpacity, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(waypointStrokeWidth, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(waypointStrokeOpacity, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(waypointStrokeColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(unknownLineColor, NSString)

RCT_EXTERN_METHOD(
  showRouteViaManager: (nonnull NSNumber *)node
  origin: (NSArray *)origin 
  destination: (NSArray *)destination 
  waypoints: (NSArray *)waypoints
  padding: (NSArray *)padding
  styles: (NSDictionaryArray *)styles
  legIndex: (nonnull NSNumber *)legIndex
)

RCT_EXTERN_METHOD(
  clearRouteViaManager: (nonnull NSNumber *)node
)

RCT_EXTERN_METHOD(
  followViaManager: (nonnull NSNumber *)node
)

RCT_EXTERN_METHOD(
  moveToOverviewViaManager: (nonnull NSNumber *)node
)

RCT_EXTERN_METHOD(
  fitCameraViaManager: (nonnull NSNumber *)node
  padding: (NSArray *)padding
)

@end