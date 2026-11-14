import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_feedback.dart';
import '../../domain/entities/waybill_stop.dart';
import 'bloc/epod_bloc.dart';
import 'bloc/epod_event.dart';
import 'bloc/epod_state.dart';
import 'capture_epod_sheet.dart';
import 'delivery_receipt_sheet.dart';

class EpodHubView extends StatefulWidget {
  const EpodHubView({super.key});

  @override
  State<EpodHubView> createState() => _EpodHubViewState();
}

class _EpodHubViewState extends State<EpodHubView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<EpodBloc>().add(LoadWaybillsEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCaptureSheet(
    BuildContext context,
    WaybillStop waybill,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return CaptureEpodSheet(
          waybill: waybill,
          onConfirm: (recipientName, signatureSvg, cargoCondition) {
            context.read<EpodBloc>().add(
              ConfirmDeliveryEvent(
                waybillId: waybill.id,
                recipientName: recipientName,
                signatureSvg: signatureSvg,
              ),
            );
          },
        );
      },
    );
  }

  void _openReceiptSheet(
    BuildContext context,
    WaybillStop waybill,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DeliveryReceiptSheet(waybill: waybill);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocConsumer<EpodBloc, EpodState>(
      listener: (context, state) {
        if (state.lastDeliveredWaybill != null) {
          _openReceiptSheet(context, state.lastDeliveredWaybill!, colorScheme);
        }
        if (state.statusMessage != null) {
          AppFeedback.showSuccess(context, state.statusMessage!);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.waybills.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingOrOut = state.waybills
            .where(
              (w) => w.status == 'OUT_FOR_DELIVERY' || w.status == 'PENDING',
            )
            .toList();

        return Scaffold(
          backgroundColor: colorScheme.surface,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_epod_capture',
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.draw),
            label: const Text('Capture ePOD Signature'),
            onPressed: () {
              if (pendingOrOut.isNotEmpty) {
                _openCaptureSheet(context, pendingOrOut.first, colorScheme);
              } else if (state.waybills.isNotEmpty) {
                _openCaptureSheet(context, state.waybills.first, colorScheme);
              } else {
                AppFeedback.showInfo(context, 'No active waybills available.');
              }
            },
          ),
          body: isLandscape
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        controller: ScrollController(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildKpiSummary(context, state, colorScheme),
                            const SizedBox(height: 12),
                            _buildSearchAndFilters(context, state, colorScheme),
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
                      child: SingleChildScrollView(
                        controller: ScrollController(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: _buildWaybillList(context, state, colorScheme),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  controller: ScrollController(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKpiSummary(context, state, colorScheme),
                      const SizedBox(height: 12),
                      _buildSearchAndFilters(context, state, colorScheme),
                      const SizedBox(height: 12),
                      _buildWaybillList(context, state, colorScheme),
                      const SizedBox(height: 80), // Padding for FAB
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildKpiSummary(
    BuildContext context,
    EpodState state,
    ColorScheme colorScheme,
  ) {
    final total = state.waybills.length;
    final delivered = state.waybills
        .where((w) => w.status == 'DELIVERED')
        .length;
    final out = state.waybills
        .where((w) => w.status == 'OUT_FOR_DELIVERY')
        .length;
    final exceptions = state.waybills
        .where((w) => w.status == 'EXCEPTION')
        .length;
    final completionPct = total > 0
        ? (delivered / total * 100).toStringAsFixed(0)
        : '0';

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
              Text(
                'ePOD Dispatch Completion',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '$completionPct% Delivered',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? delivered / total : 0,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKpiItem(
                'Total Manifest',
                '$total',
                colorScheme.onSurface,
                colorScheme,
              ),
              _buildKpiItem(
                'Delivered',
                '$delivered',
                colorScheme.primary,
                colorScheme,
              ),
              _buildKpiItem(
                'In Transit',
                '$out',
                colorScheme.secondary,
                colorScheme,
              ),
              _buildKpiItem(
                'Exceptions',
                '$exceptions',
                colorScheme.error,
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(
    String label,
    String value,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    EpodState state,
    ColorScheme colorScheme,
  ) {
    final filters = [
      {'key': 'ALL', 'label': 'All'},
      {'key': 'OUT_FOR_DELIVERY', 'label': 'Out for Delivery'},
      {'key': 'DELIVERED', 'label': 'Delivered'},
      {'key': 'EXCEPTION', 'label': 'Exceptions'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search waybills, consignee, cargo...',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      context.read<EpodBloc>().add(
                        const SearchWaybillsEvent(''),
                      );
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
          onChanged: (val) {
            context.read<EpodBloc>().add(SearchWaybillsEvent(val));
          },
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: filters.map((f) {
              final isSelected = state.activeFilter == f['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    f['label']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainer,
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                  onSelected: (_) {
                    context.read<EpodBloc>().add(
                      FilterWaybillsEvent(f['key']!),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWaybillList(
    BuildContext context,
    EpodState state,
    ColorScheme colorScheme,
  ) {
    if (state.filteredWaybills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No matching waybills found',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.filteredWaybills.length,
      itemBuilder: (context, index) {
        final w = state.filteredWaybills[index];
        final isDelivered = w.status == 'DELIVERED';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: isDelivered
                  ? colorScheme.primary.withOpacity(0.18)
                  : colorScheme.surfaceContainerHighest,
              child: Icon(
                isDelivered ? Icons.verified : Icons.local_shipping_outlined,
                color: isDelivered
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ),
            title: Text(
              '${w.id} • ${w.stopName}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              '${w.cargoDescription} • ${w.weightKg} kg${w.recipientName != null ? ' • Sign: ${w.recipientName}' : ''}',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(w.status, colorScheme),
                const SizedBox(height: 4),
                Text(
                  isDelivered ? 'View Receipt' : 'Capture ePOD',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDelivered
                        ? colorScheme.primary
                        : colorScheme.secondary,
                  ),
                ),
              ],
            ),
            onTap: () {
              if (isDelivered) {
                _openReceiptSheet(context, w, colorScheme);
              } else {
                _openCaptureSheet(context, w, colorScheme);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme colorScheme) {
    Color bg = colorScheme.surfaceContainerHighest;
    Color fg = colorScheme.onSurface;

    if (status == 'DELIVERED') {
      bg = colorScheme.primary.withOpacity(0.18);
      fg = colorScheme.primary;
    } else if (status == 'OUT_FOR_DELIVERY') {
      bg = colorScheme.secondary.withOpacity(0.18);
      fg = colorScheme.secondary;
    } else if (status == 'EXCEPTION') {
      bg = colorScheme.error.withOpacity(0.18);
      fg = colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
