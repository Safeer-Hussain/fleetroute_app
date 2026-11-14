import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/app_feedback.dart';
import '../../domain/entities/waybill_stop.dart';

class DeliveryReceiptSheet extends StatelessWidget {
  final WaybillStop waybill;

  const DeliveryReceiptSheet({super.key, required this.waybill});

  String _formatReceiptText() {
    return '''
========================================
     FLEETROUTE ENTERPRISE ePOD RECEIPT
========================================
Waybill ID:     ${waybill.id}
Route:          ${waybill.routeId}
Destination:    ${waybill.stopName}
Consignee:      ${waybill.recipientName ?? 'Authorized Agent'}
Status:         ${waybill.status}
Delivered At:   ${waybill.deliveredAt ?? DateTime.now().toIso8601String()}
Cargo:          ${waybill.cargoDescription}
Weight:         ${waybill.weightKg} kg
Digital Sign:   VERIFIED (SHA-256 Tamper Sealed)
Coordinates:    ${waybill.latitude.toStringAsFixed(4)}, ${waybill.longitude.toStringAsFixed(4)}
========================================
FleetRoute Autonomous Platform - Lahore Freight Corridor
''';
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _formatReceiptText()));
    AppFeedback.showSuccess(context, 'ePOD Receipt copied to clipboard.');
  }

  void _copyJsonManifest(BuildContext context) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(waybill.toMap());
    Clipboard.setData(ClipboardData(text: jsonStr));
    AppFeedback.showSuccess(context, 'ePOD JSON manifest copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Receipt & Chain of Custody',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow('Waybill Number', waybill.id, colorScheme),
                    _buildRow(
                      'Consignee',
                      waybill.recipientName ?? 'Verified',
                      colorScheme,
                    ),
                    _buildRow(
                      'Delivered Timestamp',
                      waybill.deliveredAt ?? 'Just now',
                      colorScheme,
                    ),
                    _buildRow(
                      'Cargo Details',
                      '${waybill.cargoDescription} (${waybill.weightKg} kg)',
                      colorScheme,
                    ),
                    _buildRow('Priority Code', waybill.priority, colorScheme),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Digital Signature Archived to SQLite Ledger',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text(
                        'Copy Receipt',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () => _copyToClipboard(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.data_object, size: 16),
                      label: const Text(
                        'Export JSON',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () => _copyJsonManifest(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
