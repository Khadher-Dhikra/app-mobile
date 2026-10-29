import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/report.dart';
import '../providers/report_providers.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  Future<void> _updateStatusDialog(
    BuildContext context,
    WidgetRef ref,
    Report report,
  ) async {
    final decisionController = TextEditingController(
      text: report.adminDecision ?? '',
    );
    String selectedStatus = report.status;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Traiter le signalement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('En attente')),
                  DropdownMenuItem(
                    value: 'reviewed',
                    child: Text('En cours d\'examen'),
                  ),
                  DropdownMenuItem(
                    value: 'resolved',
                    child: Text('Résolu / Mesure prise'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedStatus = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: decisionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Décision prise / Commentaire admin',
                  hintText: 'ex: Avertissement envoyé, compte restreint...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final repo = ref.read(reportRepositoryProvider);
      await repo.updateReportStatus(
        reportId: report.id,
        status: selectedStatus,
        adminDecision: decisionController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statut du signalement mis à jour.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).value;

    // Protection accès administrateur
    if (userProfile == null || !userProfile.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès restreint')),
        body: const Center(
          child: Text(
            'Cette section est réservée aux administrateurs TAWSILA.',
          ),
        ),
      );
    }

    final reportsAsync = ref.watch(allReportsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modération des signalements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const EmptyStateView(
              icon: Icons.check_circle_outline_rounded,
              title: 'Aucun signalement',
              message: 'Tous les signalements ont été traités.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              Color statusColor = AppColors.warning;
              if (report.status == 'resolved') statusColor = AppColors.success;
              if (report.status == 'reviewed') statusColor = AppColors.info;

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
                            report.category,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
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
                              report.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Signalé par : ${report.reporterName} • ${DateFormatter.formatShortDate(report.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        report.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (report.adminDecision != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Décision : ${report.adminDecision}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Traiter'),
                          onPressed: () =>
                              _updateStatusDialog(context, ref, report),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const LoadingIndicator(message: 'Chargement des signalements...'),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
