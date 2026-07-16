# Fix Chat Screen Red Error After Sending Message

The issue is likely caused by a **duplicate key exception** in the `ListView.builder` of the chat screen. This happens due to a race condition between the optimistic UI update completion and the background polling for new messages.

## Root Cause Analysis
1.  **Optimistic Send**: When a user sends a message, a temporary "optimistic" message is added to the list with a `temp_` ID.
2.  **Background Polling**: While the message is being sent, a background polling timer might fetch the newly sent message from the server (with its real server ID) and add it to the list if the deduplication logic fails to match it with the `temp_` message.
3.  **Completion Race**: When the `sendMessage` call finishes, it updates the `temp_` message's ID to the real server ID.
4.  **Collision**: If step 2 already added the server message, we now have two messages with the same server ID in the list.
5.  **Crash**: The `ListView.builder` (and `VisibilityDetector`) in `IndividualChatScreen` uses these IDs as keys. Flutter throws a "Duplicate keys found" exception when it encounters two widgets with the same key, resulting in the red error screen.
6.  **Reopen Fix**: Reopening the chat fetches a fresh list from the server where duplicates are naturally removed/not present.

## Proposed Changes

### [Component] lib/features/contacts/presentation/providers/contact_provider.dart

#### [MODIFY] [contact_provider.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/presentation/providers/contact_provider.dart)
- Update `sendMessage` and `_sendMediaOptimistic` to check if the server ID returned by the API already exists in the message list before updating the optimistic message. If it exists, remove the optimistic message instead of updating it to avoid duplicate keys.
- Improve deduplication logic in `getContactChatBoxData` to better match optimistic messages with incoming server messages.

### [Component] lib/ui/screens/chat/individual_chat_screen.dart

#### [MODIFY] [individual_chat_screen.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/ui/screens/chat/individual_chat_screen.dart)
- Update `_buildMessagesList` to handle potential duplicate keys gracefully by ensuring the key passed to `ValueKey` and `VisibilityDetector` is unique, even if the underlying data has duplicates (e.g., by appending index if needed, though fixing the data layer is preferred).
- Replace `withValues` with `withOpacity` for broader compatibility and consistency across the app.

## Verification Plan

### Automated Tests
- I will verify the logic by ensuring that the `indexWhere` check correctly identifies existing messages before updating the list.

### Manual Verification
- The user should test sending messages under different network conditions (especially when polling is likely to trigger).
- Verify that the red screen no longer appears after a message is successfully sent.
- Verify that scrolling to the bottom still works as expected.
