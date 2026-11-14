import 'package:flutter/material.dart';

import '../../domain/entities/waybill_stop.dart';

class CaptureEpodSheet extends StatefulWidget {
  final WaybillStop waybill;
  final void Function(
    String recipientName,
    String signatureSvg,
    String cargoCondition,
  )
  onConfirm;

  const CaptureEpodSheet({
    super.key,
    required this.waybill,
    required this.onConfirm,
  });

  @override
  State<CaptureEpodSheet> createState() => _CaptureEpodSheetState();
}

class _CaptureEpodSheetState extends State<CaptureEpodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameCtrl = TextEditingController();
  String _cargoCondition = 'PERFECT_INTACT';
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _signatureError = false;

  @override
  void dispose() {
    _recipientNameCtrl.dispose();
    super.dispose();
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _signatureError = false;
    });
  }

  String _generateSvgPath() {
    final buffer = StringBuffer();
    for (final stroke in _strokes) {
      if (stroke.isEmpty) continue;
      buffer.write(
        'M ${stroke.first.dx.toStringAsFixed(1)} ${stroke.first.dy.toStringAsFixed(1)} ',
      );
      for (int i = 1; i < stroke.length; i++) {
        buffer.write(
          'L ${stroke[i].dx.toStringAsFixed(1)} ${stroke[i].dy.toStringAsFixed(1)} ',
        );
      }
    }
    return buffer.toString().trim();
  }

  void _submit() {
    final isNameValid = _formKey.currentState!.validate();
    final hasSignature =
        _strokes.isNotEmpty && _strokes.any((s) => s.length > 2);

    if (!hasSignature) {
      setState(() => _signatureError = true);
    } else {
      setState(() => _signatureError = false);
    }

    if (!isNameValid || !hasSignature) return;

    final svg = _generateSvgPath();
    widget.onConfirm(_recipientNameCtrl.text.trim(), svg, _cargoCondition);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Electronic Proof of Delivery',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${widget.waybill.id} • ${widget.waybill.stopName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
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
                TextFormField(
                  controller: _recipientNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Authorized Consignee / Recipient Name',
                    hintText: 'e.g. Asim Jamil',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Recipient name is mandatory for chain-of-custody';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _cargoCondition,
                  decoration: const InputDecoration(
                    labelText: 'Cargo Inspection Condition',
                  ),
                  dropdownColor: colorScheme.surfaceContainerHighest,
                  items: const [
                    DropdownMenuItem(
                      value: 'PERFECT_INTACT',
                      child: Text('Perfect & Seals Intact'),
                    ),
                    DropdownMenuItem(
                      value: 'COLD_CHAIN_VERIFIED',
                      child: Text('Cold-Chain Temp Verified'),
                    ),
                    DropdownMenuItem(
                      value: 'MINOR_EXTERNAL_WEAR',
                      child: Text('Minor Outer Carton Scuff'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _cargoCondition = val);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consignee Touch Digital Signature',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text(
                        'Clear Signature',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: _clearSignature,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _signatureError
                          ? colorScheme.error
                          : colorScheme.outlineVariant,
                      width: _signatureError ? 1.8 : 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _signatureError = false;
                          _currentStroke = [details.localPosition];
                          _strokes.add(_currentStroke);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _currentStroke.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _currentStroke = [];
                        });
                      },
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          strokeColor: colorScheme.primary,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
                if (_signatureError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Consignee signature is required. Sign above.',
                      style: TextStyle(fontSize: 11, color: colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Confirm & Archive ePOD Manifest'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;

  _SignaturePainter({required this.strokes, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Watermark line
    final guidePaint = Paint()
      ..color = strokeColor.withOpacity(0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(20, size.height - 30),
      Offset(size.width - 20, size.height - 30),
      guidePaint,
    );

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
