import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/store_controller.dart';
import '../pages/find_store_page.dart';

class StoreLocationHeader extends StatelessWidget {
  const StoreLocationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreController>(
      builder: (context, storeController, _) {
        final selectedStore = storeController.selectedStore;
        
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFABC270).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFABC270), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ordering From Store',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            selectedStore?.name ?? 'Select a Store',
                            style: const TextStyle(
                              fontSize: 15, 
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E4620),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selectedStore != null && !selectedStore.isOpen)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: const Text(
                              'Closed',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FindStorePage()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: const Color(0xFFF1F8E9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: Color(0xFF1E4620), 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
