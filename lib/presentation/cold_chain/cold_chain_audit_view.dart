import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_feedback.dart';
import '../../domain/entities/temperature_excursion.dart';
import 'cubit/cold_chain_cubit.dart';
import 'cubit/cold_chain_state.dart';

class ColdChainAuditView extends StatefulWidget {
  final ColdChainCubit? cubit;

  const ColdChainAuditView({super.key, this.cubit});

  @override
  State<ColdChainAuditView> createState() => _ColdChainAuditViewState();
}

class _ColdChainAuditViewState extends State<ColdChainAuditView> {
  @override
  void initState() {
    super.initState();
    final cubit = widget.cubit ?? context.read<ColdChainCubit>();
    cubit.loadExcursions();
  }

  void _showAcknowledgeDialog(
    BuildContext context,
    TemperatureExcursion excursion,
    ColorScheme colorScheme,
  ) {
    final nameController = TextEditingController(text: 'Dr. QA Auditor');
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auditor Excursion Sign-Off',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Excursion ID: ${excursion.id} (${excursion.vehicleName})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Auditor Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person, size: 18),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Corrective Action & Root Cause Notes',
                      hintText: 'e.g. Reefer compressor reset; cargo integrity verified.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Sign & Archive'),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final cubit = widget.cubit ?? context.read<ColdChainCubit>();
                  cubit.acknowledgeExcursion(
                    excursionId: excursion.id,
                    auditorName: nameController.text.trim(),
                    notes: notesController.text.trim(),
                  );
                  Navigator.of(dialogCtx).pop();
                  AppFeedback.showSuccess(
                    context,
                    'Audit log signed and certified by ${nameController.text.trim()}.',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showExportSheet(
    BuildContext context,
    String csvContent,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pharma QA Excursion Audit CSV',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Compliant with WHO/FDA Good Distribution Practice (GDP) Annex 5 Standards.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          csvContent,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy CSV Manifest to Clipboard'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csvContent));
                      Navigator.of(sheetCtx).pop();
                      AppFeedback.showSuccess(
                        context,
                        'Excursion Audit CSV copied to clipboard.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final cubit = widget.cubit ?? context.read<ColdChainCubit>();

    return BlocConsumer<ColdChainCubit, ColdChainState>(
      bloc: cubit,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppFeedback.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            toolbarHeight: isLandscape ? 40 : 56,
            title: Text(
              'Cold-Chain Excursion Audit Log',
              style: TextStyle(
                fontSize: isLandscape ? 14 : 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Audit Logs',
                onPressed: () => cubit.loadExcursions(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_cold_chain_export',
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.file_download),
            label: const Text('Export QA CSV'),
            onPressed: () async {
              final csv = await cubit.exportAuditCsv();
              if (context.mounted && csv.isNotEmpty) {
                _showExportSheet(context, csv, colorScheme);
              }
            },
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, state, cubit, colorScheme)
              : _buildPortraitLayout(context, state, cubit, colorScheme),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ColdChainState state,
    ColdChainCubit cubit,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetricsOverview(state, colorScheme),
          const SizedBox(height: 12),
          _buildRegulatoryThresholdBanner(colorScheme),
          const SizedBox(height: 12),
          _buildFilterChips(state, cubit, colorScheme),
          const SizedBox(height: 12),
          if (state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            )
          else if (state.filteredExcursions.isEmpty)
            _buildEmptyState(colorScheme)
          else
            ...state.filteredExcursions.map(
              (exc) => _buildExcursionCard(context, exc, colorScheme),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ColdChainState state,
    ColdChainCubit cubit,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMetricsOverview(state, colorScheme),
                const SizedBox(height: 10),
                _buildRegulatoryThresholdBanner(colorScheme),
                const SizedBox(height: 10),
                _buildFilterChips(state, cubit, colorScheme),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, color: colorScheme.outlineVariant),
        Expanded(
          flex: 6,
          child: state.isLoading
              ? Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                )
              : state.filteredExcursions.isEmpty
              ? _buildEmptyState(colorScheme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: state.filteredExcursions.length,
                  itemBuilder: (ctx, idx) => _buildExcursionCard(
                    context,
                    state.filteredExcursions[idx],
                    colorScheme,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMetricsOverview(ColdChainState state, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'PHARMA REEFER AUDIT METRICS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'GDP ANNEX 5',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Excursions',
                  '${state.totalExcursions}',
                  colorScheme.primary,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Breaches (>5m)',
                  '${state.criticalBreachCount}',
                  colorScheme.error,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Compliant (<5m)',
                  '${state.compliantTransientCount}',
                  colorScheme.secondary,
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    Color accentColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegulatoryThresholdBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.ac_unit, color: colorScheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Target: -20.0°C | Critical Excursion: > -15.0°C for > 300s',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    ColdChainState state,
    ColdChainCubit cubit,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ColdChainFilter.values.map((f) {
          final isSelected = f == state.filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              selected: isSelected,
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
              onSelected: (_) => cubit.setFilter(f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExcursionCard(
    BuildContext context,
    TemperatureExcursion exc,
    ColorScheme colorScheme,
  ) {
    final isBreach = exc.isAuditableBreach;
    final isResolved = exc.isResolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBreach
              ? colorScheme.error.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isBreach
                            ? colorScheme.errorContainer
                            : colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isBreach ? Icons.warning : Icons.thermostat,
                        size: 16,
                        color: isBreach
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exc.vehicleName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Driver: ${exc.driverName} | Route: ${exc.routeId}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBreach
                      ? colorScheme.errorContainer
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isBreach ? 'REGULATORY BREACH' : 'COMPLIANT TRANSIENT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isBreach
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildExcursionParam(
                  'Peak Temp',
                  exc.formattedPeakTemp,
                  colorScheme,
                  isAlert: exc.maxRecordedTempC > -15.0,
                ),
              ),
              Expanded(
                child: _buildExcursionParam(
                  'Duration',
                  exc.formattedDuration,
                  colorScheme,
                  isAlert: exc.durationSeconds >= 300,
                ),
              ),
              Expanded(
                child: _buildExcursionParam(
                  'Status',
                  isResolved ? 'Resolved' : 'Active / Unsigned',
                  colorScheme,
                ),
              ),
            ],
          ),
          if (exc.resolutionNotes != null &&
              exc.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Notes: ${exc.resolutionNotes} (Signed: ${exc.acknowledgedBy ?? "Unknown"})',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (!isResolved) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.rate_review, size: 16),
                label: const Text(
                  'Sign & Acknowledge Excursion',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () =>
                    _showAcknowledgeDialog(context, exc, colorScheme),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExcursionParam(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isAlert = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isAlert ? colorScheme.error : colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 32,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Zero Cold-Chain Excursions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All pharmaceutical cold-chain reefer cargo units are maintained within regulatory temperature boundaries.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
