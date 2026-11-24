# Project Notes

## Environment
- This sandbox has **no Flutter/Dart SDK installed** — `flutter analyze` / builds cannot run here. Validate Dart/Flutter changes by careful review only.
- The main app is a Flutter app in `infant_hearing_app/` (not the Next.js admin dashboard).

## Questionnaire (Baalshravya infant hearing)
- Question content lives in `infant_hearing_app/lib/features/questionnaire/models/questionnaire_data.dart`.
  It contains BOTH parent and ASHA worker question sets (Basic info B1–B3, Medical/family M1–M12, age-grouped Q1–Q4, Additional concerns A1–A3).
- Respondent selection: `QuestionnaireProvider.initialize(ageMonths, respondent: ...)` picks the right set.
  `QuestionnaireScreen` sets respondent from the `filledByAsha` route arg (true → ASHA worker, else parent).
- Note: `questionnaire_data.dart` has a large commented-out legacy block at the top (lines ~1–482); the active code starts around line 484. Don't be confused by it.
- The questionnaire's basic-information section (B1–B3) is unscored (`scored: false`); only M, Q, A sections contribute to the risk score.

## ASHA dashboard
- `AshaDashboardScreen` quick actions are wired: **Sync Data** calls `AshaProvider.refresh()`; **View All** opens `AshaAllScreeningsScreen` (route `ashaAllScreenings`); the **Emergency Referral** FAB opens `showEmergencyReferralSheet` (creates a `Referral` via `AshaProvider.createEmergencyReferral`).
- `AshaProvider.refresh()` re-fetches the profile only (data streams are live/auto-update). `createEmergencyReferral` writes to the `referrals` collection.
- ASHA worker question flow: Dashboard → pending infant → Start → `AshaInfantDetailScreen` → "Questionnaire (Phase 1)" pushes with `filledByAsha: true` + `infantId`.

## Referrals & follow-ups (role-based)
- **ASHA**: `AshaReferralManagementScreen` (route `ashaReferralManagement`, lists `AshaProvider.referrals`, updates status via `updateReferralStatus`) and `AshaFollowupsScreen` (route `ashaFollowups`, lists `provider.followups`, mark complete via `completeFollowup`, schedule via `scheduleFollowup`). Both reachable from the ASHA dashboard quick actions.
- **Parent**: `ParentReferralsScreen` (route `parentReferrals`) and `ParentFollowupsScreen` (route `parentFollowups`) read own baby's data via `ParentProvider.firestoreService.getReferralsForChild` / `getFollowupsForChild` (added to `AppFirestoreService`). Reachable from the parent home quick actions.
- Firestore `referrals` and `followups` collections are the source of truth; the parent screens use live streams.
