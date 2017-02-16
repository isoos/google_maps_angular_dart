import 'dart:math';

import 'package:angular2/core.dart';
import 'package:google_maps/google_maps.dart';

/// Const value to convert from km to miles.
final double milesPerKm = 0.621371;

/// Radius of the earth in km.
final int radiusOfEarth = 6371;

/// The map control component that embeds the Google Maps widget and related
/// controls. Additionally it contains the distance calculation.
@Component(
    selector: 'map-control',
    templateUrl: 'map_control.html',
    styleUrls: const <String>['map_control.css'])
class MapControl implements AfterViewInit {
  GMap _map;
  Marker _aMarker;
  Marker _bMarker;

  /// Position of the 'A' marker.
  LatLng get a => _aMarker?.position;

  /// Position of the 'B' marker.
  LatLng get b => _bMarker?.position;

  /// Formatted position of the 'A' marker.
  String get aPosition => _formatPosition(a);

  /// Formatted position of the 'B' marker.
  String get bPosition => _formatPosition(b);

  /// Whether the 'A' marker's positions should be shown
  bool get showA => a != null;

  /// Whether the 'B' marker's positions should be shown
  bool get showB => b != null;

  String _unit = 'km';

  /// Unit for the distance.
  String get unit => _unit;
  set unit(String value) {
    _unit = value;
    _updateDistance();
  }

  /// Formatted distance (contains unit).
  String distance;

  /// Whether the 'distance' label should be shown
  bool get showDistance => distance != null;

  /// The DOM element reference for the Google Maps initialization.
  @ViewChild('mapArea')
  ElementRef mapAreaRef;

  @override
  void ngAfterViewInit() {
    _map = new GMap(
        mapAreaRef.nativeElement,
        new MapOptions()
          ..zoom = 2
          ..center = new LatLng(47.4979, 19.0402) // Budapest, Hungary
        );
    _map.onClick.listen((MouseEvent event) {
      _updatePosition(event.latLng);
      _updateDistance();
    });
  }

  String _formatPosition(LatLng position) {
    if (position == null) return null;
    return '${position.lat.toStringAsFixed(4)}, '
        '${position.lng.toStringAsFixed(4)}';
  }

  void _updatePosition(LatLng position) {
    if (_aMarker == null) {
      _aMarker = _createMarker(_map, 'A', position);
    } else if (_bMarker == null) {
      _bMarker = _createMarker(_map, 'B', position);
    } else {
      _aMarker.position = _bMarker.position;
      _bMarker.position = position;
    }
  }

  Marker _createMarker(GMap map, String label, LatLng position) {
    final Marker marker = new Marker(new MarkerOptions()
      ..map = map
      ..draggable = true
      ..label = label
      ..position = position);
    marker.onDrag.listen((MouseEvent event) {
      _updateDistance();
    });
    return marker;
  }

  void _updateDistance() {
    if (_aMarker == null || _bMarker == null) return;
    double d = _calculateDistance();
    if (unit == 'miles') {
      d *= milesPerKm;
    }
    distance = '${d.round()} $unit';
  }

  double _toRadian(num degree) => degree * PI / 180.0;

  double _calculateDistance() {
    final double dLat = _toRadian(b.lat - a.lat);
    final double sLat = pow(sin(dLat / 2), 2);
    final double dLng = _toRadian(b.lng - a.lng);
    final double sLng = pow(sin(dLng / 2), 2);
    final double cosALat = cos(_toRadian(a.lat));
    final double cosBLat = cos(_toRadian(b.lat));
    final double x = sLat + cosALat * cosBLat * sLng;
    return 2 * atan2(sqrt(x), sqrt(1 - x)) * radiusOfEarth;
  }
}
