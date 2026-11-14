import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/ai_chat_message.dart';
import '../../../domain/repositories/ai_copilot_repository.dart';

class AiDispatchState extends Equatable {
  final List<AiChatMessage> messages;
  final bool isStreaming;
  final String? streamingStatus;
  final bool isLoading;

  const AiDispatchState({
    this.messages = const [],
    this.isStreaming = false,
    this.streamingStatus,
    this.isLoading = false,
  });

  AiDispatchState copyWith({
    List<AiChatMessage>? messages,
    bool? isStreaming,
    String? streamingStatus,
    bool clearStreamingStatus = false,
    bool? isLoading,
  }) {
    return AiDispatchState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingStatus: clearStreamingStatus
          ? null
          : (streamingStatus ?? this.streamingStatus),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isStreaming,
    streamingStatus,
    isLoading,
  ];
}

class AiDispatchCubit extends Cubit<AiDispatchState> {
  final AiCopilotRepository aiRepository;
  static const _uuid = Uuid();

  AiDispatchCubit({required this.aiRepository})
    : super(const AiDispatchState());

  Future<void> loadHistory() async {
    emit(state.copyWith(isLoading: true));
    try {
      final history = await aiRepository.getConversationHistory();
      emit(
        state.copyWith(messages: List.unmodifiable(history), isLoading: false),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> sendMessage(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final userMessage = AiChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now().toIso8601String(),
    );

    await aiRepository.saveMessage(userMessage);

    final currentMessages = List<AiChatMessage>.from(state.messages)
      ..add(userMessage);

    // Placeholder message for streaming assistant response
    final assistantMsgId = _uuid.v4();
    final assistantPlaceholder = AiChatMessage(
      id: assistantMsgId,
      role: 'assistant',
      content: '',
      timestamp: DateTime.now().toIso8601String(),
      isStreaming: true,
    );

    currentMessages.add(assistantPlaceholder);

    emit(
      state.copyWith(
        messages: List.unmodifiable(currentMessages),
        isStreaming: true,
        streamingStatus: 'Correlating GPS routes, cold-chain telemetry & OBD-II fault logs...',
      ),
    );

    String accumulatedContent = '';

    try {
      final stream = aiRepository.streamCopilotResponse(trimmed);
      await for (final token in stream) {
        accumulatedContent += token;

        final updatedList = state.messages.map((m) {
          if (m.id == assistantMsgId) {
            return m.copyWith(content: accumulatedContent);
          }
          return m;
        }).toList();

        emit(state.copyWith(messages: List.unmodifiable(updatedList)));
      }

      // Save complete message to repository
      final finalAssistantMsg = AiChatMessage(
        id: assistantMsgId,
        role: 'assistant',
        content: accumulatedContent,
        timestamp: DateTime.now().toIso8601String(),
        isStreaming: false,
      );
      await aiRepository.saveMessage(finalAssistantMsg);
    } catch (e) {
      accumulatedContent +=
          '\n[System: Telemetry correlation stream disrupted]';
    } finally {
      // Guaranteed stream cleanup to dismiss spinners
      final finalList = state.messages.map((m) {
        if (m.id == assistantMsgId) {
          return m.copyWith(content: accumulatedContent, isStreaming: false);
        }
        return m;
      }).toList();

      emit(
        state.copyWith(
          messages: List.unmodifiable(finalList),
          isStreaming: false,
          clearStreamingStatus: true,
        ),
      );
    }
  }

  Future<void> clearConversation() async {
    final resetMsg = AiChatMessage(
      id: _uuid.v4(),
      role: 'assistant',
      content: 'Conversation cleared. Dispatch telemetry copilot ready.',
      timestamp: DateTime.now().toIso8601String(),
    );
    emit(
      state.copyWith(
        messages: [resetMsg],
        isStreaming: false,
        clearStreamingStatus: true,
      ),
    );
  }
}
