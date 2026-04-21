import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../controller/store_controller.dart';
import '../../model/store_model.dart';
import '../../service/location_service.dart';
import '../widgets/store_detail_sheet.dart';

class FindStorePage extends StatefulWidget {
  const FindStorePage({super.key});

  @override
  State<FindStorePage> createState() => _FindStorePageState();
}

class _FindStorePageState extends State<FindStorePage> {
  final MapController _mapController = MapController();

  // FIX 6: Track location state
  bool _locationInitialised = false;

  @override
  void initState() {
    super.initState();
    // FIX 6: Trigger location detection as soon as the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    if (_locationInitialised) return;
    _locationInitialised = true;

    final storeCtrl = context.read<StoreController>();
    await storeCtrl.initLocationBasedStore();

    // Pan the map to user's current position if available
    if (mounted && storeCtrl.userPosition != null) {
      final pos = storeCtrl.userPosition!;
      _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
    } else if (mounted && storeCtrl.selectedStore != null) {
      final store = storeCtrl.selectedStore!;
      _mapController.move(LatLng(store.latitude, store.longitude), 13.0);
    }
  }

  void _onStoreTapped(Store store, StoreController storeCtrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoreDetailBottomSheet(store: store),
    );
    _mapController.move(LatLng(store.latitude, store.longitude), 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Store', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF5F5F0),
        foregroundColor: const Color(0xFF1E4620),
        centerTitle: true,
        // FIX 6: Re-locate button in app bar
        actions: [
          Consumer<StoreController>(
            builder: (context, storeCtrl, _) {
              return IconButton(
                icon: const Icon(Icons.my_location, color: Color(0xFF1E4620)),
                tooltip: 'Find nearest store',
                onPressed: () async {
                  await storeCtrl.initLocationBasedStore();
                  if (!mounted) return;
                  if (storeCtrl.userPosition != null) {
                    final pos = storeCtrl.userPosition!;
                    _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<StoreController>(
        builder: (context, storeCtrl, _) {
          // Default centre — use user position if available, else nearest store
          final defaultLat = storeCtrl.userPosition?.latitude
              ?? storeCtrl.selectedStore?.latitude
              ?? 5.4206;
          final defaultLng = storeCtrl.userPosition?.longitude
              ?? storeCtrl.selectedStore?.longitude
              ?? 100.3429;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(defaultLat, defaultLng),
                  initialZoom:   13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains:          const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.nuburn.nutritionapp.mealshop.v4',
                  ),
                  // FIX 6: Show user's current location dot on map
                  if (storeCtrl.userPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            storeCtrl.userPosition!.latitude,
                            storeCtrl.userPosition!.longitude,
                          ),
                          width:  24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color:  const Color(0xFF1E4620),
                              shape:  BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Store markers
                  MarkerLayer(
                    markers: storeCtrl.stores.map((store) {
                      return Marker(
                        point:  LatLng(store.latitude, store.longitude),
                        width:  65,
                        height: 65,
                        child: GestureDetector(
                          onTap: () => _onStoreTapped(store, storeCtrl),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color:       Colors.white,
                                  shape:       BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                        color:     Colors.black26,
                                        blurRadius: 4,
                                        offset:    Offset(0, 2)),
                                  ],
                                  border: Border.all(
                                    color: store.id == storeCtrl.selectedStore?.id
                                        ? const Color(0xFFD95F2B)
                                        : const Color(0xFFABC270),
                                    width: store.id == storeCtrl.selectedStore?.id ? 3 : 2,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: Image.asset(
                                  store.logoUrl,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.location_on,
                                      color: Color(0xFFBF5D32)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // FIX 6: Location loading overlay
              if (!_locationInitialised)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color:     Colors.black12,
                              blurRadius: 8)
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width:  14,
                            height: 14,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:       Color(0xFF1E4620)),
                          ),
                          SizedBox(width: 8),
                          Text('Finding your location...',
                              style: TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w600,
                                  color:      Color(0xFF1E4620))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}