import 'package:flutter/material.dart';

class PremiumSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final List<String> options;
  final List<IconData> icons;
  final Function(int) onValueChanged;

  const PremiumSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.options,
    required this.icons,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E2D9),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double itemWidth = (constraints.maxWidth - 8) / options.length;
          
          return Stack(
            children: [
              // Animated Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Labels and Tap Targets
              Row(
                children: List.generate(options.length, (index) {
                  bool isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onValueChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icons[index],
                              size: 22,
                              color: isSelected ? Colors.black : const Color(0xFF5C5C5C),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              options[index],
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                color: isSelected ? Colors.black : const Color(0xFF5C5C5C),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // Divider
              if (options.length == 2)
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 1,
                      height: 18,
                      color: const Color(0xFFC4C1B6),
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
