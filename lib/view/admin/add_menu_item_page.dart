import 'package:flutter/material.dart';
import '../../model/meal_model.dart';

class AddMenuItemPage extends StatefulWidget {
  const AddMenuItemPage({super.key});

  @override
  State<AddMenuItemPage> createState() => _AddMenuItemPageState();
}

class _AddMenuItemPageState extends State<AddMenuItemPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  static const _green      = Color(0xFF1E4620);
  static const _lightGreen = Color(0xFFB5CC30);
  static const _bgColor    = Color(0xFFF9F9F4); // Creamy background

  // Form State
  final _nameController = TextEditingController();
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _servingSizeController = TextEditingController();
  
  // Nutrition State
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sugarController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _cholesterolController = TextEditingController();

  // Dietary State
  final Map<String, bool> _dietaryRestrictions = {
    'Halal': false,
    'Vegan': false,
    'Vegetarian': false,
    'Non-vegetarian': false,
  };
  final Map<String, bool> _allergens = {
    'Contains Nuts': false,
    'Contains Egg': false,
    'Contains Dairy': false,
    'Contains Shellfish': false,
  };
  final _remarksController = TextEditingController();

  final List<String> _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Pre-workout',
    'Post-workout',
    'Snacks'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _servingSizeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    _cholesterolController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  bool get _isStep1Valid {
    return _nameController.text.isNotEmpty &&
           _selectedCategory != null &&
           _priceController.text.isNotEmpty;
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveMeal() {
    final meal = Meal(
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=1000&auto=format&fit=crop', // Default placeholder
      categories: [_selectedCategory ?? 'Other'],
      dietaryPreferences: _dietaryRestrictions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      servingSize: _servingSizeController.text,
      calories: double.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      fiber: double.tryParse(_fiberController.text) ?? 0,
      sugar: double.tryParse(_sugarController.text) ?? 0,
      sodium: double.tryParse(_sodiumController.text) ?? 0,
      cholesterol: double.tryParse(_cholesterolController.text) ?? 0,
      allergens: _allergens.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      remarks: _remarksController.text,
    );

    Navigator.pop(context, meal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text('Add New Item', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentStep = index),
        children: [
          _buildStep1BasicInfo(),
          _buildStep2Nutrition(),
          _buildStep3Dietary(),
        ],
      ),
    );
  }

  // ── Step 1: Basic Information ──────────────────────────────────────────────

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, 'Basic Information'),
          const SizedBox(height: 20),
          _buildLabel('Item Name *'),
          _buildTextField(_nameController, 'e.g., Quinoa Power Bowl'),
          const SizedBox(height: 16),
          _buildLabel('Category *'),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          _buildLabel('Description'),
          _buildTextField(_descriptionController, 'Describe your menu item...', maxLines: 3),
          const SizedBox(height: 16),
          _buildLabel('Price (RM) *'),
          _buildTextField(_priceController, '12.99', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildLabel('Serving Size'),
          _buildTextField(_servingSizeController, '1 bowl (350g)'),
          const SizedBox(height: 20),
          _buildLabel('Add Photo'),
          _buildPhotoPlaceholder(),
          const SizedBox(height: 40),
          _buildBottomButton(
            onPressed: _isStep1Valid ? _nextStep : null,
            label: 'Next : Nutrition Information',
          ),
        ],
      ),
    );
  }

  // ── Step 2: Nutrition Information ──────────────────────────────────────────

  Widget _buildStep2Nutrition() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.favorite_outline, 'Nutrition Information'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildNutritionField(_caloriesController, 'Calories (cal) *', '450')),
              const SizedBox(width: 16),
              Expanded(child: _buildNutritionField(_proteinController, 'Protein (g)', '25.5')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildNutritionField(_carbsController, 'Carbs (g)', '45.2')),
              const SizedBox(width: 16),
              Expanded(child: _buildNutritionField(_fatController, 'Fat (g)', '12.8')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildNutritionField(_fiberController, 'Fiber (g)', '8.5')),
              const SizedBox(width: 16),
              Expanded(child: _buildNutritionField(_sugarController, 'Sugar (g)', '6.2')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildNutritionField(_sodiumController, 'Sodium (mg)', '480')),
              const SizedBox(width: 16),
              Expanded(child: _buildNutritionField(_cholesterolController, 'Cholesterol (mg)', '0')),
            ],
          ),
          const SizedBox(height: 100),
          Row(
            children: [
              Expanded(child: _buildBackButton()),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildBottomButton(
                  onPressed: _nextStep,
                  label: 'Next : Dietary Information',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 3: Dietary Information ────────────────────────────────────────────

  Widget _buildStep3Dietary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.eco_outlined, 'Dietary Information'),
          const SizedBox(height: 20),
          _buildLabel('Dietary Restrictions'),
          _buildCheckboxGrid(_dietaryRestrictions),
          const SizedBox(height: 24),
          _buildLabel('Allergen Information'),
          _buildCheckboxGrid(_allergens),
          const SizedBox(height: 24),
          _buildLabel('Additional Information'),
          _buildTextField(_remarksController, 'Remarks...', maxLines: 4),
          const SizedBox(height: 60),
          Row(
            children: [
              Expanded(child: _buildBackButton()),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _saveMeal,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Menu Item', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _lightGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Common UI Components ───────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _green, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5C5C5C),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFC0C0C0), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildNutritionField(TextEditingController controller, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        _buildTextField(controller, hint, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select Category', style: TextStyle(color: Color(0xFFC0C0C0), fontSize: 14)),
          value: _selectedCategory,
          items: _categories.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(cat, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, color: Colors.black, size: 28),
          const SizedBox(height: 4),
          const Text('Add a photo', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCheckboxGrid(Map<String, bool> data) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        String key = data.keys.elementAt(index);
        return Row(
          children: [
            Checkbox(
              value: data[key],
              activeColor: _lightGreen,
              onChanged: (val) => setState(() => data[key] = val!),
            ),
            Text(key, style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2C))),
          ],
        );
      },
    );
  }

  Widget _buildBottomButton({required VoidCallback? onPressed, required String label}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightGreen,
          disabledBackgroundColor: _lightGreen.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _prevStep,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Back'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _green,
          side: const BorderSide(color: Color(0xFFDDDCD0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
