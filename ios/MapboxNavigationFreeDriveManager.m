#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(MapboxNavigationFreeDriveManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(onLocationChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(showSpeedLimit, BOOL)
RCT_EXPORT_VIEW_PROPERTY(followZoomLevel, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(userPuckImage, UIImage)
RCT_EXPORT_VIEW_PROPERTY(userPuckScale, NSNumber)

RCT_EXTERN_METHOD(
  showRouteViaManager: (NSNumber *)node
  origin: (NSArray *)origin 
  destination: (NSArray *)destination 
  waypoints: (NSArray *)waypoints
)

@end