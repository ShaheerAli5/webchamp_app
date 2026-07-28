# Backend Coordination Required

Our diagnostics (enabled in Phase 3) have revealed exact validation and routing discrepancies. While we have implemented "Ultra-Compatibility" in the app, the backend developer **must** confirm several details to ensure stability.

## Message for Backend Developer

> "Hi, we are seeing the following discrepancies between the mobile app and the API:
>
> ### 1. Assign Labels
> - **Endpoint**: `POST /api/vendor/whatsapp/contact/chat/assign-labels`
> - **Error**: `422 Unprocessable Entity`
> - **Error Response**: `{"message":"The contact uid field is required.","errors":{"contactUid":["The contact uid field is required."]}}`
> - **What we are sending**: We are sending `contactUid` (camelCase) as a JSON key in the POST body.
> - **Question**: Why is it reported as missing? Does the API expect `x-www-form-urlencoded` instead of JSON? Or is the key name different?
>
> ### 2. Delete Label
> - **Endpoint**: `POST /api/vendor/whatsapp/contact/chat/delete-label/{uid}`
> - **Status**: `200 OK`
> - **Response Body**: `{"message":"nothing deleted"}`
> - **Question**: We are sending the UID in the URL. Does this endpoint also require `user_uid` or `vendor_uid` in the body for authorization? Is `POST` correct or should it be `DELETE` (Previous tries with `DELETE` gave 405).
>
> ### 3. Contact Group List
> - **Endpoints tried**: `/vendor/contact/groups`, `/vendor/contact/groups-data`, `/vendor/contact/group/list`.
> - **Result**: All return `404 Not Found`.
> - **Question**: What is the correct endpoint for fetching the list of contact groups?
>
> ### 4. General Payload
> - For endpoints like `create-label` and `create-contact`, does the API strictly require `snake_case` or `camelCase`? We see a mix of requirements in the validation errors."

## Implementation Changes (Phase 5)

We have added "Ultra-Compatibility" mode to the app:
1. **Assign Labels**: Now sends `contactUid`, `contact_uid`, AND `contactID` in the same payload to bypass any validation pickiness.
2. **Delete Label**: Now sends `user_uid` and `userUid` in the body along with the URL UID.
3. **Redundant User ID**: Every label/contact operation now sends both `user_uid` and `userUid`.

## Files Updated
- [contact_api_service.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/data/services/contact_api_service.dart)
- [contact_repository.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/data/repositories/contact_repository.dart)
- [contact_provider.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/presentation/providers/contact_provider.dart)
