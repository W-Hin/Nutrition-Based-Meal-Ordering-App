import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../controller/store_controller.dart';
import '../../model/store_model.dart';
import '../widgets/store_detail_sheet.dart';

class FindStorePage extends StatefulWidget {
  const FindStorePage({super.key});

  @override
  State<FindStorePage> createState() => _FindStorePageState();
}

class _FindStorePageState extends State<FindStorePage> {
  final MapController _mapController = MapController();

  void _onStoreTapped(Store store) {
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
        backgroundColor: const Color(0xFF1E4620),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Consumer<StoreController>(
        builder: (context, controller, _) {
          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(controller.selectedStore?.latitude ?? 5.4206, 
                                controller.selectedStore?.longitude ?? 100.3429),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.nuburn.nutritionapp.mealshop.v4',
              ),
              MarkerLayer(
                markers: controller.stores.map((store) {
                  return Marker(
                    point: LatLng(store.latitude, store.longitude),
                    width: 65,
                    height: 65,
                    child: GestureDetector(
                      onTap: () => _onStoreTapped(store),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // White background circle for the pin
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                              border: Border.all(color: const Color(0xFFABC270), width: 2),
                            ),
                          ),
                          // App Logo
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Image.asset(
                              store.logoUrl,
                              errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.location_on, color: Color(0xFFBF5D32)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
