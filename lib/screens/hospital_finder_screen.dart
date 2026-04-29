import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/hospital_place.dart';
import '../services/hospital_search_service.dart';
import '../theme/app_theme.dart';

class HospitalFinderScreen extends StatefulWidget {
  const HospitalFinderScreen({super.key});

  @override
  State<HospitalFinderScreen> createState() => _HospitalFinderScreenState();
}

class _HospitalFinderScreenState extends State<HospitalFinderScreen> {
  static const LatLng _defaultCenter = LatLng(37.5665, 126.9780);

  final TextEditingController _searchController = TextEditingController();
  final HospitalSearchService _hospitalSearchService = HospitalSearchService();
  GoogleMapController? _mapController;
  LatLng _currentCenter = _defaultCenter;
  bool _isLoading = false;
  String? _errorMessage;
  List<HospitalPlace> _searchResults = const [];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final center = LatLng(position.latitude, position.longitude);
      setState(() => _currentCenter = center);
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 14),
        ),
      );
    } catch (_) {
      // Keep default center when location lookup fails.
    }
  }

  Set<Marker> get _markers {
    return _searchResults
        .map(
          (hospital) => Marker(
            markerId: MarkerId(hospital.name),
            position: LatLng(hospital.latitude, hospital.longitude),
            infoWindow: InfoWindow(
              title: hospital.name,
              snippet: hospital.address,
            ),
          ),
        )
        .toSet();
  }

  Future<void> _searchHospitals() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _hospitalSearchService.searchHospitals(
        query: _searchController.text,
        latitude: _currentCenter.latitude,
        longitude: _currentCenter.longitude,
      );

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isLoading = false;
        if (results.isEmpty) {
          _errorMessage = '검색된 병원이 없어요.';
        }
      });

      if (results.isNotEmpty) {
        final first = results.first;
        await _moveToHospital(first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '병원 검색 중 문제가 생겼어요.';
      });
    }
  }

  Future<void> _moveToHospital(HospitalPlace hospital) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(hospital.latitude, hospital.longitude),
          zoom: 15.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospitals = _searchResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('병원찾기'),
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7FBF7),
              Color(0xFFF1F7F2),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentCenter,
                            zoom: 11.5,
                          ),
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          markers: _markers,
                          onMapCreated: (controller) =>
                              _mapController = controller,
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.06),
                                Colors.transparent,
                                const Color(0xFF0F2315).withValues(alpha: 0.18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 18,
                        left: 18,
                        right: 18,
                        child: Row(
                          children: [
                            _buildMapBadge(
                              icon: Icons.local_hospital_rounded,
                              label: '병원 지도',
                            ),
                            const SizedBox(width: 8),
                            _buildMapBadge(
                              icon: Icons.place_rounded,
                              label: '${hospitals.length}곳',
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '내 주변 병원을 빠르게 찾아보세요',
                              style: TextStyle(
                                fontSize: 22,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '검색한 병원 결과를 지도와 목록에서 함께 확인할 수 있어요.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE4ECE5)),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFBFD1C2).withValues(alpha: 0.20),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '병원 검색',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8F3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isLoading ? '검색 중' : '실시간',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FBF8),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE2EBE3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onSubmitted: (_) => _searchHospitals(),
                                  decoration: const InputDecoration(
                                    hintText: '병원명 또는 주소 검색',
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: AppColors.primary,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = const [];
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _searchHospitals,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(88, 46),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('검색'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: _errorMessage != null
                              ? _buildInfoState(message: _errorMessage!)
                              : hospitals.isEmpty
                                  ? _buildInfoState(
                                      message: '검색 결과가 여기에 표시돼요.',
                                      icon: Icons.travel_explore_rounded,
                                    )
                                  : ListView.separated(
                                      itemCount: hospitals.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final hospital = hospitals[index];
                                        return _buildHospitalResultCard(
                                            hospital);
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoState({
    required String message,
    IconData icon = Icons.info_outline_rounded,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECE5)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalResultCard(HospitalPlace hospital) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _moveToHospital(hospital),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FCFA),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5ECE6)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE9F8EE),
                    Color(0xFFD8F0E0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hospital.address,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF7F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
