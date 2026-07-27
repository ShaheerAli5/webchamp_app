# Label & Group API Fixes (Phase 2)

Fix remaining issues with Label Management (Create/Edit/Assign) and Group List (404).

## User Review Required

> [!IMPORTANT]
> - **Label ID Extraction**: We will add more keys (`label_id`, `id`) and ensure they are parsed robustly to prevent empty UIDs which cause 405 errors.
> - **Payload Consistency**: We will inject `user_uid` into Label CRUD operations, consistent with the Contact API fix.
> - **Group Endpoint**: We will test a corrected endpoint for contact groups (`/vendor/contact/groups`) to resolve the 404.

## Proposed Changes

### Core Models

#### [MODIFY] [label_model.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/data/models/label_model.dart)
- Update `fromJson` to include `label_id`.
- Ensure all IDs are trimmed and cast to String correctly.

### Data Layer

#### [MODIFY] [contact_api_service.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/data/services/contact_api_service.dart)
- Add `user_uid` to `createLabel` and `updateLabel`.
- Try changing payload key for `assignLabels` if 422 persists (will add more logging first).

#### [MODIFY] [contact_repository.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/data/repositories/contact_repository.dart)
- Pass `user_uid` through to API service for labels.
- Enhance `_extractError` to log the full response body for 422/405/404 errors to help debugging.

#### [MODIFY] [api_constants.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/core/network/api_constants.dart)
- Update `contactGroupsList` and `groups` to `/vendor/contact/groups`.

### Presentation Layer

#### [MODIFY] [contact_provider.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/presentation/providers/contact_provider.dart)
- **Local State Management**:
    - Update `createLabel` to add the newly created label to `_allAvailableLabels` immediately.
    - Update `updateLabel` to refresh the local item.
- **Delete Guard**: Prevent API call if `labelUid` is empty and show a descriptive error.
- **Payload Injection**: Pass `_activeUserUid` to all label CRUD methods.

## Verification Plan

### Manual Verification
1. **Create Label**: Verify label is created and appears in the list instantly.
2. **Delete Label**: Ensure 405 error is gone by verifying UID is passed in URL.
3. **Assign Label**: Check if 422 persists with new payload structure.
4. **Group List**: Verify 404 is resolved.

## Backend Message (to be sent if issues persist)
"Hi, we are seeing some issues with the following endpoints:
1. `POST /vendor/whatsapp/contact/chat/assign-labels`: Returning 422. We are sending `{contact_uid: string, labels: string[]}`. Please confirm the expected payload structure.
2. `POST /vendor/whatsapp/contact/chat/delete-label/{label_uid}`: Returning 405 when called with a valid UID. Please verify the allowed methods.
3. `GET /vendor/groups`: Returning 404. Is this the correct endpoint for fetching contact groups? or is it `/vendor/contact/groups`?"
