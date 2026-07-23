# Fix "Too Many Attempts" (Rate Limiting) Error

The "Too Many Attempts" (HTTP 429) error is caused by the app exceeding the server's request rate limits. This is primarily driven by aggressive polling and parallel data fetching.

## Root Cause Analysis
1.  **Chat Polling Frequency**: The app currently polls the chat data every **2 seconds**.
2.  **Redundant Requests**: Each poll to `getContactChatBoxData` triggers **two parallel API calls** (Sidebar/Metadata and Chat History).
3.  **Parallel Contact Fetching**: When loading the contact list, the app fetches 5 pages concurrently with a relatively short 1.2s delay between batches.
4.  **Cumulative Impact**: If a user is on a chat screen, they are making ~60 requests per minute just for that chat, plus background unread count polling and any ongoing contact list synchronization.

## Proposed Changes

### [Component] lib/ui/screens/chat/individual_chat_screen.dart

#### [MODIFY] [individual_chat_screen.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/ui/screens/chat/individual_chat_screen.dart)
- Increase the polling interval from **2 seconds** to **6 seconds**. This reduces the background request load by 66%.

### [Component] lib/features/contacts/presentation/providers/contact_provider.dart

#### [MODIFY] [contact_provider.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/presentation/providers/contact_provider.dart)
- Update `getContactChatBoxData` to accept a `pollOnly` parameter.
- When `pollOnly` is true, skip the metadata/sidebar request and only fetch the chat history.
- Increase the delay in `_fetchAllContactsParallel` from **1.2s** to **2.5s** to be more respectful of rate limits during bulk sync.
- Increase the global unread polling interval from **15s** to **45s**.

## Verification Plan

### Automated Tests
- I will verify that the number of requests fired in a 1-minute period is significantly reduced.

### Manual Verification
- Verify that the chat still feels responsive even with the 6-second polling interval (new messages still arrive automatically).
- Verify that the "Too Many Attempts" error no longer appears during normal usage.
