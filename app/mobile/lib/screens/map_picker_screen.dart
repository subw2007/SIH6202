import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class MapPickerResult {
  const MapPickerResult({required this.point, required this.address});

  final LatLng point;
  final String address;
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({required this.initialPoint, super.key});

  final LatLng initialPoint;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _point = widget.initialPoint;
  bool _isConfirming = false;

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);
    var address =
        '${_point.latitude.toStringAsFixed(5)}, ${_point.longitude.toStringAsFixed(5)}';
    try {
      final places = await placemarkFromCoordinates(
        _point.latitude,
        _point.longitude,
      );
      if (places.isNotEmpty) {
        final place = places.first;
        final parts = [
          place.street,
          place.locality,
          place.administrativeArea,
        ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
        if (parts.isNotEmpty) address = parts.join(', ');
      }
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop(MapPickerResult(point: _point, address: address));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose location'),
        actions: [
          TextButton(
            onPressed: _isConfirming ? null : _confirm,
            child: _isConfirming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _point,
              initialZoom: 16,
              onPositionChanged: (position, _) {
                setState(() => _point = position.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.civicpulse.mobile',
              ),
            ],
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(
                Icons.location_pin,
                color: Color(0xFF4A62AD),
                size: 52,
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Drag the map to place the pin at the issue location.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
