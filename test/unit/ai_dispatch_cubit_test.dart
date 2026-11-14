import 'package:fleetroute_app/domain/entities/ai_chat_message.dart';
import 'package:fleetroute_app/domain/repositories/ai_copilot_repository.dart';
import 'package:fleetroute_app/presentation/ai_copilot/cubit/ai_dispatch_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAiCopilotRepository implements AiCopilotRepository {
  List<AiChatMessage> history = [];

  @override
  Future<List<AiChatMessage>> getConversationHistory() async => history;

  @override
  Future<void> saveMessage(AiChatMessage message) async {
    history.add(message);
  }

  @override
  Stream<String> streamCopilotResponse(String prompt) async* {
    yield 'FleetRoute';
    yield ' Telematics';
    yield ' Operational.';
  }
}

class FaultyAiCopilotRepository implements AiCopilotRepository {
  @override
  Future<List<AiChatMessage>> getConversationHistory() async => [];

  @override
  Future<void> saveMessage(AiChatMessage message) async {}

  @override
  Stream<String> streamCopilotResponse(String prompt) async* {
    yield 'Initiating';
    throw Exception('Simulated network disruption during stream');
  }
}

void main() {
  group('AiDispatchCubit Unit Tests', () {
    test('Test 13: Streams AI copilot response tokens smoothly', () async {
      final repo = MockAiCopilotRepository();
      final cubit = AiDispatchCubit(aiRepository: repo);

      await cubit.sendMessage('Audit Vehicles With Active OBD-II Faults');

      expect(cubit.state.isStreaming, false);
      expect(cubit.state.messages.length, 2);
      expect(cubit.state.messages.first.role, 'user');
      expect(cubit.state.messages.last.role, 'assistant');
      expect(
        cubit.state.messages.last.content,
        'FleetRoute Telematics Operational.',
      );

      await cubit.close();
    });

    test('Test 14: Verifies isStreaming strictly resets to false in finally block even on error', () async {
      final faultyRepo = FaultyAiCopilotRepository();
      final cubit = AiDispatchCubit(aiRepository: faultyRepo);

      await cubit.sendMessage('Simulate Error');

      // Crucial test rule: isStreaming must be false regardless of stream exceptions!
      expect(cubit.state.isStreaming, false);
      expect(cubit.state.streamingStatus, null);
      expect(cubit.state.messages.last.isStreaming, false);

      await cubit.close();
    });

    test(
      'Test 15: clearConversation resets messages to default initial greeting',
      () async {
        final repo = MockAiCopilotRepository();
        final cubit = AiDispatchCubit(aiRepository: repo);

        await cubit.sendMessage('Test prompt');
        expect(cubit.state.messages.length, 2);

        await cubit.clearConversation();
        expect(cubit.state.messages.length, 1);
        expect(cubit.state.messages.first.role, 'assistant');
        expect(cubit.state.isStreaming, false);

        await cubit.close();
      },
    );
  });
}
