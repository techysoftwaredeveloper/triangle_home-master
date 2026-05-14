# Implementation Plan - Profile Screen Design Update

This plan outlines the changes to bring the Profile screen in alignment with the high-fidelity design provided in the attachment.

## User Review Required

- **Avatar Styling**: The design uses a specific pink background for the avatar placeholder. I will implement this for users without profile images.
- **Phone Number Visibility**: I will ensure the phone number is displayed prominently below the name, matching the "Guest User" scenario.

## Proposed Changes

### [Profile Screen]

#### [profile_screen.dart](file:///C:/Users/hitec/own/dev/triangle_home-master/lib/screens/profile/profile_screen.dart)
- **Header Refinement**:
    - Update `_buildProfileHeader` to use a fixed pink background for the avatar placeholder when no image is present.
    - Set the avatar text (initial) to be large and dark gray.
    - Ensure the "Edit" button matches the specific blue in the design.
    - Update typography: Name in `font2XL` bold white, phone number in `fontMD` white/80%.
- **List Item Refinement**:
    - Update `_buildSection` to match the exact padding and card radii of the design.
    - Standardize the `leading` icon container to use a very light blue/lavender tint (`Color(0xFFF1F5F9)` or `primaryColor.withOpacity(0.05)`).
    - Match the horizontal dividers' indent to the design image (starting from the text, not the icon).
- **Navigation Logic**:
    - Preserve existing navigation but ensure the icons match the design precisely (e.g., `notifications_none_rounded` for Notifications).

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax errors.

### Manual Verification
1.  **UI Comparison**: Side-by-side comparison of the implemented screen with the provided image.
2.  **State Check**: Verify the UI handles both logged-in users with data and guest users correctly.
3.  **Responsiveness**: Ensure the layout scales well on different screen sizes.
