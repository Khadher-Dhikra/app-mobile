import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/tunisian_cities.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  String _selectedCity = 'Tunis';
  bool _initialized = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    if (_initialized) {
      _firstNameController.dispose();
      _lastNameController.dispose();
      _phoneController.dispose();
    }
    super.dispose();
  }

  void _initControllers(UserProfile profile) {
    if (!_initialized) {
      _firstNameController = TextEditingController(text: profile.firstName);
      _lastNameController = TextEditingController(text: profile.lastName);
      _phoneController = TextEditingController(text: profile.phoneNumber);
      _selectedCity = profile.city.isNotEmpty ? profile.city : 'Tunis';
      _initialized = true;
    }
  }

  Future<void> _handleSave(UserProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedProfile = currentProfile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        city: _selectedCity,
      );

      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil non chargé.'));
          }

          _initControllers(profile);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            label: 'Prénom',
                            prefixIcon: Icons.person_outline,
                            validator: (v) =>
                                Validators.validateRequired(v, 'Le prénom'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            label: 'Nom',
                            prefixIcon: Icons.person_outline,
                            validator: (v) =>
                                Validators.validateRequired(v, 'Le nom'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Numéro de téléphone',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ville de résidence',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.location_city_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: TunisianCities.list.map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCity = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    CustomButton(
                      text: 'Enregistrer les modifications',
                      isLoading: _isSaving,
                      onPressed: () => _handleSave(profile),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Chargement...'),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
