import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/ride.dart';
import '../providers/ride_providers.dart';

class MyRidesScreen extends ConsumerWidget {
  const MyRidesScreen({super.key});

  Future<void> _confirmCancelRide(
    BuildContext context,
    WidgetRef ref,
    Ride ride,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer l\'annulation'),
        content: Text(
          'Voulez-vous vraiment annuler votre trajet de ${ride.departureCity} à ${ride.arrivalCity} ?\n'
          'Les passagers ayant réservé seront informés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non, garder'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, annuler le trajet'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) return;

      try {
        final repo = ref.read(rideRepositoryProvider);
        await repo.cancelRide(rideId: ride.id, driverId: currentUserId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le trajet a été annulé avec succès.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(myPublishedRidesProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes trajets publiés')),
      body: ridesAsync.when(
        data: (rides) {
          if (rides.isEmpty) {
            return EmptyStateView(
              icon: Icons.directions_car_outlined,
              title: 'Aucun trajet publié',
              message: 'Vous n\'avez pas encore proposé de covoiturage.',
              buttonText: 'Publier un trajet',
              onButtonPressed: () => context.go('/publish'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final canCancel =
                  currentUserId != null &&
                  ride.canBeEditedOrCancelled(currentUserId);

              Color statusColor;
              String statusText;
              if (ride.isCancelled) {
                statusColor = AppColors.error;
                statusText = 'Annulé';
              } else if (ride.isPast) {
                statusColor = AppColors.textMuted;
                statusText = 'Passé';
              } else {
                statusColor = AppColors.success;
                statusText = 'Actif';
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormatter.formatDateTime(
                              ride.departureDateTime,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${ride.departureCity}  ➔  ${ride.arrivalCity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(ride.pricePerSeat),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Point de rencontre : ${ride.meetingPoint}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Places : ${ride.availableSeats} dispo / ${ride.totalSeats} totales',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.divider),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: const Text('Détails'),
                            onPressed: () => context.push('/rides/${ride.id}'),
                          ),
                          if (canCancel) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Modifier'),
                              onPressed: () =>
                                  context.push('/edit-ride/${ride.id}'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Annuler'),
                              onPressed: () =>
                                  _confirmCancelRide(context, ref, ride),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const LoadingIndicator(message: 'Chargement de vos trajets...'),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
