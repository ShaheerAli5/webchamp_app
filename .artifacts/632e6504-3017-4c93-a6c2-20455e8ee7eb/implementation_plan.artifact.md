# Implementation Plan - Complete & Polished Label Management

We will finalize the Label Management system to ensure it meets 100% of the requirements provided, including cascading updates and a more intuitive menu structure.

## Key Enhancements

### 1. Robust Cascading Updates
- **Update Label**: When a label is updated (title/color), we will now ensure it updates immediately in:
    - The global list (`_allAvailableLabels`).
    - The currently active chat's assigned labels (`_labels`).
    - Every contact in the main list (`_contacts`) that has this label.
- **Delete Label**: When a label is deleted, it will be removed from:
    - The global list.
    - The currently active chat's assigned labels.
    - Every contact in the main list.

### 2. Chat Menu Alignment
- **Requirement**: Display "Create Label, Assign Label, Edit Label, Delete Label" in the menu.
- **Implementation**:
    - We will keep "Create" and "Assign" as direct actions.
    - We will rename "Manage Labels" to "Edit / Delete Labels" to better match the user's requested terminology.
    - We will ensure "Assign Labels" dialog also allows jumping to "Create" if the list is empty.

### 3. "No Refresh" UI Enforcement
- Ensure `notifyListeners()` is called at every step.
- Fix any potential "stale" data in the `_contacts` list by deep-mutating the label maps inside the contact objects.

### 4. Build & Install Troubleshooting
- **ADB Issue**: The `failed to install` error is usually caused by signature conflicts or stale build artifacts.
- **Action**: Provide instructions to the user to run `flutter clean` and manually uninstall the app.

---

## Proposed Changes

### Features - Contacts (Provider)

#### [MODIFY] [contact_provider.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/features/contacts/presentation/providers/contact_provider.dart)
- Update `updateLabel` to perform deep-updates on `_labels` and `_contacts`.
- Update `deleteLabel` to remove from `_labels`.
- Refine `_syncLabelsFromResponse` to also update `_labels` if matching UIDs are found.

### UI - Chat Screen

#### [MODIFY] [individual_chat_screen.dart](file:///C:/Users/muham/Documents/GitHub/webchamp_app/lib/ui/screens/chat/individual_chat_screen.dart)
- Align menu item titles with the requested requirements.
- Ensure the `_AssignedLabelsBar` uses the same color parsing logic as the rest of the app for consistency.

---

## Verification Plan

### Automated Steps
- **Build**: Ensure app compiles without "method not defined" or "constant expression" errors.

### Manual Verification (User)
1.  **Run `flutter clean` first.**
2.  **Edit Test**: Rename a label used in an open chat. Verify the chip at the top changes title instantly.
3.  **Delete Test**: Delete an assigned label. Verify it disappears from the chat top bar instantly.
4.  **Persistence**: Restart the app and verify all labels (global and assigned) are still there.
