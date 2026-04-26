import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ChatState, () {
    test('canSend is true only when ready and no response in flight', () {
      expect(ChatState(status: ChatStatus.ready).canSend, isTrue);
      expect(ChatState(status: ChatStatus.connecting).canSend, isFalse);
      expect(
        ChatState(status: ChatStatus.ready, awaitingResponse: true).canSend,
        isFalse,
      );
      expect(
        ChatState(status: ChatStatus.ready, streamingMessageId: '0').canSend,
        isFalse,
      );
    });

    test('isResponseInFlight reflects awaiting + streaming', () {
      expect(ChatState().isResponseInFlight, isFalse);
      expect(ChatState(awaitingResponse: true).isResponseInFlight, isTrue);
      expect(
        ChatState(streamingMessageId: '0').isResponseInFlight,
        isTrue,
      );
    });

    test('copyWith honors clear flags', () {
      final seeded = ChatState(
        streamingMessageId: '1',
        transientError: ChatTransientError.sendFailed,
      );
      expect(
        seeded.copyWith(clearStreamingMessageId: true).streamingMessageId,
        isNull,
      );
      expect(
        seeded.copyWith(clearTransientError: true).transientError,
        isNull,
      );
    });
  });
}
