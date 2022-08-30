/** @type {[number, number]}
 * Provide an array with longitude and latitude [$longitude, $latitude]
 */
type Coordinate = [number, number];
type Padding = [number, number, number, number];

type OnLocationChangeEvent = {
  nativeEvent?: {
    latitude: number;
    longitude: number;
    roadName: string;
  };
};

type OnTrackingStateChangeEvent = {
  nativeEvent?: {
    state: string
  }
}

type OnRouteProgressChangeEvent = {
  nativeEvent?: {
    distanceTraveled: number;
    durationRemaining: number;
    fractionTraveled: number;
    distanceRemaining: number;
  };
};

type OnErrorEvent = {
  nativeEvent?: {
    message?: string;
  };
};

export interface IMapboxNavigationProps {
  origin: Coordinate;
  destination: Coordinate;
  shouldSimulateRoute?: boolean;
  onLocationChange?: (event: OnLocationChangeEvent) => void;
  onRouteProgressChange?: (event: OnRouteProgressChangeEvent) => void;
  onError?: (event: OnErrorEvent) => void;
  onCancelNavigation?: () => void;
  onArrive?: () => void;
  showsEndOfRouteFeedback?: boolean;
  hideStatusView?: boolean;
  mute?: boolean;
}

export interface IMapboxNavigationFreeDriveProps {
  onLocationChange?: (event: OnLocationChangeEvent) => void;
  onTrackingStateChange?: (event: OnTrackingStateChangeEvent) => void;
  showSpeedLimit?: boolean;
  showSpeedLimitAnchor?: Padding;
  followZoomLevel?: number;
  userPuckImage?: string;
  userPuckScale?: number;
  destinationImage?: string;
  mapPadding?: Padding;
  logoVisible?: boolean;
  logoPadding?: Coordinate;
  attributionVisible?: boolean;
  attributionPadding?: Coordinate;
  lineColor?: string;
  altLineColor?: string;
  unknownLineColor?: string;
  waypointColor?: string;
  waypointRadius?: number;
  waypointBorderWidth?: number;
  waypointBorderColor?: string;
}