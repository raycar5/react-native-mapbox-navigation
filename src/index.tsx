import * as React from 'react';
import { Platform, findNodeHandle, requireNativeComponent, NativeModules, UIManager, StyleSheet } from 'react-native';

import { IMapboxNavigationProps, IMapboxNavigationFreeDriveProps } from './typings';

const MapboxNavigation = (props: IMapboxNavigationProps) => {
  return <RNMapboxNavigation style={styles.container} {...props} />;
};

const MapboxNavigationFreeDrive = React.forwardRef((props: IMapboxNavigationFreeDriveProps, ref) => {
  const mapboxNavigationFreeDriveRef = React.useRef()

  React.useImperativeHandle(ref, () => ({
    showRoute
  }))

  const showRoute = (origin = [], destination = [], waypoints = []) => {
    if (Platform.OS === "android") {
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(mapboxNavigationFreeDriveRef.current),
        UIManager.getViewManagerConfig('RNMapboxNavigationFreeDrive').Commands.showRouteViaManager,
        [origin, destination, waypoints]
      )
    } else if (Platform.OS === "ios") {
      NativeModules.MapboxNavigationFreeDrive.showRouteViaManager(findNodeHandle(mapboxNavigationFreeDriveRef.current), origin, destination, waypoints)
      //UIManager.dispatchViewManagerCommand(
        //findNodeHandle(mapboxNavigationFreeDriveRef.current),
        //UIManager.getViewManagerConfig('RNMapboxNavigationFreeDrive').Commands.showRouteViaManager,
        //[origin, destination, waypoints]
      //)
    }
  }

  return <RNMapboxNavigationFreeDrive ref={mapboxNavigationFreeDriveRef} style={styles.container} {...props} />;
});

const RNMapboxNavigation = requireNativeComponent(
  'MapboxNavigation',
  MapboxNavigation
);

const RNMapboxNavigationFreeDrive = requireNativeComponent(
  'MapboxNavigationFreeDrive',
  MapboxNavigationFreeDrive
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});

export { MapboxNavigation, MapboxNavigationFreeDrive }