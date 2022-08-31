import * as React from 'react';
import { Platform, findNodeHandle, requireNativeComponent, UIManager, StyleSheet } from 'react-native';
const MapboxNavigation = (props) => {
    return <RNMapboxNavigation style={styles.container} {...props}/>;
};
const MapboxNavigationFreeDrive = React.forwardRef((props, ref) => {
    const mapboxNavigationFreeDriveRef = React.useRef();
    React.useImperativeHandle(ref, () => ({
        showRoute,
        clearRoute,
        follow,
        moveToOverview,
        fitCamera
    }));
    const showRoute = (origin = [], destination = [], waypoints = [[]], styles = [], legIndex = -1, onSuccess = null, onFailure = null) => {
        if (Platform.OS === "android") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.showRouteViaManager, [origin, destination, waypoints, styles, legIndex, onSuccess, onFailure]);
        }
        else if (Platform.OS === "ios") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.showRouteViaManager, [origin, destination, waypoints, styles, legIndex, onSuccess, onFailure]);
        }
    };
    const clearRoute = () => {
        if (Platform.OS === "android") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.clearRouteViaManager, []);
        }
        else if (Platform.OS === "ios") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.clearRouteViaManager, []);
        }
    };
    const follow = () => {
        if (Platform.OS === "android") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.followViaManager, []);
        }
        else if (Platform.OS === "ios") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.followViaManager, []);
        }
    };
    const moveToOverview = (padding = []) => {
        if (Platform.OS === "android") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.moveToOverviewViaManager, [padding]);
        }
        else if (Platform.OS === "ios") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.moveToOverviewViaManager, [padding]);
        }
    };
    const fitCamera = (padding = []) => {
        if (Platform.OS === "android") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.fitCameraViaManager, [padding]);
        }
        else if (Platform.OS === "ios") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.fitCameraViaManager, [padding]);
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
