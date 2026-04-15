import 'package:flutter/material.dart';

class AdminMenuManagementPage extends StatefulWidget {
  const AdminMenuManagementPage({super.key});

  @override
  State<AdminMenuManagementPage> createState() =>
      _AdminMenuManagementPageState();
}

class _AdminMenuManagementPageState extends State<AdminMenuManagementPage> {
  static const _green      = Color(0xFF1E4620);
  static const _lightGreen = Color(0xFFB5CC30);
  static const _terracotta = Color(0xFFD95F2B);

  // Placeholder menu items
  final List<_MenuItem> _items = [
    _MenuItem(
      name:        'Grilled Salmon Bowl',
      description: 'Fresh grilled salmon with quinoa, roasted vegetables, and lemon herb dressing. High in protein and omega-3.',
      price:       35.00,
      tags:        ['High Protein', 'Omega-3', 'Gluten-Free'],
    ),
    _MenuItem(
      name:        'Caesar Salad with Chicken Bites',
      description: 'Crispy romaine lettuce with grilled chicken, parmesan, and house caesar dressing.',
      price:       32.80,
      tags:        ['High Protein', 'Low Carb'],
    ),
    _MenuItem(
      name:        'Custom Meal Bowl',
      description: 'Build your own bowl with your choice of base, protein, and toppings.',
      price:       32.80,
      tags:        ['Customizable'],
    ),
    _MenuItem(
      name:        'Avocado Veggie Wrap',
      description: 'Whole wheat wrap with fresh avocado, mixed greens, cherry tomatoes and hummus.',
      price:       28.00,
      tags:        ['Vegan', 'High Fibre'],
    ),
  ];

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove "${_items[index].name}" from the menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B6B6B))),
          ),
          TextButton(
            onPressed: () {
              setState(() => _items.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editItem(int index) {
    // TODO: open edit form
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit "${_items[index].name}" — coming soon'),
        backgroundColor: _green,
      ),
    );
  }

  void _addItem() {
    // TODO: open add form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new item — coming soon'),
        backgroundColor: Color(0xFF1E4620),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menu Items',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const Text(
                'Manage your restaurant menu items',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
              ),
              const SizedBox(height: 14),

              // ── Add button ──
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Add New Item',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lightGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),

        // ── Item list ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            itemBuilder: (context, index) => _MenuItemCard(
              item:     _items[index],
              onDelete: () => _deleteItem(index),
              onEdit:   () => _editItem(index),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Menu Item Card ─────────────────────────────────────────────────────────────

class _MenuItemCard extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  static const _terracotta = Color(0xFFD95F2B);
  static const _lightGreen = Color(0xFFB5CC30);
  static const _green      = Color(0xFF1E4620);

  const _MenuItemCard({
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEBDE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Placeholder image ──
          Container(
            height: 160,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D5C5),
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Center(
              child: Icon(Icons.fastfood_outlined,
                  color: Color(0xFF9E9880), size: 48),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name + price ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    ),
                    Text(
                      'RM ${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1E4620),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Description ──
                Text(
                  item.description,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                      height: 1.4),
                ),
                const SizedBox(height: 10),

                // ── Tags ──
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.tags
                      .map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(tag,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _green)),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 12),

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Colors.red),
                        label: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            size: 16),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lightGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String name;
  final String description;
  final double price;
  final List<String> tags;

  const _MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.tags,
  });
}