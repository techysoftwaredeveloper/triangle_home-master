# Implement Suggestion Detail View Flow

On mobile devices (narrow mode), tapping a suggestion in the "Suggestions Hub" should navigate to a new detail screen instead of showing a side panel.

## Proposed Changes

### Admin Suggestions

#### [NEW] [suggestion_detail_screen.dart](file:///C:/Users/hitec/own/dev/triangle_home-master/lib/screens/admin/suggestion_detail_screen.dart)

- Create a new screen `SuggestionDetailScreen` that displays the full details of a suggestion.
- It will take `Map<String, dynamic> suggestion` and `AdminService adminService` as arguments.
- Replicate the UI from `SuggestionsTab._buildDetailPanel` but as a full-screen widget with a back button.
- Add status update functionality using `adminService.updateSuggestionStatus`.

#### [suggestions_tab.dart](file:///C:/Users/hitec/own/dev/triangle_home-master/lib/screens/admin/tabs/suggestions_tab.dart)

- Update `_SuggestionsTabState.build` to handle navigation:
    - In `_buildSuggestionsList`, the `onTap` for `_SuggestionCard` currently just sets `_selectedSuggestion`.
    - Modify `onTap` to check `widget.isNarrow`. If true, use `Navigator.push` to go to `SuggestionDetailScreen`.
- Ensure status updates in the detail screen trigger a refresh if needed (since it's a stream, it should happen automatically).

---

## Verification Plan

### Manual Verification
1. Open the "Suggestions Hub" in the admin panel (`AdminDashboardRedesign`).
2. Ensure the app is in mobile/narrow mode (resize browser or use emulator).
3. Click on a "Pending" suggestion.
4. Verify that it navigates to a new page showing complete details.
5. Verify that action buttons are present and functional (test "Mark as Contacted").
6. Verify that after an action, the status is updated and the user can navigate back.
7. Verify that on desktop (wide mode), the split-view behavior still works as before.
