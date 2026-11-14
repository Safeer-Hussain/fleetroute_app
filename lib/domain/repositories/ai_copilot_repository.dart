import '../entities/ai_chat_message.dart';

abstract class AiCopilotRepository {
  Future<List<AiChatMessage>> getConversationHistory();
  Future<void> saveMessage(AiChatMessage message);
  Stream<String> streamCopilotResponse(String prompt);
}
