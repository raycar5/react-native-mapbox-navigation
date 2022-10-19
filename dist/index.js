import * as React from 'react';
import { Platform, findNodeHandle, requireNativeComponent, UIManager, StyleSheet, Image } from 'react-native';
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
    const showRoute = (origin = [], destination = [], waypoints = [], styles = [], legIndex = -1, cameraType = 'none', padding = []) => {
        if (Platform.OS === "android") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.showRouteViaManager, [origin, destination, waypoints, styles, legIndex, cameraType, padding]);
        }
        else if (Platform.OS === "ios") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.showRouteViaManager, [origin, destination, waypoints, styles, legIndex, cameraType, padding]);
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
    const follow = (padding = []) => {
        if (Platform.OS === "android") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.followViaManager, [padding]);
        }
        else if (Platform.OS === "ios") {
            UIManager.dispatchViewManagerCommand(findNodeHandle(mapboxNavigationFreeDriveRef.current), UIManager.MapboxNavigationFreeDrive.Commands.followViaManager, [padding]);
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
    const getUserImage = () => {
        if (Platform.OS === 'ios' || !props.userPuckImage) {
            return props.userPuckImage;
        }
        else {
            return (Image.resolveAssetSource(props.userPuckImage) || {}).uri;
        }
    };
    return <RNMapboxNavigationFreeDrive ref={mapboxNavigationFreeDriveRef} style={styles.container} {...Object.assign(Object.assign({}, props), { userPuckImage: getUserImage() })}/>;
});
const RNMapboxNavigation = requireNativeComponent('MapboxNavigation', MapboxNavigation);
const RNMapboxNavigationFreeDrive = requireNativeComponent('MapboxNavigationFreeDrive', MapboxNavigationFreeDrive);
const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
});
export { MapboxNavigation, MapboxNavigationFreeDrive };
