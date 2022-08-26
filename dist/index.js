import * as React from 'react';
import { Platform, findNodeHandle, requireNativeComponent, NativeModules, UIManager, StyleSheet } from 'react-native';
const MapboxNavigation = (props) => {
    return <RNMapboxNavigation style={styles.container} {...props}/>;
};
const MapboxNavigationFreeDrive = React.forwardRef((props, ref) => {
    const mapboxNavigationFreeDriveRef = React.useRef();
    React.useImperativeHandle(ref, () => ({
        showRoute: (origin = [], destination = [], waypoints = []) => {
            showRoute(origin, destination, waypoints);
        }
    }));
    const showRoute = (origin = [], destination = [], waypoints = []) => {
        if (Platform.OS === "android") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.getViewManagerConfig("RNMapboxNavigationFreeDrive").Commands.showRoute, [origin, destination, waypoints]);
        }
        else if (Platform.OS === "ios") {
            return NativeModules.MapboxNavigationFreeDriveManager.showRoute(origin, destination, waypoints, findNodeHandle(mapboxNavigationFreeDriveRef.current));
        }
    };
    return <RNMapboxNavigationFreeDrive ref={mapboxNavigationFreeDriveRef} style={styles.container} {...props}/>;
});
const RNMapboxNavigation = requireNativeComponent('MapboxNavigation', MapboxNavigation);
const RNMapboxNavigationFreeDrive = requireNativeComponent('MapboxNavigationFreeDrive', MapboxNavigationFreeDrive);
const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
});
export { MapboxNavigation, MapboxNavigationFreeDrive };
