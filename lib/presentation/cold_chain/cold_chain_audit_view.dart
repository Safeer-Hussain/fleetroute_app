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

  static Future<void> show(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ColdChainAuditView()));
  }

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
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainer,
          title: Text(
            'Acknowledge Excursion ${excursion.id}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle: ${excursion.vehicleName} (${excursion.vehicleId})',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recorded Peak: ${excursion.formattedTemp} (Threshold: ${excursion.formattedThreshold})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Corrective Action & Auditor Notes',
                  hintText: 'Enter reefer inspection details, driver notes, or salvage log...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: () {
                final notes = textController.text.trim().isEmpty
                    ? 'Auditor reviewed and verified reefer operation.'
                    : textController.text.trim();
                final cubit = widget.cubit ?? context.read<ColdChainCubit>();
                cubit.acknowledgeExcursion(
                  excursionId: excursion.id,
                  auditorNotes: notes,
                );
                Navigator.of(dialogCtx).pop();
                AppFeedback.showSuccess(
                  context,
                  'Excursion ${excursion.id} acknowledged.',
                );
              },
              child: const Text('Confirm Acknowledgment'),
            ),
          ],
        );
      },
    );
  }

  void _showCsvExportModal(
    BuildContext context,
    String csvData,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pharma GDP Excursion Audit Export',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'RFC 4180 CSV Standard Format',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        csvData,
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
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy CSV Manifest to Clipboard'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: csvData));
                    Navigator.of(sheetCtx).pop();
                    AppFeedback.showSuccess(
                      context,
                      'GDP Excursion Audit CSV copied to clipboard.',
                    );
                  },
                ),
              ],
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

    final content = BlocConsumer<ColdChainCubit, ColdChainState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppFeedback.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        if (state.status == ColdChainStatus.loading &&
            state.excursions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = state.filteredExcursions;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surfaceContainer,
            title: Text(
              'Cold-Chain Excursion Audit Log',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Export GDP CSV',
                icon: Icon(Icons.download, color: colorScheme.primary),
                onPressed: () async {
                  final cubit = widget.cubit ?? context.read<ColdChainCubit>();
                  final csv = await cubit.exportAuditCsv();
                  if (context.mounted) {
                    _showCsvExportModal(context, csv, colorScheme);
                  }
                },
              ),
              IconButton(
                tooltip: 'Refresh Log',
                icon: Icon(Icons.refresh, color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  final cubit = widget.cubit ?? context.read<ColdChainCubit>();
                  cubit.loadExcursions();
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_cold_chain_export',
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.file_download),
            label: const Text('Export GDP Audit'),
            onPressed: () async {
              final cubit = widget.cubit ?? context.read<ColdChainCubit>();
              final csv = await cubit.exportAuditCsv();
              if (context.mounted) {
                _showCsvExportModal(context, csv, colorScheme);
              }
            },
          ),
          body: isLandscape
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMetricsOverview(state.metrics, colorScheme),
                            const SizedBox(height: 12),
                            _buildFilterSelector(context, state, colorScheme),
                          ],
                        ),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: colorScheme.outlineVariant,
                    ),
                    Expanded(
                      flex: 6,
                      child: _buildExcursionListView(
                        filtered,
                        colorScheme,
                        context,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _buildMetricsOverview(state.metrics, colorScheme),
                          const SizedBox(height: 10),
                          _buildFilterSelector(context, state, colorScheme),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildExcursionListView(
                        filtered,
                        colorScheme,
                        context,
                      ),
                    ),
                  ],
                ),
        );
      },
    );

    if (widget.cubit != null) {
      return BlocProvider<ColdChainCubit>.value(
        value: widget.cubit!,
        child: content,
      );
    }
    return content;
  }

  Widget _buildMetricsOverview(
    Map<String, dynamic> metrics,
    ColorScheme colorScheme,
  ) {
    final compliance =
        (metrics['compliance_score'] as num?)?.toDouble() ?? 100.0;
    final breached = (metrics['breached_excursions'] as num?)?.toInt() ?? 0;
    final active = (metrics['active_excursions'] as num?)?.toInt() ?? 0;

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
                  'GDP REEFER COMPLIANCE',
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
                  color: compliance >= 90.0
                      ? colorScheme.primaryContainer
                      : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${compliance.toStringAsFixed(1)}% COMPLIANT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: compliance >= 90.0
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
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
                  'Active',
                  '$active active',
                  active > 0 ? colorScheme.error : colorScheme.onSurface,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  '> 5-Min Breaches',
                  '$breached events',
                  breached > 0 ? colorScheme.error : colorScheme.onSurface,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile(
                  'Threshold',
                  'Max -15.0 °C',
                  colorScheme.primary,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector(
    BuildContext context,
    ColdChainState state,
    ColorScheme colorScheme,
  ) {
    final cubit = widget.cubit ?? context.read<ColdChainCubit>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildFilterChip(
            'All Excursions',
            ColdChainFilter.all,
            state.filter,
            cubit,
            colorScheme,
          ),
          _buildFilterChip(
            'Breached (>5m)',
            ColdChainFilter.activeBreaches,
            state.filter,
            cubit,
            colorScheme,
          ),
          _buildFilterChip(
            'Resolved',
            ColdChainFilter.resolved,
            state.filter,
            cubit,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ColdChainFilter filter,
    ColdChainFilter currentFilter,
    ColdChainCubit cubit,
    ColorScheme colorScheme,
  ) {
    final isSelected = filter == currentFilter;
    return Expanded(
      child: InkWell(
        onTap: () => cubit.setFilter(filter),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExcursionListView(
    List<TemperatureExcursion> excursions,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    if (excursions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 36,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Zero Excursion Breaches',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'All refrigerated reefer units operating strictly within nominal GDP specifications.',
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: excursions.length,
      itemBuilder: (ctx, index) {
        final exc = excursions[index];
        final isBreached = exc.isThresholdBreached;
        final isCritical =
            exc.severity == TemperatureExcursionSeverity.critical;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCritical
                  ? colorScheme.error
                  : isBreached
                  ? colorScheme.error.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? colorScheme.errorContainer
                          : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.thermostat,
                      size: 16,
                      color: isCritical
                          ? colorScheme.onErrorContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                          '${exc.vehicleId} | Route: ${exc.routeId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        exc.formattedTemp,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCritical
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Limit: ${exc.formattedThreshold}',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 4,
                spacing: 8,
                children: [
                  Text(
                    'Duration: ${exc.formattedDuration}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isBreached
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isBreached
                          ? colorScheme.error
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    exc.isActive ? 'BREACH ACTIVE' : 'RESOLVED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: exc.isActive
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                  Text(
                    exc.isAcknowledged ? 'ACKNOWLEDGED' : 'PENDING AUDIT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: exc.isAcknowledged
                          ? colorScheme.secondary
                          : colorScheme.error,
                    ),
                  ),
                ],
              ),
              if (exc.notes != null && exc.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Auditor: ${exc.notes!}',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (!exc.isAcknowledged) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text(
                      'Acknowledge Breach',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () =>
                        _showAcknowledgeDialog(context, exc, colorScheme),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
