// lib/constants/map_styles.dart
// Map styling constants for Google Maps customization

class MapStyles {
  MapStyles._(); // Private constructor to prevent instantiation

  /// Hides all Points of Interest (POIs) from Google Maps
  /// This includes restaurants, hospitals, gas stations, etc.
  static const String hideAllPois = '''[
    {
      "featureType": "poi",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.business",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.government",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.medical",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.place_of_worship",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.school",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.sports_complex",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "transit",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "transit.station",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
  ]''';

  /// Minimal style that only hides POIs and transit
  static const String hideBasicPois = '''[
    {
      "featureType": "poi",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "transit",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
  ]''';

  /// Dark theme map style with POIs hidden
  static const String darkStyleNoPois = '''[
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#212121"
        }
      ]
    },
    {
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#212121"
        }
      ]
    },
    {
      "featureType": "poi",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "transit",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#2c2c2c"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#8a8a8a"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#000000"
        }
      ]
    }
  ]''';

  /// Default Google Maps style (empty array)
  static const String defaultStyle = '[]';

  /// Returns appropriate style based on preferences
  static String getStyleForMode({
    bool hidePois = true,
    bool darkMode = false,
  }) {
    if (darkMode && hidePois) {
      return darkStyleNoPois;
    } else if (hidePois) {
      return hideBasicPois;
    } else {
      return defaultStyle;
    }
  }

  /// Available style options for UI selection
  static const Map<String, String> availableStyles = {
    'Default': defaultStyle,
    'Hide POIs': hideBasicPois,
    'Hide All POIs': hideAllPois,
    'Dark + No POIs': darkStyleNoPois,
  };
}