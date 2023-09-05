import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../utils/constants.dart';
import '../utils/notification_handler.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({Key? key}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => OrderTrackingScreenState();
}

class OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  NotificationHandler notificationHandler = NotificationHandler();

  static const LatLng pickupLocation = LatLng(37.33500926, -122.03272188);
  static const LatLng delivery = LatLng(37.33429383, -122.06600055);

  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? deliveryIcon;
  BitmapDescriptor? driverLocationIcon;

  List<LatLng> polylineCoordinates = [];
  LocationData? driverLocation;
  String userStatusText = 'On the way';

  @override
  void initState() {
    super.initState();
    setCustomMarkerIcon();
    getPolyPoints();
    getCurrentLocation();
  }

  // Function to set custom marker icons
  Future<void> setCustomMarkerIcon() async {
    final pickup = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/Pin_pickup.png");
    final delivery = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/Pin_delivery.png");
    final driverLocation = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/Badge.png");

    setState(() {
      pickupIcon = pickup;
      deliveryIcon = delivery;
      driverLocationIcon = driverLocation;
    });
  }

  // Function to get polyline points
  void getPolyPoints() async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(pickupLocation.latitude, pickupLocation.longitude),
      PointLatLng(delivery.latitude, delivery.longitude),
    );
    if (result.points.isNotEmpty) {
      setState(() {
        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
    }
  }

  // Function to get current location
  void getCurrentLocation() async {
    final location = Location();
    final currentLocation = await location.getLocation();
    setState(() {
      driverLocation = currentLocation;
    });

    final googleMapController = await _controller.future;
    location.onLocationChanged.listen((newLoc) {
      setState(() {
        driverLocation = newLoc;
      });

      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            zoom: 12.5,
            target: LatLng(newLoc.latitude!, newLoc.longitude!),
          ),
        ),
      );
      checkGeoFences(); // Check geofences when location changes
    });
  }

  // Function to check geoFences and send notifications
  void checkGeoFences() {
    if (driverLocation != null) {
      final distanceToPickup = calculateDistance(
        driverLocation!.latitude!,
        driverLocation!.longitude!,
        pickupLocation.latitude,
        pickupLocation.longitude,
      );
      final distanceToDelivery = calculateDistance(
        driverLocation!.latitude!,
        driverLocation!.longitude!,
        delivery.latitude,
        delivery.longitude,
      );

      // Notify user when driver is near pickup or delivery
      if (distanceToPickup <= 5000) {
        setState(() {
          userStatusText = 'Driver is near pickup';
        });
        sendNotification(
          title: 'Driver Near Pickup',
          body: 'Your driver is near the pickup location.',
        );
      }
      if (distanceToDelivery <= 5000) {
        setState(() {
          userStatusText = 'Driver is near delivery';
        });
        sendNotification(
          title: 'Driver Near Delivery',
          body: 'Your driver is near the delivery location.',
        );
      }
      // Notify user when driver arrives at pickup or delivery
      if (distanceToPickup <= 100) {
        setState(() {
          userStatusText = 'Driver arrives at pickup';
        });
        sendNotification(
          title: 'Driver Arrived at Pickup',
          body: 'Your driver has arrived at the pickup location.',
        );
      }
      if (distanceToDelivery <= 100) {
        setState(() {
          userStatusText = 'Driver arrives at delivery';
        });
        sendNotification(
          title: 'Driver Arrived at Delivery',
          body: 'Your driver has arrived at the delivery location.',
        );
      }
    }
  }

  // Function to calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371; // Radius of the Earth in kilometers
    double degreesToRadians(double degrees) {
      return degrees * (math.pi / 180);
    }

    double dLat = degreesToRadians(lat2 - lat1);
    double dLon = degreesToRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(degreesToRadians(lat1)) *
            math.cos(degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radius * c * 1000; // Distance in meters
  }

  // Function to send notifications
  void sendNotification({
    required String title,
    required String body,
  }) {
    notificationHandler.showLocalNotification(
      title: title,
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track order",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: driverLocation == null
          ? const Center(child: Text("Loading"))
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                        driverLocation!.latitude!, driverLocation!.longitude!),
                    zoom: 15,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("route"),
                      points: polylineCoordinates,
                      color: lineColor,
                      width: 6,
                    ),
                  },
                  markers: {
                    if (driverLocationIcon != null)
                      Marker(
                        markerId: const MarkerId("driverLocation"),
                        position: LatLng(driverLocation!.latitude!,
                            driverLocation!.longitude!),
                        icon: driverLocationIcon!,
                      ),
                    if (pickupIcon != null)
                      Marker(
                        markerId: const MarkerId('pickup'),
                        position: pickupLocation,
                        icon: pickupIcon!,
                      ),
                    if (deliveryIcon != null)
                      Marker(
                        markerId: const MarkerId('delivery'),
                        icon: deliveryIcon!,
                        position: delivery,
                      ),
                  },
                ),
                PositionedDirectional(
                  bottom: 0,
                  child: Container(
                    color: Colors.white,
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      child: Text(
                        userStatusText,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
