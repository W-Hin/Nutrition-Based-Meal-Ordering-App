import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/build_bowl_page.dart';
import '../../controller/store_controller.dart';

class CustomBowlCard extends StatelessWidget {
  const CustomBowlCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Bowl',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E4620),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mix and Match your favorite ingredients',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Consumer<StoreController>(
              builder: (context, storeCtrl, _) {
                final isClosed = !(storeCtrl.selectedStore?.isOpen ?? true);

                return ElevatedButton(
                  onPressed: isClosed ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BuildYourBowlPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClosed ? Colors.grey[300] : const Color(0xFFABC270),
                    foregroundColor: isClosed ? Colors.grey[600] : const Color(0xFF1E4620),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isClosed ? Icons.lock_outline : Icons.add, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isClosed ? 'Store Closed' : 'Build Your Bowl',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
