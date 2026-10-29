import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_providers.dart';
import '../../reviews/presentation/add_review_dialog.dart';
import '../../rides/providers/ride_providers.dart';
import '../domain/booking.dart';
import '../providers/booking_providers.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  int _selectedTabIndex = 0; // 0 = Mes réservations, 1 = Mes trajets

  Future<void> _handleCancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Annuler la réservation',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir annuler cette réservation ? '
          'Si la demande était acceptée, la place sera immédiatement libérée.',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non, garder'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) return;

      try {
        final repo = ref.read(bookingRepositoryProvider);
        await repo.cancelBooking(
          bookingId: booking.id,
          currentUserId: currentUserId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation annulée avec succès.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: AppLogo(
          size: 34,
          subtitle: _selectedTabIndex == 0
              ? 'Vue passager · Après acceptation'
              : 'Vue conducteur',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Control Tabs: Mes réservations | Mes trajets
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(8),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Mes réservations',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: _selectedTabIndex == 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _selectedTabIndex == 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(8),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Mes trajets',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: _selectedTabIndex == 1
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _selectedTabIndex == 1
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildPassengerView()
                  : _buildDriverView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerView() {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return EmptyStateView(
            icon: Icons.confirmation_number_outlined,
            title: 'Aucune réservation',
            message: 'Vous n\'avez effectué aucune demande de réservation.',
            buttonText: 'Chercher un trajet',
            onButtonPressed: () => context.go('/home'),
          );
        }

        final acceptedBookings = bookings.where((b) => b.isAccepted).toList();
        final otherBookings = bookings.where((b) => !b.isAccepted).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Text(
              'Votre place vous attend.',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Retrouvez vos demandes et vos départs à venir.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // Cartes acceptées
            ...acceptedBookings.map((b) => _buildAcceptedCard(b)),

            // Section: Mes autres demandes
            if (otherBookings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Mes autres demandes',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...otherBookings.map((b) => _buildOtherCard(b)),
            ],

            const SizedBox(height: 18),
            Center(
              child: Text(
                'Le contact est réservé aux participants autorisés, uniquement tant que la réservation est acceptée.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () =>
          const LoadingIndicator(message: 'Chargement de vos réservations...'),
      error: (err, _) => Center(child: Text('Erreur: $err')),
    );
  }

  Widget _buildAcceptedCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Acceptée',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                '${booking.seatsCount} place réservée',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${booking.departureCity}  ➔  ${booking.arrivalCity}',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('EEE. d MMMM yyyy · HH:mm', 'fr_FR').format(booking.departureDateTime)} · ${CurrencyFormatter.format(booking.totalPrice)}',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),

          // Conducteur & Contact
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFFDE68A),
                child: Text(
                  'CD',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conducteur assigné',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Conducteur · Contact autorisé',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Point de rencontre
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.pin_drop_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.meetingPoint,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Action: Afficher mon code de départ
          CustomButton(
            text: 'Afficher mon code de départ',
            icon: Icons.vpn_key_rounded,
            backgroundColor: AppColors.primary,
            onPressed: () {
              context.push('/departure-code/${booking.id}');
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () => _handleCancelBooking(booking),
              child: Text(
                'Annuler ma réservation',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherCard(Booking booking) {
    Color pillBg = AppColors.surfaceVariant;
    Color pillTextColor = AppColors.textSecondary;
    String pillText = booking.statusDisplay;

    if (booking.isPending) {
      pillBg = AppColors.warningLight;
      pillTextColor = AppColors.warning;
    } else if (booking.isRejected) {
      pillBg = AppColors.errorLight;
      pillTextColor = AppColors.error;
    } else if (booking.isCompleted) {
      pillBg = AppColors.secondaryLight;
      pillTextColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${booking.departureCity}  ➔  ${booking.arrivalCity}',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pillText,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pillTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${DateFormat('d MMM yyyy · HH:mm', 'fr_FR').format(booking.departureDateTime)} · ${booking.seatsCount} place demandée',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.isCompleted
                    ? 'Trajet effectué'
                    : 'Contact et code indisponibles',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),
              if (booking.isPending)
                GestureDetector(
                  onTap: () => _handleCancelBooking(booking),
                  child: Text(
                    'Annuler la demande',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              else if (booking.isCompleted)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AddReviewDialog(
                        rideId: booking.rideId,
                        targetUserId: booking.driverId,
                      ),
                    );
                  },
                  child: Text(
                    'Laisser un avis',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverView() {
    final ridesAsync = ref.watch(myPublishedRidesProvider);

    return ridesAsync.when(
      data: (rides) {
        if (rides.isEmpty) {
          return EmptyStateView(
            icon: Icons.directions_car_outlined,
            title: 'Aucun trajet proposé',
            message: 'Vous n\'avez publié aucun trajet pour le moment.',
            buttonText: 'Publier un trajet',
            onButtonPressed: () => context.go('/publish'),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Text(
              'Vos trajets, votre rythme.',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gérez les trajets que vous avez publiés.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            ...rides.map((ride) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat(
                            'd MMM yyyy · HH:mm',
                            'fr_FR',
                          ).format(ride.departureDateTime),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
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
                            color: ride.isCancelled
                                ? AppColors.errorLight
                                : AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ride.isCancelled ? 'Annulé' : 'Ouvert',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ride.isCancelled
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${ride.departureCity}  ➔  ${ride.arrivalCity}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${ride.availableSeats} / ${ride.totalSeats} places libres',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(ride.pricePerSeat)} / pers.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 14),

                    // Actions
                    CustomButton(
                      text: 'Gérer les demandes reçues',
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        // Open driver requests management modal
                        _showRideBookingsModal(context, ride);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/edit-ride/${ride.id}'),
                          child: Text(
                            'Modifier le trajet',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () {
                            context.push('/my-rides');
                          },
                          child: Text(
                            'Annuler le trajet',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.error,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),
            CustomButton(
              text: '+  Publier un autre trajet',
              backgroundColor: Colors.white,
              textColor: AppColors.primary,
              isOutlined: true,
              onPressed: () => context.go('/publish'),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const LoadingIndicator(message: 'Chargement...'),
      error: (err, _) => Center(child: Text('Erreur: $err')),
    );
  }

  void _showRideBookingsModal(BuildContext context, dynamic ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final bookings =
              ref.watch(driverReceivedBookingsProvider).value ?? [];
          final rideBookings = bookings
              .where((b) => b.rideId == ride.id)
              .toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Demandes reçues',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${ride.departureCity} ➔ ${ride.arrivalCity} · ${ride.availableSeats} places libres sur ${ride.totalSeats}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: rideBookings.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune réservation reçue pour ce trajet.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: rideBookings.length,
                          itemBuilder: (ctx, idx) {
                            final b = rideBookings[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        b.passengerName,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: b.isAccepted
                                              ? AppColors.secondaryLight
                                              : AppColors.warningLight,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          b.statusDisplay,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: b.isAccepted
                                                ? AppColors.primary
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${b.seatsCount} place(s) · ${CurrencyFormatter.format(b.totalPrice)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (b.isAccepted) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Téléphone : ${b.passengerPhone}',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomButton(
                                      text: 'Saisir son code au départ',
                                      backgroundColor: AppColors.primary,
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        context.push('/departure-code/${b.id}');
                                      },
                                    ),
                                  ] else if (b.isPending) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            text: 'Accepter',
                                            backgroundColor: AppColors.primary,
                                            onPressed: () async {
                                              await ref
                                                  .read(
                                                    bookingRepositoryProvider,
                                                  )
                                                  .respondToBooking(
                                                    bookingId: b.id,
                                                    driverId: b.driverId,
                                                    accept: true,
                                                  );
                                              if (ctx.mounted) {
                                                Navigator.of(ctx).pop();
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: CustomButton(
                                            text: 'Refuser',
                                            isOutlined: true,
                                            onPressed: () async {
                                              await ref
                                                  .read(
                                                    bookingRepositoryProvider,
                                                  )
                                                  .respondToBooking(
                                                    bookingId: b.id,
                                                    driverId: b.driverId,
                                                    accept: false,
                                                  );
                                              if (ctx.mounted) {
                                                Navigator.of(ctx).pop();
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
