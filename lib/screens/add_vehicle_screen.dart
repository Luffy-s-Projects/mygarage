import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _mileageController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _saveButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _saveButtonScale;
  late Animation<double> _saveButtonGlow;

  bool _isLoading = false;
  bool _isEditMode = false;

  // Focus nodes for animated border effects
  final _makeFocus = FocusNode();
  final _modelFocus = FocusNode();
  final _yearFocus = FocusNode();
  final _licensePlateFocus = FocusNode();
  final _mileageFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.vehicle != null;

    if (_isEditMode) {
      _makeController.text = widget.vehicle!.make;
      _modelController.text = widget.vehicle!.model;
      _yearController.text = widget.vehicle!.year.toString();
      _licensePlateController.text = widget.vehicle!.licensePlate;
      _mileageController.text = widget.vehicle!.mileage.toString();
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _saveButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _saveButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _saveButtonController, curve: Curves.easeInOut),
    );
    _saveButtonGlow = Tween<double>(begin: 0.4, end: 0.7).animate(
      CurvedAnimation(parent: _saveButtonController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _mileageController.dispose();
    _fadeController.dispose();
    _saveButtonController.dispose();
    _makeFocus.dispose();
    _modelFocus.dispose();
    _yearFocus.dispose();
    _licensePlateFocus.dispose();
    _mileageFocus.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final vehicleData = {
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'licensePlate': _licensePlateController.text.trim().toUpperCase(),
        'mileage': int.parse(_mileageController.text.trim()),
      };

      final vehiclesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('vehicles');

      if (_isEditMode) {
        await vehiclesRef.doc(widget.vehicle!.id).update(vehicleData);
      } else {
        await vehiclesRef.add(vehicleData);
      }

      HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save vehicle: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(),
                          const SizedBox(height: 32),
                          _buildSectionTitle(
                            'Vehicle Details',
                            Icons.info_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedTextField(
                            controller: _makeController,
                            focusNode: _makeFocus,
                            label: 'Make',
                            hint: 'e.g. Toyota, Honda, Ford',
                            icon: Icons.factory_outlined,
                            delay: 0,
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedTextField(
                            controller: _modelController,
                            focusNode: _modelFocus,
                            label: 'Model',
                            hint: 'e.g. Camry, Civic, Mustang',
                            icon: Icons.directions_car_outlined,
                            delay: 50,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAnimatedTextField(
                                  controller: _yearController,
                                  focusNode: _yearFocus,
                                  label: 'Year',
                                  hint: 'e.g. 2024',
                                  icon: Icons.calendar_today_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  validator: _validateYear,
                                  delay: 100,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAnimatedTextField(
                                  controller: _mileageController,
                                  focusNode: _mileageFocus,
                                  label: 'Mileage',
                                  hint: 'e.g. 25000',
                                  icon: Icons.speed_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: _validateMileage,
                                  delay: 150,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle(
                            'Registration',
                            Icons.badge_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedTextField(
                            controller: _licensePlateController,
                            focusNode: _licensePlateFocus,
                            label: 'License Plate',
                            hint: 'e.g. ABC 1234',
                            icon: Icons.credit_card_outlined,
                            textCapitalization: TextCapitalization.characters,
                            delay: 200,
                          ),
                          const SizedBox(height: 40),
                          _buildSaveButton(),
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isEditMode ? 'Edit Vehicle' : 'Add Vehicle',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C63FF).withValues(alpha: 0.15),
              const Color(0xFF00D9FF).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF6C63FF), const Color(0xFF8B7DFF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isEditMode ? Icons.edit_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditMode ? 'Edit Your Vehicle' : 'Add New Vehicle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isEditMode
                        ? 'Update your vehicle information below'
                        : 'Fill in the details of your vehicle',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.words,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _AnimatedInputField(
        controller: controller,
        focusNode: focusNode,
        label: label,
        hint: hint,
        icon: icon,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator ?? _validateRequired,
        textCapitalization: textCapitalization,
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Year is required';
    }
    final year = int.tryParse(value);
    if (year == null) {
      return 'Enter a valid year';
    }
    if (year < 1900 || year > DateTime.now().year + 2) {
      return 'Enter a valid year';
    }
    return null;
  }

  String? _validateMileage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mileage is required';
    }
    final mileage = int.tryParse(value);
    if (mileage == null) {
      return 'Enter valid mileage';
    }
    if (mileage < 0) {
      return 'Mileage cannot be negative';
    }
    return null;
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (!_isLoading) {
          _saveButtonController.forward();
          HapticFeedback.selectionClick();
        }
      },
      onTapUp: (_) {
        _saveButtonController.reverse();
        if (!_isLoading) {
          _saveVehicle();
        }
      },
      onTapCancel: () {
        _saveButtonController.reverse();
      },
      child: AnimatedBuilder(
        animation: _saveButtonController,
        builder: (context, child) {
          return Transform.scale(
            scale: _saveButtonScale.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [
                          const Color(0xFF6C63FF).withValues(alpha: 0.5),
                          const Color(0xFF8B7DFF).withValues(alpha: 0.5),
                        ]
                      : [const Color(0xFF6C63FF), const Color(0xFF8B7DFF)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF6C63FF,
                    ).withValues(alpha: _saveButtonGlow.value),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEditMode
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isEditMode ? 'Save Changes' : 'Add Vehicle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom animated input field widget with focus glow effect
class _AnimatedInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?) validator;
  final TextCapitalization textCapitalization;

  const _AnimatedInputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.inputFormatters,
    required this.validator,
    required this.textCapitalization,
  });

  @override
  State<_AnimatedInputField> createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<_AnimatedInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _borderAnimation;
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _borderAnimation = Tween<double>(begin: 0.1, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final borderColor = _hasError
            ? const Color(0xFFFF6B6B)
            : _isFocused
            ? const Color(0xFF6C63FF)
            : Colors.white;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (_isFocused && !_hasError)
                BoxShadow(
                  color: const Color(
                    0xFF6C63FF,
                  ).withValues(alpha: _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              if (_hasError)
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: const Color(0xFF6C63FF),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              labelStyle: TextStyle(
                color: _isFocused
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  widget.icon,
                  color: _isFocused
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withValues(alpha: 0.4),
                  size: 22,
                ),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: borderColor.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(
                    0xFF6C63FF,
                  ).withValues(alpha: _borderAnimation.value),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFFFF6B6B),
                  width: 2,
                ),
              ),
              errorStyle: TextStyle(
                color: const Color(0xFFFF6B6B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: (value) {
              final error = widget.validator(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _hasError != (error != null)) {
                  setState(() {
                    _hasError = error != null;
                  });
                }
              });
              return error;
            },
          ),
        );
      },
    );
  }
}
