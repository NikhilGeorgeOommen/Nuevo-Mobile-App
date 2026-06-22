import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/profile_image_picker_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_icons.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  DateTime? _selectedDate;
  File? _selectedImage;

  bool _isInitialized = false;
  String _initialName = '';
  String _initialDob = '';
  String _initialHeight = '';
  String _initialWeight = '';

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _dobController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    
    _nameController.addListener(_onFieldChanged);
    _dobController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    
    // Initialize with user data if available
    // In a real app, we'd listen to the provider. For now, we'll set defaults or wait for the provider build.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  bool get _hasChanges {
    if (!_isInitialized) return false;
    if (_nameController.text.trim() != _initialName.trim()) return true;
    if (_dobController.text.trim() != _initialDob.trim()) return true;
    if (_heightController.text.trim() != _initialHeight.trim()) return true;
    if (_weightController.text.trim() != _initialWeight.trim()) return true;
    if (_selectedImage != null) return true;
    return false;
  }
  


  void _handleImageSelection(File image) {
    setState(() {
      _selectedImage = image;
    });
    // TODO: Implement actual upload logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image selected for upload')),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileImagePickerSheet(
        onImageSelected: _handleImageSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    // Initialize controllers once with user data
    if (!_isInitialized && userState.hasValue && userState.value != null) {
      final user = userState.value!;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _initialName = user.name;
      // Populate DOB from user entity
      if (user.dateOfBirth != null) {
        final formattedDob = DateFormat('dd/MM/yyyy').format(user.dateOfBirth!);
        _dobController.text = formattedDob;
        _initialDob = formattedDob;
        _selectedDate = user.dateOfBirth;
      } else {
        _initialDob = '';
      }
      
      _heightController.text = user.height != null ? user.height.toString() : '';
      _initialHeight = _heightController.text;
      
      _weightController.text = user.weight != null ? user.weight.toString() : '';
      _initialWeight = _weightController.text;
      
      _isInitialized = true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              )
                            : (userState.value?.profileImageUrl != null && userState.value!.profileImageUrl!.isNotEmpty)
                                ? (userState.value!.profileImageUrl!.toLowerCase().endsWith('.svg')
                                    ? Image.asset(
                                        'assets/images/details_image.png',
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        userState.value!.profileImageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) => Image.asset(
                                          'assets/images/details_image.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ))
                                : Image.asset(
                                    'assets/images/details_image.png',
                                    fit: BoxFit.cover,
                                  ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImagePicker,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8D6E63), // Brown
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: SvgPicture.asset(
                              AppIcons.icProfileEdit,
                              width: 18,
                              height: 18,
                              // colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Full Name
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                ),
                
                const SizedBox(height: 24),
                
                // Email Address
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true, // Email is unchangeable
                ),
                
                const SizedBox(height: 24),
                
                // Date of Birth
                _buildLabel('Date Of Birth'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: _dobController,
                      hint: 'dd/mm/yy',
                      icon: null, 
                      suffixIcon: Icons.calendar_today_outlined,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Height and Weight Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Height (cm)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _heightController,
                            hint: '',
                            icon: null,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Weight (kg)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _weightController,
                            hint: '',
                            icon: null,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (userState.isLoading || !_hasChanges) ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF964A38), // Rust/Brown
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF964A38).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: userState.isLoading
                          ? [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            ]
                          : [
                              const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFBECE9)), // Light Pink Border
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyMedium.copyWith(
          color: readOnly ? Colors.grey[600] : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[400]),
          prefixIcon: icon != null 
              ? Icon(icon, color: Colors.grey[400], size: 22) 
              : null,
          suffixIcon: suffixIcon != null 
              ? Icon(suffixIcon, color: Colors.grey[500], size: 22) 
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          // If no prefix icon, add padding left
          prefix: icon == null ? const SizedBox(width: 16) : null, 
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF964A38), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF964A38), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      
      String? updatedName;
      if (name != _initialName.trim()) {
         updatedName = name;
      }
      
      String? updatedDob;
      if (_dobController.text.trim() != _initialDob.trim()) {
         if (_selectedDate != null) {
            updatedDob = DateFormat("yyyy-MM-dd'T'00:00:00'Z'").format(_selectedDate!);
         } else {
            updatedDob = _dobController.text.trim();
         }
      }
      
      String? updatedImage;
      if (_selectedImage != null) {
         updatedImage = _selectedImage!.path;
      }
      
      double? updatedHeight;
      if (_heightController.text.trim() != _initialHeight.trim()) {
         updatedHeight = double.tryParse(_heightController.text.trim());
      }
      
      double? updatedWeight;
      if (_weightController.text.trim() != _initialWeight.trim()) {
         updatedWeight = double.tryParse(_weightController.text.trim());
      }

//      print(updatedImage);
      await ref.read(userProvider.notifier).updateProfile(
        name: updatedName,
        dateOfBirth: updatedDob,
        profileImageUrl: updatedImage,
        height: updatedHeight,
        weight: updatedWeight,
      );

      if (mounted) {
        final userState = ref.read(userProvider);
        if (userState.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userState.error.toString())),
          );
        } else {
          // Refresh user profile data
          ref.read(userProvider.notifier).fetchProfile();
          // Also refresh home dashboard so the name updates on the Home Screen
          ref.invalidate(homeDashboardProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully!')),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }
}
