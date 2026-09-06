import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

const feedCategories = <String>[
  'All',
  'Roads & Transport',
  'Water & Sewage',
  'Electricity & Lighting',
  'Waste & Sanitation',
  'Public Hazards & Safety',
  'Public Infrastructure',
];

const feedSeverities = <String>['All', 'HIGH', 'MEDIUM', 'LOW'];

class FeedFilterBar extends StatefulWidget {
  const FeedFilterBar({
    required this.city,
    required this.category,
    required this.severity,
    required this.onChanged,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final String city;
  final String category;
  final String severity;
  final void Function(String city, String category, String severity) onChanged;
  final EdgeInsets margin;

  @override
  State<FeedFilterBar> createState() => _FeedFilterBarState();
}

class _FeedFilterBarState extends State<FeedFilterBar> {
  var _cities = const ['All'];
  late String _selectedCity = widget.city;
  late String _selectedCategory = widget.category;
  late String _selectedSeverity = widget.severity;

  @override
  void initState() {
    super.initState();
    _detectCity();
  }

  Future<void> _detectCity() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception();
      }
      final position = await Geolocator.getCurrentPosition();
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final city = places.isEmpty ? '' : (places.first.locality ?? '').trim();
      if (!mounted) return;
      if (city.isEmpty) {
        widget.onChanged(_selectedCity, _selectedCategory, _selectedSeverity);
        return;
      }
      setState(() => _cities = [city, 'All']);
      setState(() => _selectedCity = city);
      widget.onChanged(_selectedCity, _selectedCategory, _selectedSeverity);
    } catch (_) {
      if (mounted) {
        widget.onChanged(_selectedCity, _selectedCategory, _selectedSeverity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = _cities.contains(_selectedCity)
        ? _selectedCity
        : _cities.first;
    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _dropdown('City', city, _cities, (value) {
                setState(() => _selectedCity = value!);
                widget.onChanged(
                  _selectedCity,
                  _selectedCategory,
                  _selectedSeverity,
                );
              }),
              const SizedBox(width: 8),
              _dropdown('Category', _selectedCategory, feedCategories, (value) {
                setState(() => _selectedCategory = value!);
                widget.onChanged(city, _selectedCategory, _selectedSeverity);
              }),
              const SizedBox(width: 8),
              _dropdown('Severity', _selectedSeverity, feedSeverities, (value) {
                setState(() => _selectedSeverity = value!);
                widget.onChanged(city, _selectedCategory, _selectedSeverity);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            isDense: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F6FB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
