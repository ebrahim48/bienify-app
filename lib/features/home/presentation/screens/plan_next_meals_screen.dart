import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/home_controller.dart';

class PlanNextMealsScreen extends StatefulWidget {
  const PlanNextMealsScreen({super.key});

  @override
  State<PlanNextMealsScreen> createState() => _PlanNextMealsScreenState();
}

class _PlanNextMealsScreenState extends State<PlanNextMealsScreen> {
  int _adults = 0;
  int _children = 0;
  double _budget = 115;
  int _breakfast = 0;
  int _lunch = 3;
  int _dinner = 5;
  String _selectedDiet = 'Vegetarian';
  final List<String> _selectedCuisines = ['Italian', 'Asian', 'Mediterranean'];

  static const List<String> _diets = [
    'Vegetarian', 'Vegan', 'Halal', 'Kosher',
    'Dairy-free', 'Nut-free', 'Pescatarian', 'High protein', 'Gluten-free',
  ];

  static const List<String> _cuisines = [
    'Italian', 'Mexican', 'Asian', 'American',
    'Mediterranean', 'Indian', 'Middle Eastern', 'British',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(children: [
          // App bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14, color: AppColors.primary),
                ),
              ),
              const Spacer(),
              Text('Plan your next meals',
                  style: AppTextStyles.sub2.copyWith(
                      color: AppColors.textSecondary)),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text("Let's plan your next meals", style: AppTextStyles.h4),
                const SizedBox(height: 6),
                Text(
                  "Tweak anything below — changes save to your preferences. Then we'll suggest meals to match.",
                  style: AppTextStyles.body3.copyWith(
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // People & budget card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _CounterRow(
                      label: 'Adults', value: _adults,
                      onDec: () { if (_adults > 0) setState(() => _adults--); },
                      onInc: () => setState(() => _adults++),
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _CounterRow(
                      label: 'Children', value: _children,
                      onDec: () { if (_children > 0) setState(() => _children--); },
                      onInc: () => setState(() => _children++),
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    Row(children: [
                      Text('Weekly budget', style: AppTextStyles.sub3),
                      const Spacer(),
                      Text('\$', style: AppTextStyles.sub2.copyWith(
                          color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      Text('${_budget.round()}', style: AppTextStyles.sub2),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // Meals per week
                Text('MEALS PER WEEK',
                    style: AppTextStyles.sub4.copyWith(
                        color: AppColors.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _CounterRow(
                      label: 'Breakfast', value: _breakfast,
                      onDec: () { if (_breakfast > 0) setState(() => _breakfast--); },
                      onInc: () => setState(() => _breakfast++),
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _CounterRow(
                      label: 'Lunch', value: _lunch,
                      onDec: () { if (_lunch > 0) setState(() => _lunch--); },
                      onInc: () => setState(() => _lunch++),
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _CounterRow(
                      label: 'Dinner', value: _dinner,
                      onDec: () { if (_dinner > 0) setState(() => _dinner--); },
                      onInc: () => setState(() => _dinner++),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Dietary
                Text('DIETARY',
                    style: AppTextStyles.sub4.copyWith(
                        color: AppColors.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Wrap(spacing: 8, runSpacing: 8,
                    children: _diets.map((d) {
                      final sel = _selectedDiet == d;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDiet = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: sel ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(d,
                              style: AppTextStyles.body3.copyWith(
                                color: sel ? AppColors.white : AppColors.primary,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Cuisines
                Text('CUISINES YOU LIKE',
                    style: AppTextStyles.sub4.copyWith(
                        color: AppColors.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Wrap(spacing: 8, runSpacing: 8,
                    children: _cuisines.map((c) {
                      final sel = _selectedCuisines.contains(c);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (sel) {
                            _selectedCuisines.remove(c);
                          } else {
                            _selectedCuisines.add(c);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: sel ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(c,
                              style: AppTextStyles.body3.copyWith(
                                color: sel ? AppColors.white : AppColors.primary,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: AppButton(
              label: 'Looks good — find me meals →',
              onPressed: () {
                Get.find<HomeController>().togglePlanView();
                Get.back();
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.onDec,
    required this.onInc,
  });
  final String label;
  final int value;
  final VoidCallback onDec, onInc;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: AppTextStyles.sub3),
      const Spacer(),
      GestureDetector(
        onTap: onDec,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.remove, size: 16,
              color: AppColors.textSecondary),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('$value', style: AppTextStyles.sub2),
      ),
      GestureDetector(
        onTap: onInc,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.add, size: 16,
              color: AppColors.textSecondary),
        ),
      ),
    ]);
  }
}
