#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(MapboxNavigationFreeDriveManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(onLocationChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(showSpeedLimit, BOOL)
RCT_EXPORT_VIEW_PROPERTY(followZoomLevel, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(userPuckImage, UIImage)
RCT_EXPORT_VIEW_PROPERTY(userPuckScale, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(destinationImage, UIImage)
RCT_EXPORT_VIEW_PROPERTY(mapPadding, NSArray)

RCT_EXTERN_METHOD(
  showRouteViaManager: (nonnull NSNumber *)node
  origin: (NSArray *)origin 
  destination: (NSArray *)destination 
  waypoints: (NSArray *)waypoints
  padding: (NSArray *)padding
)

RCT_EXTERN_METHOD(
  clearRouteViaManager: (nonnull NSNumber *)node
)

RCT_EXTERN_METHOD(
  followViaManager: (nonnull NSNumber *)node
)

@end