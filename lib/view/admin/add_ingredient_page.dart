import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../model/ingredient_model.dart';
import '../../service/ingredient_service.dart';

class AddIngredientPage extends StatefulWidget {
  final Ingredient? initialIngredient;
  final String storeId;
  const AddIngredientPage({super.key, this.initialIngredient, required this.storeId});

  @override
  State<AddIngredientPage> createState() => _AddIngredientPageState();
}

class _AddIngredientPageState extends State<AddIngredientPage> {
  static const _green      = Color(0xFF1E4620);
  static const _lightGreen = Color(0xFFB5CC30);
  static const _bgColor    = Color(0xFFF9F9F4);

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Macros
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();

  IngredientType _selectedType = IngredientType.veggies;
  
  String? _currentImageUrl;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIngredient != null) {
      final ing = widget.initialIngredient!;
      _nameController.text = ing.name;
      _priceController.text = ing.price.toStringAsFixed(2);
      _caloriesController.text = ing.calories.toString();
      _descriptionController.text = ing.description;
      _proteinController.text = ing.protein.toStringAsFixed(1);
      _carbsController.text = ing.carbs.toStringAsFixed(1);
      _fatController.text = ing.fat.toStringAsFixed(1);
      _fiberController.text = ing.fiber.toStringAsFixed(1);
      _selectedType = ing.type;
      _currentImageUrl = ing.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _caloriesController.dispose();
    _descriptionController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
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
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showDiscardDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.center,
        title: const Text('Discard Changes?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Are you sure you want to discard your changes?'),
        actions: [
          SizedBox(
            width: 130,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD25432),
                side: const BorderSide(color: Color(0xFFD25432)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Keep Editing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD25432),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  bool get _isValid {
    return _nameController.text.isNotEmpty &&
           _priceController.text.isNotEmpty &&
           _caloriesController.text.isNotEmpty;
  }

  void _save() async {
    if (!_isValid) return;

    setState(() => _isSaving = true);
    
    try {
      String imageUrl = _currentImageUrl ?? '';
      if (_imageFile != null) {
        imageUrl = await IngredientService.uploadImage(_imageFile!);
      }

      final ingredient = Ingredient(
        id: widget.initialIngredient?.id,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        calories: int.tryParse(_caloriesController.text) ?? 0,
        description: _descriptionController.text,
        type: _selectedType,
        protein: double.tryParse(_proteinController.text) ?? 0.0,
        carbs: double.tryParse(_carbsController.text) ?? 0.0,
        fat: double.tryParse(_fatController.text) ?? 0.0,
        fiber: double.tryParse(_fiberController.text) ?? 0.0,
        imageUrl: imageUrl,
        isAvailable: widget.initialIngredient?.isAvailable ?? true,
        storeId: widget.storeId,
      );

      Ingredient saved;
      if (widget.initialIngredient != null) {
        saved = await IngredientService.updateIngredient(ingredient);
      } else {
        saved = await IngredientService.addIngredient(ingredient);
      }

      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          title: Text(widget.initialIngredient != null ? 'Edit Ingredient' : 'Add Ingredient', 
            style: const TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _showDiscardDialog();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.info_outline, 'Basic Info'),
            const SizedBox(height: 20),
            _buildLabel('Ingredient Name *'),
            _buildTextField(_nameController, 'e.g., Grilled Salmon'),
            const SizedBox(height: 16),
            _buildLabel('Category *'),
            _buildTypeDropdown(),
            const SizedBox(height: 16),
            _buildLabel('Price (RM) *'),
            _buildTextField(_priceController, '4.50', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildLabel('Description'),
            _buildTextField(_descriptionController, 'Describe this ingredient...', maxLines: 3),
            const SizedBox(height: 20),
            _buildSectionHeader(Icons.monitor_heart_outlined, 'Nutrition (per serving)'),
            const SizedBox(height: 20),
            _buildLabel('Calories (cal) *'),
            _buildTextField(_caloriesController, '150', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildNutritionInput(_proteinController, 'Protein (g)')),
                const SizedBox(width: 12),
                Expanded(child: _buildNutritionInput(_carbsController, 'Carbs (g)')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildNutritionInput(_fatController, 'Fat (g)')),
                const SizedBox(width: 12),
                Expanded(child: _buildNutritionInput(_fiberController, 'Fiber (g)')),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(Icons.image_outlined, 'Display'),
            const SizedBox(height: 16),
            _buildLabel('Add Photo'),
            _buildPhotoPicker(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_isSaving || !_isValid) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lightGreen,
                  disabledBackgroundColor: _lightGreen.withOpacity(0.5),
                  foregroundColor: _green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: _green)
                  : Text(widget.initialIngredient != null ? 'Update ingredient' : 'Save ingredient', 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _green, size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2C2C2C))),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF5C5C5C))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFC0C0C0), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _lightGreen, width: 2)),
      ),
    );
  }

  Widget _buildNutritionInput(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        _buildTextField(controller, '0.0', keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<IngredientType>(
          isExpanded: true,
          value: _selectedType,
          items: IngredientType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_capitalize(type.name), style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedType = val!),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _showImageSourceActionSheet,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _imageFile != null 
          ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, fit: BoxFit.cover))
          : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(_currentImageUrl!, fit: BoxFit.cover))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.black, size: 36),
                  const SizedBox(height: 8),
                  Text('Add a photo', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
      ),
    );
  }
}
