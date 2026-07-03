---
phase: 1
title: Avatar Upload
status: completed
priority: P3
dependencies: []
---

# Phase 1: Avatar Upload

## Overview
Let a customer pick and upload a profile photo in the edit-profile screen; the
uploaded URL is saved to `profiles.avatar_url` and reflected everywhere the
avatar shows. No model or bloc changes — reuse the existing update path.

## Requirements
- Functional: tap avatar in edit-profile → pick from gallery → upload → save →
  avatar updates in profile header and edit screen.
- Non-functional: disable Save while uploading; show error inline; no orphaned
  UI on failure (keep old avatar).

## Architecture
`UserModel.avatarUrl` is already in `copyWith` + `toMap('avatar_url')`, and
`AuthService.updateProfile(user)` already writes `toMap()`. So the only work is
in `edit_profile_screen.dart`: pick image (`image_picker`, already a dep), upload
bytes via the existing `ProductService.uploadProductImage(fileName, bytes, mime)`
helper, put the returned URL into `copyWith(avatarUrl:)`, and dispatch the
existing `UpdateProfileEvent`. RLS already allows `auth.uid()=id` UPDATE on
`profiles`. Reuse the `products` storage bucket (KISS).

## Related Code Files
- Modify: `FE/lib/screens/profile/edit_profile_screen.dart`
  - Wrap the display-only `CircleAvatar` (lines ~74-86) in a `GestureDetector`/
    `Stack` with a camera edit badge.
  - Add State: `XFile? _pickedAvatar; bool _uploadingAvatar = false; String? _avatarUrl;`.
  - In `_save()` (lines ~125-139): if a new image was picked, upload first
    (await `ProductService().uploadProductImage`), then
    `currentUser.copyWith(fullName, phone, address, avatarUrl: _avatarUrl)`.
- Reuse (no change): `FE/lib/services/product_service.dart` `uploadProductImage`.
  - Optional (nice-to-have, DRY): add a `String bucket = 'products'` param so an
    `avatars` bucket could be used later — not required this phase.
- No change: `models/user_model.dart`, `blocs/auth/*`, `services/auth_service.dart`.

## Implementation Steps
1. Import `package:image_picker/image_picker.dart` in edit-profile screen.
2. Add avatar State fields + a `_pickAvatar()` that calls
   `ImagePicker().pickImage(source: ImageSource.gallery)`, stores `XFile`, and
   shows a local preview (`Image.file`/`FileImage`) over the network avatar.
3. Wrap `CircleAvatar` in `GestureDetector(onTap: _uploadingAvatar ? null : _pickAvatar)`
   with a small edit badge (match manager create-product image-picker UX).
4. In `_save()`: guard `_saving`; if `_pickedAvatar != null`, set
   `_uploadingAvatar=true`, read bytes, call `uploadProductImage(<uuid>.jpg, bytes,
   'image/jpeg')`; on null return show error and abort save; on success set
   `_avatarUrl`.
5. Build `updated = currentUser.copyWith(..., avatarUrl: _avatarUrl ?? currentUser.avatarUrl)`
   and dispatch `UpdateProfileEvent(updated)` (existing listener handles success/pop).
6. Disable the Save button while `_saving || _uploadingAvatar`.

## Success Criteria
- [ ] Picking + saving updates `profiles.avatar_url` (verify row in DB).
- [ ] Profile header + edit screen show the new avatar after save.
- [ ] Save disabled during upload; upload failure keeps old avatar + shows error.
- [ ] `flutter analyze` clean.

## Risk Assessment
- Upload uses user JWT to the `products` bucket (already works for manager) —
  low risk. Mitigation: reuse the exact call the manager screen uses.
- Large images: acceptable for demo; optionally pass `imageQuality`/`maxWidth`
  to `pickImage` to cap size.
