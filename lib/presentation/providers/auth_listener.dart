import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'auth_state.dart';
import 'home_provider.dart';
import 'diet_plan_provider.dart';
import 'specialist_provider.dart';
import 'appointment_provider.dart';
import 'health_provider.dart';
import 'lab_reports_provider.dart';
import 'preferences_provider.dart';
import 'goal_provider.dart';
import 'phase_provider.dart';
import 'subscription_provider.dart';
import 'questionnaire_provider.dart';

final authStateListenerProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    final wasLoggedIn = previous?.status == AuthStatus.authenticated;
    final isLoggedIn = next.status == AuthStatus.authenticated;

    if (wasLoggedIn != isLoggedIn) {
      Future.microtask(() => clearAllProviders(ref));
    }
  });
});

void clearAllProviders(Ref ref) {
  ref.invalidate(homeDashboardProvider);
  ref.invalidate(dietPlanProvider);
  ref.invalidate(specialistListProvider);

  ref.invalidate(userAppointmentsProvider);
  ref.invalidate(timeSlotsProvider);
  ref.invalidate(appointmentDetailProvider);

  ref.invalidate(labReportsProvider);
  ref.invalidate(todayExerciseProvider);
  ref.invalidate(weeklyScheduleProvider);
  ref.invalidate(patientHabitHistoryListProvider);
  ref.invalidate(patientHabitHistoryProvider);

  ref.invalidate(goalListProvider);
  ref.invalidate(preferencesProvider);

  ref.invalidate(activePhaseProvider);
  ref.invalidate(phaseListProvider);
  ref.invalidate(weeklyViewProvider);
  ref.invalidate(phaseProgressProvider);
  ref.invalidate(activePhaseTaskProvider);

  ref.invalidate(subscriptionProvider);
  ref.invalidate(featureAccessProvider);

  ref.invalidate(fetchQuestionnaireProvider);
  ref.invalidate(questionnaireNotifierProvider);

  ref.invalidate(sessionDetailsProvider);
  ref.invalidate(startSessionProvider);
  ref.invalidate(completeSessionProvider);
  ref.invalidate(syncSessionProgressProvider);
  ref.invalidate(activeProgressProvider);

  ref.invalidate(labReportDetailsProvider);
  ref.invalidate(createLabRequestProvider);
}