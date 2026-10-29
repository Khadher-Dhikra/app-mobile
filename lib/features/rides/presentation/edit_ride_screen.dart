import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../domain/ride.dart';
import '../providers/ride_providers.dart';

class EditRideScreen extends ConsumerStatefulWidget {
  final String rideId;

  const EditRideScreen({super.key, required this.rideId});

  @override
  ConsumerState<EditRideScreen> createState() => _EditRideScreenState();
}

class _EditRideScreenState extends ConsumerState<EditRideScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _meetingPointController;
  late TextEditingController _priceController;
  late TextEditingController _carModelController;
  late TextEditingController _notesController;
  bool _initialized = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    if (_initialized) {
      _meetingPointController.dispose();
      _priceController.dispose();
      _carModelController.dispose();
      _notesController.dispose();
    }
    super.dispose();
  }

  void _initControllers(Ride ride) {
    if (!_initialized) {
      _meetingPointController = TextEditingController(text: ride.meetingPoint);
      _priceController = TextEditingController(
        text: ride.pricePerSeat.toString(),
      );
      _carModelController = TextEditingController(text: ride.carModel);
      _notesController = TextEditingController(text: ride.notes ?? '');
      _initialized = true;
    }
  }

  Future<void> _handleSave(Ride originalRide) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedRide = originalRide.copyWith(
        meetingPoint: _meetingPointController.text.trim(),
        pricePerSeat: double.parse(_priceController.text.trim()),
        carModel: _carModelController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final repo = ref.read(rideRepositoryProvider);
      await repo.updateRide(updatedRide);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trajet mis à jour avec succès !'),
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
    final rideAsync = ref.watch(rideDetailsProvider(widget.rideId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon trajet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: rideAsync.when(
        data: (ride) {
          if (ride == null) {
            return const Center(child: Text('Trajet introuvable.'));
          }

          _initControllers(ride);

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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Itinéraire : ${ride.departureCity} ➔ ${ride.arrivalCity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _meetingPointController,
                      label: 'Point de rencontre',
                      prefixIcon: Icons.pin_drop_outlined,
                      validator: (v) => Validators.validateRequired(
                        v,
                        'Le point de rencontre',
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _priceController,
                      label: 'Prix par place (TND)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.monetization_on_outlined,
                      validator: Validators.validatePrice,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _carModelController,
                      label: 'Modèle de la voiture',
                      prefixIcon: Icons.directions_car_outlined,
                      validator: (v) => Validators.validateRequired(
                        v,
                        'Le modèle de voiture',
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _notesController,
                      label: 'Commentaires additionnels',
                      prefixIcon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
                    CustomButton(
                      text: 'Enregistrer les modifications',
                      isLoading: _isSaving,
                      onPressed: () => _handleSave(ride),
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
