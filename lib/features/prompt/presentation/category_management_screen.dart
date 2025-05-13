import 'package:flutter/material.dart';
import 'package:ai_chat_bot/core/constants/app_colors.dart';
import 'package:ai_chat_bot/core/constants/category_constants.dart';
import '../services/prompt_service.dart';
import '../../../widgets/information.dart';
import '../../../widgets/button.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final PromptService _promptService = PromptService();
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _fetchCategoryData();
  }
  
  Future<void> _fetchCategoryData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // This will just get the categories, we'll use our constants for now
      await _promptService.getPromptCategories();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchCategoryData,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? InformationIndicator(
              message: 'Loading categories...',
              variant: InformationVariant.loading,
            )
          : _errorMessage.isNotEmpty
              ? InformationIndicator(
                  message: 'Error: $_errorMessage',
                  variant: InformationVariant.error,
                  onButtonPressed: _fetchCategoryData,
                  buttonText: 'Retry',
                )
              : Column(
                  children: [
                    // Category list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: CategoryConstants.categories.length,
                        itemBuilder: (context, index) {
                          final category = CategoryConstants.categories[index];
                          return _buildCategoryCard(category, isDarkMode, colors);
                        },
                      ),
                    ),
                    
                    // Note at bottom explaining category usage
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Categories',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Categories help you organize your prompts. Each prompt is assigned to one category.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The available categories are pre-defined in the app to ensure consistency.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildCategoryCard(String category, bool isDarkMode, AppColors colors) {
    final categoryColor = CategoryConstants.getCategoryColor(
      category, 
      darkMode: isDarkMode,
    );
    final categoryIcon = CategoryConstants.getCategoryIcon(category);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: categoryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              categoryIcon,
              size: 24,
              color: categoryColor,
            ),
          ),
        ),
        title: Text(
          category.substring(0, 1).toUpperCase() + category.substring(1),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Used for ${category.toLowerCase()} related prompts',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              label: 'Browse',
              variant: ButtonVariant.ghost,
              isDarkMode: isDarkMode,
              size: ButtonSize.small,
              onPressed: () => _browseCategory(category),
              fullWidth: false,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _browseCategory(String category) async {
    Navigator.of(context).pop(category);
  }
} 