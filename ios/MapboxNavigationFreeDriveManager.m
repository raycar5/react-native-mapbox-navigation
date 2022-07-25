#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(MapboxNavigationFreeDriveManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(onLocationChange, RCTDirectEventBlock)

@end
