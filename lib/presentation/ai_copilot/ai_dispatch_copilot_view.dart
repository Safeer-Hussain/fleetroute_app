import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_feedback.dart';
import 'cubit/ai_dispatch_cubit.dart';

class AiDispatchCopilotView extends StatefulWidget {
  const AiDispatchCopilotView({super.key});

  @override
  State<AiDispatchCopilotView> createState() => _AiDispatchCopilotViewState();
}

class _AiDispatchCopilotViewState extends State<AiDispatchCopilotView> {
  final TextEditingController _promptCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AiDispatchCubit>().loadHistory();
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendPrompt([String? customPrompt]) {
    final text = customPrompt ?? _promptCtrl.text;
    if (text.trim().isEmpty) return;
    _promptCtrl.clear();
    context.read<AiDispatchCubit>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true, // Auto resize to software keyboard
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'fab_ai_dispatch_clear',
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        onPressed: () {
          context.read<AiDispatchCubit>().clearConversation();
          AppFeedback.showInfo(context, 'Copilot conversation reset.');
        },
        child: const Icon(Icons.cleaning_services, size: 18),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAnalyticsCharts(context, colorScheme),
                        const SizedBox(height: 12),
                        _buildPromptShortcuts(context, colorScheme),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant),
                Expanded(flex: 6, child: _buildChatPane(context, colorScheme)),
              ],
            )
          : Column(
              children: [
                // Collapsible analytics card at top
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _buildAnalyticsCharts(context, colorScheme),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildPromptShortcuts(context, colorScheme),
                ),
                const Divider(height: 16),
                Expanded(child: _buildChatPane(context, colorScheme)),
              ],
            ),
    );
  }

  Widget _buildAnalyticsCharts(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'On-Time & Fuel Curve',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '94.2% On-Time',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 0),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 0),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 0),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 0),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 5.2),
                      FlSpot(1, 6.4),
                      FlSpot(2, 7.8),
                      FlSpot(3, 7.2),
                      FlSpot(4, 8.6),
                      FlSpot(5, 9.1),
                      FlSpot(6, 9.4),
                    ],
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withOpacity(0.12),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 7.5),
                      FlSpot(1, 6.8),
                      FlSpot(2, 6.1),
                      FlSpot(3, 5.8),
                      FlSpot(4, 5.2),
                      FlSpot(5, 4.9),
                      FlSpot(6, 4.6),
                    ],
                    isCurved: true,
                    color: colorScheme.secondary,
                    barWidth: 2.0,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(colorScheme.primary, 'On-Time %', colorScheme),
              const SizedBox(width: 14),
              _buildLegendDot(
                colorScheme.secondary,
                'Fuel L/100km',
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPromptShortcuts(BuildContext context, ColorScheme colorScheme) {
    final shortcuts = [
      'Optimize Delayed Routes & Reroute Traffic',
      'Audit Vehicles With Active OBD-II Faults',
      'Analyze Weekly Fuel & Cold-Chain Efficiency',
      'Generate End-of-Shift Fleet Executive Summary',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: shortcuts.map((prompt) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              backgroundColor: colorScheme.surfaceContainer,
              side: BorderSide(color: colorScheme.outlineVariant),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              label: Text(
                prompt,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              onPressed: () => _sendPrompt(prompt),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatPane(BuildContext context, ColorScheme colorScheme) {
    return BlocConsumer<AiDispatchCubit, AiDispatchState>(
      listener: (context, state) {
        if (state.isStreaming) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final msg = state.messages[index];
                  final isUser = msg.role == 'user';

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? colorScheme.primary
                            : colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUser
                              ? Colors.transparent
                              : colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUser ? Icons.person : Icons.psychology,
                                size: 14,
                                color: isUser
                                    ? colorScheme.onPrimary
                                    : colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isUser
                                    ? 'Operations Dispatcher'
                                    : 'FleetRoute AI Copilot',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isUser
                                      ? colorScheme.onPrimary.withOpacity(0.9)
                                      : colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.content.isEmpty && msg.isStreaming
                                ? '...'
                                : msg.content,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: isUser
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (state.streamingStatus != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                color: colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.streamingStatus!,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Bottom Input bar: Rely on Scaffold resizeToAvoidBottomInset + SafeArea(top: false)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptCtrl,
                        decoration: InputDecoration(
                          hintText: 'Ask FleetRoute Dispatch Copilot...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _sendPrompt(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: colorScheme.primary,
                      onPressed: state.isStreaming ? null : () => _sendPrompt(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
