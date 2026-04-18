import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/bowl_controller.dart';
import '../../controller/cart_controller.dart';
import '../../controller/store_controller.dart';
import '../../model/cart_item.dart';
import '../../model/ingredient_model.dart';

class BuildYourBowlPage extends StatefulWidget {
  const BuildYourBowlPage({super.key});

  @override
  State<BuildYourBowlPage> createState() => _BuildYourBowlPageState();
}

class _BuildYourBowlPageState extends State<BuildYourBowlPage> {
  @override
  void initState() {
    super.initState();
    // Load ingredients from Supabase when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = Provider.of<StoreController>(context, listen: false).selectedStore?.id ?? '2';
      Provider.of<BowlController>(context, listen: false).loadIngredients(storeId);
    });
  }

  void _showExitConfirmationDialog(BuildContext context, BowlController bowl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Item?',
          style: TextStyle(color: Color(0xFF1E4620), fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure to delete your custom bowl?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              bowl.reset();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to menu
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF5D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BowlController>(
      builder: (context, bowl, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F0),
          appBar: AppBar(
            title: const Text('Build Your Bowl', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1E4620),
            foregroundColor: Colors.white,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _showExitConfirmationDialog(context, bowl),
            ),
          ),
          body: bowl.isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E4620)))
            : bowl.error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${bowl.error}'),
                    ElevatedButton(
                      onPressed: () {
                        final storeId = Provider.of<StoreController>(context, listen: false).selectedStore?.id ?? '2';
                        bowl.loadIngredients(storeId);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ))
              : Column(
                  children: [
              const _ProgressBar(),
              const _StepLabels(),
              
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        bowl.stepTitles[bowl.currentStep],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E4620),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStepInstruction(bowl.currentStep),
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildStepContent(bowl),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _BottomSummary(),
            ],
          ),
        );
      },
    );
  }
  String _getStepInstruction(int step) {
    switch (step) {
      case 0: return 'Pick one base for your bowl';
      case 1: return 'Select one or more proteins for your bowl';
      case 2: return 'Select one or more veggies for your bowl';
      case 3: return 'Select one or more sauces for your bowl';
      default: return '';
    }
  }

  Widget _buildStepContent(BowlController bowl) {
    switch (bowl.currentStep) {
      case 0:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: bowl.bases.length,
          itemBuilder: (context, index) => _IngredientCard(
            ingredient: bowl.bases[index],
            isSelected: bowl.selectedBase == bowl.bases[index],
            onTap: () => bowl.selectBase(bowl.bases[index]),
          ),
        );
      case 1:
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bowl.proteins.length,
          itemBuilder: (context, index) {
            final ingredient = bowl.proteins[index];
            final qty = bowl.getIngredientQuantity(ingredient);
            return _ProteinTile(
              ingredient: ingredient,
              quantity: qty,
              onIncrement: () => bowl.updateQuantity(ingredient, 1),
              onDecrement: () => bowl.updateQuantity(ingredient, -1),
            );
          },
        );
      case 2:
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bowl.veggiesList.length,
          itemBuilder: (context, index) {
            final ingredient = bowl.veggiesList[index];
            final qty = bowl.getIngredientQuantity(ingredient);
            return _ProteinTile(
              ingredient: ingredient,
              quantity: qty,
              onIncrement: () => bowl.updateQuantity(ingredient, 1),
              onDecrement: () => bowl.updateQuantity(ingredient, -1),
            );
          },
        );
      case 3:
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bowl.sauces.length,
          itemBuilder: (context, index) {
            final ingredient = bowl.sauces[index];
            return _SimpleTile(
              ingredient: ingredient,
              isSelected: bowl.selectedSauce == ingredient,
              onTap: () => bowl.selectSauce(ingredient),
            );
          },
        );
      default:
        return const Center(child: Text('Coming Soon...'));
    }
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    final bowl = Provider.of<BowlController>(context);
    final progress = (bowl.currentStep + 1) / bowl.steps.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${bowl.currentStep + 1} of ${bowl.steps.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                bowl.stepTitles[bowl.currentStep],
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLabels extends StatelessWidget {
  const _StepLabels();

  @override
  Widget build(BuildContext context) {
    final bowl = Provider.of<BowlController>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(bowl.steps.length, (index) {
          final isActive = bowl.currentStep == index;
          final isPast = bowl.currentStep > index;
          return Text(
            bowl.steps[index],
            style: TextStyle(
              color: isActive || isPast ? const Color(0xFF1E4620) : Colors.grey[400],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          );
        }),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final bool isSelected;
  final VoidCallback onTap;

  const _IngredientCard({
    required this.ingredient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSoldOut = !ingredient.isAvailable;

    return IgnorePointer(
      ignoring: isSoldOut,
      child: Opacity(
        opacity: isSoldOut ? 0.6 : 1.0,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF1E4620) : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: ingredient.imageUrl.startsWith('http')
                          ? Image.network(
                              ingredient.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[100],
                                child: const Icon(Icons.rice_bowl, color: Colors.grey),
                              ),
                            )
                          : Image.asset(
                              ingredient.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[100],
                                child: const Icon(Icons.rice_bowl, color: Colors.grey),
                              ),
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ingredient.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('${ingredient.calories} cal', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              const SizedBox(width: 4),
                              _NutritionInfoIcon(ingredient: ingredient),
                              const Spacer(),
                              Text('RM ${ingredient.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSoldOut)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBF5D32),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SOLD OUT',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProteinTile extends StatelessWidget {
  final Ingredient ingredient;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ProteinTile({
    required this.ingredient,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = quantity > 0;
    final bool isSoldOut = !ingredient.isAvailable;
    
    return IgnorePointer(
      ignoring: isSoldOut,
      child: Opacity(
        opacity: isSoldOut ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E4620) : Colors.grey[200]!,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ingredient.imageUrl.startsWith('http')
                  ? Image.network(
                      ingredient.imageUrl,
                      width: 60,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    )
                  : Image.asset(
                      ingredient.imageUrl,
                      width: 60,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ingredient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(ingredient.description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${ingredient.calories} cal', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        _NutritionInfoIcon(ingredient: ingredient),
                        const Spacer(),
                        if (isSoldOut)
                          const Text('SOLD OUT', style: TextStyle(color: Color(0xFFBF5D32), fontWeight: FontWeight.bold, fontSize: 12))
                        else
                          Text('RM ${ingredient.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              if (!isSoldOut) ...[
                if (!isSelected)
                  GestureDetector(
                    onTap: onIncrement,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: const Icon(Icons.add, size: 20, color: Colors.grey),
                    ),
                  )
                else
                  Row(
                    children: [
                      _QtyBtn(icon: Icons.remove, onTap: onDecrement),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      _QtyBtn(icon: Icons.add, onTap: onIncrement),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1E4620)),
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  final Ingredient ingredient;
  final bool isSelected;
  final VoidCallback onTap;

  const _SimpleTile({
    required this.ingredient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSoldOut = !ingredient.isAvailable;

    return IgnorePointer(
      ignoring: isSoldOut,
      child: Opacity(
        opacity: isSoldOut ? 0.6 : 1.0,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF1E4620) : Colors.grey[200]!,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ingredient.imageUrl.startsWith('http')
                    ? Image.network(
                        ingredient.imageUrl,
                        width: 60,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )
                    : Image.asset(
                        ingredient.imageUrl,
                        width: 60,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ingredient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(ingredient.description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${ingredient.calories} cal', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          _NutritionInfoIcon(ingredient: ingredient),
                          const Spacer(),
                          if (isSoldOut)
                            const Text('SOLD OUT', style: TextStyle(color: Color(0xFFBF5D32), fontWeight: FontWeight.bold, fontSize: 12))
                          else
                            Text('RM ${ingredient.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isSoldOut)
                  const SizedBox(width: 24)
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                      color: isSelected ? const Color(0xFF1E4620) : Colors.transparent,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionInfoIcon extends StatelessWidget {
  final Ingredient ingredient;
  const _NutritionInfoIcon({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNutritionTooltip(context),
      child: const Icon(Icons.info_outline, size: 14, color: Color(0xFFABC270)),
    );
  }

  void _showNutritionTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFABC270)),
            const SizedBox(width: 8),
            Text(ingredient.name, style: const TextStyle(color: Color(0xFF1E4620))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nutritional Information:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...ingredient.nutritionData.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: TextStyle(color: Colors.grey[600])),
                  Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _BottomSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bowl = Provider.of<BowlController>(context);
    final showButtons = bowl.currentStep != 0 || bowl.selectedBase != null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showButtons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  if (bowl.currentStep > 0)
                    OutlinedButton(
                      onPressed: () => bowl.previousStep(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBF5D32),
                        side: const BorderSide(color: Color(0xFFBF5D32), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Back: ${bowl.steps[bowl.currentStep - 1]}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Next Button
                  ElevatedButton(
                    onPressed: bowl.canGoNext ? () {
                      if (bowl.currentStep == bowl.steps.length - 1) {
                        _showCustomDetailsDialog(context, bowl);
                      } else {
                        bowl.nextStep();
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bowl.canGoNext 
                          ? const Color(0xFFABC270) 
                          : const Color(0xFFD9D9D9), 
                      foregroundColor: bowl.canGoNext ? const Color(0xFF1E4620) : Colors.white,
                      disabledBackgroundColor: const Color(0xFFD9D9D9),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: bowl.canGoNext ? 2 : 0,
                    ),
                    child: Text(
                      bowl.currentStep == bowl.steps.length - 1 ? 'Add to Cart' : 'Next: ${bowl.steps[bowl.currentStep + 1]}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16, 
                        color: bowl.canGoNext ? const Color(0xFF1E4620) : Colors.black26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const Divider(height: 1),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_fire_department, color: Color(0xFF4CAF50), size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Calorie',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${bowl.totalCalories}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('calories', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.payments, color: Color(0xFF1976D2), size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      'RM ${bowl.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E4620),
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

  void _showCustomDetailsDialog(BuildContext context, BowlController bowl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Custom Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E4620))),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Color(0xFFBF5D32)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFF5F5F0),
                    child: const Icon(Icons.rice_bowl, size: 60, color: Color(0xFF1E4620)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Your Custom Bowl', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _SummaryItem(title: 'Base', items: [bowl.selectedBase?.name ?? 'None']),
              _SummaryItem(
                title: 'Protein', 
                items: bowl.selectedProteins.entries.map((e) => '${e.key.name} x${e.value}').toList()
              ),
              _SummaryItem(
                title: 'Veggies', 
                items: bowl.selectedVeggies.entries.map((e) => '${e.key.name} x${e.value}').toList()
              ),
              _SummaryItem(title: 'Sauce', items: [bowl.selectedSauce?.name ?? 'No sauce']),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Total Calories', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBF5D32))),
                      const SizedBox(width: 4),
                      _NutritionTotalsInfo(bowl: bowl),
                    ],
                  ),
                  Text('${bowl.totalCalories} cal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFBF5D32))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('RM ${bowl.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1E4620))),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final cart = Provider.of<CartController>(context, listen: false);
                    List<String> details = [];
                    details.add('Base: ${bowl.selectedBase!.name}');
                    bowl.selectedProteins.forEach((k, v) => details.add('${k.name} x$v'));
                    bowl.selectedVeggies.forEach((k, v) => details.add('${k.name} x$v'));
                    if (bowl.selectedSauce != null) details.add('Sauce: ${bowl.selectedSauce!.name}');

                    cart.addItem(CartItem(
                      name: 'Custom Bowl',
                      price: bowl.totalPrice,
                      addOns: details,
                      quantity: 1,
                    ));
                    bowl.reset();
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to menu
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Custom Bowl added to cart!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFABC270),
                    foregroundColor: const Color(0xFF1E4620),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionTotalsInfo extends StatelessWidget {
  final BowlController bowl;
  const _NutritionTotalsInfo({required this.bowl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final totals = bowl.totalNutrition;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nutritional Info',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E4620)),
                ),
                const SizedBox(height: 16),
                _NutrientRow(label: 'Protein', value: '${totals['Protein']} g'),
                _NutrientRow(label: 'Carbs', value: '${totals['Carbs']} g'),
                _NutrientRow(label: 'Fat', value: '${totals['Fats']} g'),
                _NutrientRow(label: 'Fiber', value: '${totals['Fiber']} g'),
              ],
            ),
          ),
        );
      },
      child: const Icon(Icons.info_outline, size: 18, color: Color(0xFFABC270)),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final String value;
  const _NutrientRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label :', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final List<String> items;
  const _SummaryItem({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, size: 6, color: Colors.grey),
                const SizedBox(width: 6),
                Text(item, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

Widget _buildPlaceholder() {
  return Container(
    width: 60,
    height: 40,
    color: Colors.grey[100],
    child: const Icon(Icons.restaurant, color: Colors.grey),
  );
}
