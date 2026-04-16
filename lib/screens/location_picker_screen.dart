import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String title;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = "위치 선택",
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selected;
  String _address = "지도를 탭해 위치를 선택해 주세요.";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selected = LatLng(
      widget.initialLat ?? 37.5665,
      widget.initialLng ?? 126.9780,
    );
    if (widget.initialLat != null && widget.initialLng != null) {
      _resolveAddress(_selected);
    }
  }

  Future<void> _resolveAddress(LatLng position) async {
    setState(() => _loading = true);
    try {
      await setLocaleIdentifier('ko_KR');
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      if (placemarks.isEmpty) {
        setState(() {
          _address = "위도 ${position.latitude.toStringAsFixed(5)}, 경도 ${position.longitude.toStringAsFixed(5)}";
        });
      } else {
        final p = placemarks.first;
        final text = [
          p.administrativeArea,
          p.subAdministrativeArea,
          p.locality,
          p.subLocality,
          p.thoroughfare,
          p.subThoroughfare,
        ].where((e) => (e ?? '').trim().isNotEmpty).join(' ');

        final containsEnglish = RegExp(r'[A-Za-z]').hasMatch(text);
        setState(() {
          _address = text.isEmpty || containsEnglish
              ? "위도 ${position.latitude.toStringAsFixed(5)}, 경도 ${position.longitude.toStringAsFixed(5)}"
              : text;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _address = "위도 ${position.latitude.toStringAsFixed(5)}, 경도 ${position.longitude.toStringAsFixed(5)}";
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _selected, zoom: 15),
              myLocationButtonEnabled: false,
              onTap: (position) {
                setState(() => _selected = position);
                _resolveAddress(position);
              },
              markers: {
                Marker(
                  markerId: const MarkerId("selected"),
                  position: _selected,
                ),
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "선택 위치",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _address,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              LocationPickerResult(
                                latitude: _selected.latitude,
                                longitude: _selected.longitude,
                                address: _address,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "이 위치 사용",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
