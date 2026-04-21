import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../model/meal_model.dart';
import '../widgets/meal_confirmation_dialog.dart';
import '../../service/meal_service.dart';

class AddMenuItemPage extends StatefulWidget {
  final Meal? initialMeal;
  final String storeId;
  const AddMenuItemPage({super.key, this.initialMeal, required this.storeId});

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
  final Map<String, bool> _categorySelections = {};
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

  // Image State
  String? _currentImageUrl;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    for (var cat in _categories) {
      _categorySelections[cat] = false;
    }

    if (widget.initialMeal != null) {
      final meal = widget.initialMeal!;
      _nameController.text = meal.name;
      
      // Update with existing category data
      for (var cat in _categories) {
        _categorySelections[cat] = meal.categories.contains(cat);
      }
      
      _descriptionController.text = meal.description;
      _priceController.text = meal.price.toStringAsFixed(2);
      _servingSizeController.text = meal.servingSize;
      
      _caloriesController.text = meal.calories.toStringAsFixed(0);
      _proteinController.text = meal.protein.toStringAsFixed(1);
      _carbsController.text = meal.carbs.toStringAsFixed(1);
      _fatController.text = meal.fat.toStringAsFixed(1);
      _fiberController.text = meal.fiber.toStringAsFixed(1);
      _sugarController.text = meal.sugar.toStringAsFixed(1);
      _sodiumController.text = meal.sodium.toStringAsFixed(0);
      _cholesterolController.text = meal.cholesterol.toStringAsFixed(0);

      // Populate dietary state
      for (var pref in meal.dietaryPreferences) {
        if (_dietaryRestrictions.containsKey(pref)) {
          _dietaryRestrictions[pref] = true;
        }
      }
      // Populate allergens
      for (var allergen in meal.allergens) {
        if (_allergens.containsKey(allergen)) {
          _allergens[allergen] = true;
        }
      }

      _remarksController.text = meal.remarks;
      _currentImageUrl = meal.imageUrl;
    }
  }

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
    final price = double.tryParse(_priceController.text);
    return _nameController.text.isNotEmpty &&
           _categorySelections.values.contains(true) &&
           price != null && price > 0;
  }

  bool get _isStep2Valid {
    final calories = double.tryParse(_caloriesController.text);
    return _caloriesController.text.isNotEmpty && calories != null && calories >= 0;
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add a photo',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Select from Gallery (or Library)'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('Choose from Files'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery); // On mobile, Gallery usually covers files too
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveMeal() async {
    // small loading indicator
    if (_imageFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...'), duration: Duration(seconds: 2)),
      );
    }

    String finalImageUrl = _currentImageUrl ?? '';
    
    try {
      final meal = Meal(
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        imageUrl: finalImageUrl,
        categories: _categorySelections.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
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
        isAvailable: widget.initialMeal?.isAvailable ?? true,
        storeId: widget.storeId,
      );

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => MealConfirmationDialog(meal: meal, localImage: _imageFile),
      );

      if (!context.mounted) return;

      if (confirmed == true) {
        // if a new image was picked, upload it now
        if (_imageFile != null) {
          finalImageUrl = await MealService.uploadImage(_imageFile!);
        }

        Meal savedMeal;
        if (widget.initialMeal != null) {
          savedMeal = await MealService.updateMeal(meal.copyWith(
            id: widget.initialMeal!.id,
            imageUrl: finalImageUrl,
          ));
        } else {
          savedMeal = await MealService.addMeal(meal.copyWith(imageUrl: finalImageUrl));
        }
        
        if (mounted) Navigator.pop(context, savedMeal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<bool> _showDiscardDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.center,
        title: const Text('Discard Changes?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Are you sure you want to discard your changes?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD25432),
                    side: const BorderSide(color: Color(0xFFD25432)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const FittedBox(
                    child: Text('Keep Editing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD25432),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const FittedBox(
                    child: Text('Discard', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (!context.mounted) return;
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          title: Text(widget.initialMeal != null ? 'Edit Item' : 'Add New Item', style: const TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _showDiscardDialog();
              if (!context.mounted) return;
              if (shouldPop) {
                Navigator.pop(context);
              }
            },
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
      ),
    );
  }

  // Basic Information
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
          _buildLabel('Categories *'),
          _buildCheckboxGrid(_categorySelections),
          const SizedBox(height: 16),
          _buildLabel('Description'),
          _buildTextField(_descriptionController, 'Describe your menu item...', maxLines: 3),
          const SizedBox(height: 16),
          _buildLabel('Price (RM) *'),
          _buildTextField(
            _priceController, 
            '12.99', 
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          ),
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

  // Nutrition Information
  Widget _buildStep2Nutrition() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.monitor_heart_outlined, 'Nutrition Information'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildNutritionField(_caloriesController, 'Calories (cal) *', '450', isInteger: true)),
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
              Expanded(child: _buildNutritionField(_sodiumController, 'Sodium (mg)', '480', isInteger: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildNutritionField(_cholesterolController, 'Cholesterol (mg)', '370', isInteger: true)),
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
                  onPressed: _isStep2Valid ? _nextStep : null,
                  label: 'Next : Dietary Information',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dietary Information
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
                    onPressed: (_isStep1Valid && _isStep2Valid) ? _saveMeal : null,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Menu Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _lightGreen,
                      disabledBackgroundColor: _lightGreen.withValues(alpha: 0.5),
                      foregroundColor: _green,
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

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, {
    int maxLines = 1, 
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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

  Widget _buildNutritionField(TextEditingController controller, String label, String hint, {bool isInteger = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        _buildTextField(
          controller, 
          hint, 
          keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
          inputFormatters: [
            isInteger 
                ? FilteringTextInputFormatter.digitsOnly 
                : FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
      ],
    );
  }


  Widget _buildPhotoPlaceholder() {
    if (_imageFile != null || _currentImageUrl != null) {
      return GestureDetector(
        onTap: _showImageSourceActionSheet,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 130,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: _imageFile != null 
                      ? FileImage(_imageFile!) as ImageProvider
                      : (_currentImageUrl!.startsWith('http')
                          ? NetworkImage(_currentImageUrl!) as ImageProvider
                          : AssetImage(_currentImageUrl!) as ImageProvider),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              width: 130,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
            const Icon(Icons.edit_note, color: Colors.white, size: 36),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _showImageSourceActionSheet,
      child: Container(
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
          foregroundColor: _green,
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
