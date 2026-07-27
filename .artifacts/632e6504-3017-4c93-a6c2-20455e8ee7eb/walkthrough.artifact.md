# Label & Group API Fixes (Phase 4)

We have implemented Phase 4 of the API fixes, addressing the "picky" key naming and incorrect HTTP methods discovered in the logs.

## Key Fixes

### 1. Reverted Deletion to `POST`
- **Correction**: The backend explicitly stated that `DELETE` is not supported and `POST` is required for deleting labels, even though it's a destructive operation.
- **Action**: Switched `deleteLabel` and `deleteContactGroup` back to `POST`.

### 2. Resolved "The contact uid field is required" (Assign Labels)
- **Issue**: The API expected `contactUid` (camelCase) but was receiving `contact_uid` (snake_case).
- **Fix**: Updated `assignLabels` to send **both** `contactUid` and `contact_uid` for maximum compatibility.
- **Consistency**: Applied similar dual-key logic to `userUid`/`user_uid` and `labelUid`/`label_uid`.

### 3. Expanded Group Discovery
- **Issue**: Group fetching continues to 404.
- **Action**: Added a third guess to the group discovery chain.
    - Path 1: `/vendor/contact/groups-data` (Likely, following the `contacts-data` pattern)
    - Path 2: `/vendor/contact/groups`
    - Path 3: `/vendor/contact/group/list`
- **Result**: The app will now try all three automatically before giving up.

### 4. Payload Strengthening
- Updated `createContact`, `updateContact`, `createLabel`, and `updateLabel` to send redundant keys (`userUid` and `user_uid`) to satisfy different validation rules on the backend.

## Verified in Logs
- Duplicate Label detection is working (`eee` already taken).
- Authorization headers are correctly HIDDEN in logs for security.
- Full bodies are being logged to capture future validation errors.

## Files Modified
- [api_constants.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/core/network/api_constants.dart)
- [contact_api_service.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/data/services/contact_api_service.dart)
- [contact_repository.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/data/repositories/contact_repository.dart)
