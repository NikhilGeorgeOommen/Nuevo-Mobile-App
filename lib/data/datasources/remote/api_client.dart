import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/api_response.dart';
import '../../models/auth_response_model.dart';
import '../../models/user_model.dart';
import '../../models/subscription_model.dart';
import '../../models/lab_request_model.dart';
import '../../models/lab_report_model.dart';
import '../../models/diet_plan_model.dart';
import '../../models/preferences_model.dart';
import '../../models/daily_exercise_model.dart';
import '../../models/weekly_schedule_model.dart';
import '../../models/session_progress_model.dart';
import '../../models/active_progress_model.dart';
import '../../models/specialist_model.dart';
import '../../models/payment_integration_models.dart';
import '../../models/billing_response_model.dart';
import '../../models/goal_model.dart';
import '../../models/phase_model.dart';
import '../../models/appointment_model.dart';
import '../../../domain/models/health/patient_habit_history.dart';

import 'package:dio/dio.dart';

/// API Client (Data Layer)
/// Handles all API calls using Dio directly (Manual Implementation of RestClient interface)
class ApiClient {
  final DioClient _dioClient;
  
  ApiClient({required DioClient dioClient}) : _dioClient = dioClient;
  
  // ============================================
  // Authentication Endpoints
  // ============================================
  
  /// Send OTP
  Future<ApiResponse<void>> sendOtp(SendOtpRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.generateOtp,
      data: request.toJson(),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => null,
    );
  }

  /// Verify OTP
  Future<ApiResponse<AuthResponseData>> verifyOtp(VerifyOtpRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.loginOtp,
      data: request.toJson(),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => AuthResponseData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Login with email and password (Legacy / Alternative)
  Future<ApiResponse<AuthResponseData>> login(LoginRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.login,
      data: request.toJson(),
    );
    
    return ApiResponse.fromJson(
      response.data, 
      (json) => AuthResponseData.fromJson(json as Map<String, dynamic>),
    );
  }
  
  /// Sign up new user
  Future<ApiResponse<AuthResponseData>> register(RegisterRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.register,
      data: request.toJson(),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => AuthResponseData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Google Sign-In backend verification
  Future<ApiResponse<AuthResponseData>> googleLogin(String token) async {
    final response = await _dioClient.post(
      ApiConstants.googleLogin,
      data: {'token': token},
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => AuthResponseData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Apple Sign-In backend verification
  Future<ApiResponse<AuthResponseData>> appleLogin({
    required String token,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final Map<String, dynamic> data = {'token': token};
    
    // Only add these fields if they are non-null and not empty strings
    if (firstName != null && firstName.isNotEmpty) data['firstName'] = firstName;
    if (lastName != null && lastName.isNotEmpty) data['lastName'] = lastName;
    // According to the document, Apple SDK returns empty strings or null on subsequent logins, 
    // we should safely pass them or omit them entirely.
    if (email != null && email.isNotEmpty) data['email'] = email;

    final response = await _dioClient.post(
      ApiConstants.appleLogin,
      data: data,
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => AuthResponseData.fromJson(json as Map<String, dynamic>),
    );
  }
  
  /// Logout current user
  Future<ApiResponse<void>> logout() async {
    // Assuming client-side only or API call if exists
    return const ApiResponse(success: true, message: 'Logged out locally');
  }
  
  /// Forgot Password
  Future<ApiResponse<void>> forgotPassword(ForgotPasswordRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.forgotPassword,
      data: request.toJson(),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => null,
    );
  }
  
  /// Resend Reset Code
  Future<ApiResponse<void>> resendResetCode(ForgotPasswordRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.resendResetCode,
      data: request.toJson(),
    );
     return ApiResponse.fromJson(
      response.data,
      (json) => null,
    );
  }
  
  /// Verify Reset Code
  Future<ApiResponse<void>> verifyResetCode(VerifyResetCodeRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.verifyResetCode,
      data: request.toJson(),
    );
     return ApiResponse.fromJson(
      response.data,
      (json) => null,
    );
  }
  
  /// Reset Password
  Future<ApiResponse<void>> resetPassword(ResetPasswordRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.resetPassword,
      data: request.toJson(),
    );
     return ApiResponse.fromJson(
      response.data,
      (json) => null,
    );
  }

  // ============================================
  // User Endpoints
  // ============================================
  
  /// Get current user profile
  Future<ApiResponse<UserModel>> getUserProfile() async {
    final response = await _dioClient.get(ApiConstants.userProfile);
    return ApiResponse.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }
  
  /// Update user profile
  Future<ApiResponse<UserModel>> updateProfile(dynamic data) async {
     final response = await _dioClient.patch(
       ApiConstants.updateProfile,
       data: data,
    );
     return ApiResponse.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Check Email
  Future<ApiResponse<void>> checkEmail(String email) async {
    final response = await _dioClient.get(
      ApiConstants.checkEmail,
      queryParameters: {'email': email},
    );
     return ApiResponse.fromJson(
      response.data,
      (json) => null,
    );
  }

  /// Update user preferences (Notification & Consent)
  Future<ApiResponse<PreferencesModel>> updatePreferences(
      PreferencesModel preferences) async {
    final response = await _dioClient.put(
      ApiConstants.preferences,
      data: preferences.toJson(),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => PreferencesModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get user preferences
  Future<ApiResponse<PreferencesModel>> getPreferences() async {
    final response = await _dioClient.get(ApiConstants.preferences);
    return ApiResponse.fromJson(
      response.data,
      (json) => PreferencesModel.fromJson(json as Map<String, dynamic>),
    );
  }
  
  // ============================================
  // Subscription Endpoints
  // ============================================
  
  Future<SubscriptionModel> getSubscriptionStatus() async {
    throw UnimplementedError("Use getUserProfile() instead");
  }
  
  Future<SubscriptionModel> getSubscriptionDetails() async {
     throw UnimplementedError("Use getUserProfile() instead");
  }
  
  // ============================================
  // Lab Requests Endpoints
  // ============================================

  /// Create Lab Request
  Future<ApiResponse<LabRequestData>> createLabRequest(
      CreateLabRequest request) async {
    final response = await _dioClient.post(
      ApiConstants.labRequests,
      data: request.toJson(),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => LabRequestData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Lab Requests List
  Future<ApiResponse<LabRequestListResponseData>> getLabRequests() async {
    final response = await _dioClient.get(ApiConstants.labRequests);
    return ApiResponse.fromJson(
      response.data,
      (json) =>
          LabRequestListResponseData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Lab Request By ID
  Future<ApiResponse<LabRequestData>> getLabRequestById(String id) async {
    final response = await _dioClient.get('${ApiConstants.labRequests}/$id');
    return ApiResponse.fromJson(
      response.data,
      (json) => LabRequestData.fromJson(json as Map<String, dynamic>),
    );
  }

  // ============================================
  // Lab Reports Endpoints
  // ============================================

  /// Get Lab Reports List
  Future<ApiResponse<LabReportListData>> getLabReports() async {
    final response = await _dioClient.get(ApiConstants.labReports);
    return ApiResponse.fromJson(
      response.data,
      (json) =>
          LabReportListData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Lab Report Details / Comparison
  Future<ApiResponse<LabReportDetailData>> getLabReportDetails(String id) async {
    final response = await _dioClient.get('${ApiConstants.labReports}/$id');
    
    return ApiResponse.fromJson(
      response.data,
      (json) => LabReportDetailData.fromJson(json as Map<String, dynamic>),
    );
  }

  // ============================================
  // Health Metrics / Habits Endpoints
  // ============================================

  /// Get Patient Habits History
  Future<ApiResponse<List<PatientHabitHistory>>> getPatientHabitHistory(String date) async {
    final response = await _dioClient.get(
      '${ApiConstants.patientHabits}/$date',
    );
    
    return ApiResponse.fromJson(
      response.data,
      (json) {
        if (json is List) {
          return json.map((e) => PatientHabitHistory.fromJson(e as Map<String, dynamic>)).toList();
        } else if (json is Map<String, dynamic>) {
          return [PatientHabitHistory.fromJson(json)];
        }
        return <PatientHabitHistory>[];
      },
    );
  }
  /// Get All Patient Habits History
  Future<ApiResponse<List<PatientHabitHistory>>> getPatientHabitHistoryAll() async {
    final response = await _dioClient.get(ApiConstants.patientHabitsHistory);
    
    return ApiResponse.fromJson(
      response.data,
      (json) {
        if (json is List) {
          return json.map((e) => PatientHabitHistory.fromJson(e as Map<String, dynamic>)).toList();
        } else if (json is Map<String, dynamic>) {
          if (json.containsKey('data') && json['data'] is List) {
            return (json['data'] as List).map((e) => PatientHabitHistory.fromJson(e as Map<String, dynamic>)).toList();
          }
          return [PatientHabitHistory.fromJson(json)];
        }
        return <PatientHabitHistory>[];
      },
    );
  }

  /// Save Patient Habits History
  Future<ApiResponse<PatientHabitHistory>> savePatientHabitHistory(PatientHabitHistory data) async {
    final response = await _dioClient.post(
      ApiConstants.patientHabits,
      data: data.toJson(),
    );
    
    return ApiResponse.fromJson(
      response.data,
      (json) => PatientHabitHistory.fromJson(json as Map<String, dynamic>),
    );
  }

  // Add other methods (Programs, Bookings) as needed if they were in the previous attempt
  // For brevity and to fix the immediate error, ensuring register/login/updateProfile exist.
  
  // ============================================
  // Appointment/Booking Endpoints
  // ============================================

  /// Get Time Slots for a specific care-team member
  /// GET /specialist-timeslots/care-team/{member_id}?date=YYYY-MM-DD
  Future<ApiResponse<TimeSlotResponse>> getTimeSlots({
    required String memberId,
    required String date,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.specialistTimeSlots}/care-team/$memberId',
      queryParameters: {'date': date},
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => TimeSlotResponse.fromJson(response.data as Map<String, dynamic>),
    );
  }

  /// Book appointment with a specific care-team member
  /// POST /specialist-timeslots/care-team/{member_id}/book
  Future<ApiResponse<AppointmentResponseData>> bookAppointment({
    required String memberId,
    required String startTime,
    String? notes,
  }) async {
    final response = await _dioClient.post(
      '${ApiConstants.specialistTimeSlots}/care-team/$memberId/book',
      data: BookAppointmentRequest(startTime: startTime, notes: notes).toJson(),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => AppointmentResponseData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get appointment details by ID
  /// GET /specialist-timeslots/appointments/{appointment_id}
  Future<ApiResponse<AppointmentResponseData>> getAppointmentById(
      String appointmentId) async {
    final response = await _dioClient.get(
      '${ApiConstants.specialistTimeSlots}/appointments/$appointmentId',
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => AppointmentResponseData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Update Appointment
  Future<ApiResponse<AppointmentResponseData>> updateAppointment(
      String bookingId, UpdateAppointmentRequest request) async {
    final response = await _dioClient.patch(
      '${ApiConstants.createAppointment}/$bookingId',
      data: request.toJson(),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => AppointmentResponseData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Cancel Appointment
  Future<ApiResponse<CancelAppointmentResponseData>> cancelAppointment(
      String bookingId) async {
    final response = await _dioClient.delete('${ApiConstants.bookings}/$bookingId');
    return ApiResponse.fromJson(
      response.data,
      (json) =>
          CancelAppointmentResponseData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get all user appointments
  /// GET /bookings/appointments/all
  Future<ApiResponse<UserAppointmentsResponse>> getUserAppointments() async {
    final response = await _dioClient.get(ApiConstants.allAppointments);
    return ApiResponse.fromJson(
      response.data,
      (json) =>
          UserAppointmentsResponse.fromJson(json as Map<String, dynamic>),
    );
  }
  
  // ============================================
  // Goal Endpoints
  // ============================================

  /// Get All Goals
  Future<ApiResponse<List<GoalModel>>> getGoals() async {
    final response = await _dioClient.get(ApiConstants.goals);
    return ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map((item) => GoalModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Create Goal
  Future<ApiResponse<GoalModel>> createGoal(Map<String, dynamic> data) async {
    final response = await _dioClient.post(
      ApiConstants.goals,
      data: data,
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => GoalModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Goal By ID
  Future<ApiResponse<GoalModel>> getGoalById(String id) async {
    final response = await _dioClient.get('${ApiConstants.goals}/$id');
    return ApiResponse.fromJson(
      response.data,
      (json) => GoalModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Update Goal
  Future<ApiResponse<GoalModel>> updateGoal(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put(
      '${ApiConstants.goals}/$id',
      data: data,
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => GoalModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Delete Goal
  Future<ApiResponse<void>> deleteGoal(String id) async {
    final response = await _dioClient.delete('${ApiConstants.goals}/$id');
    return ApiResponse.fromJson(
      response.data,
      (json) => null,
    );
  }

  // ============================================
  // Phase Endpoints
  // ============================================

  /// Get All Phases
  Future<ApiResponse<List<PhaseModel>>> getPhases() async {
    final response = await _dioClient.get(ApiConstants.phases);
    return ApiResponse.fromJson(
      response.data,
      (json) => (json as List<dynamic>)
          .map((item) => PhaseModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get Phase By ID — GET /phases/{phaseId}
  Future<ApiResponse<PhaseModel>> getPhaseById(String phaseId) async {
    final response = await _dioClient.get('${ApiConstants.phases}/$phaseId');
    return ApiResponse.fromJson(
      response.data,
      (json) => PhaseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get My Active Phase — GET /phases/my-active-phase
  Future<ApiResponse<ActivePhaseResponseModel>> getMyActivePhase() async {
    final response = await _dioClient.get(ApiConstants.myActivePhase);
    return ApiResponse.fromJson(
      response.data,
      (json) =>
          ActivePhaseResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Current Weekly View — GET /phases/my-active-phase/weekly
  Future<ApiResponse<WeeklyViewModel>> getCurrentWeeklyView() async {
    final response = await _dioClient.get(ApiConstants.myActivePhaseWeekly);
    return ApiResponse.fromJson(
      response.data,
      (json) => WeeklyViewModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Phase Progress — GET /phases/my-active-phase/progress
  Future<ApiResponse<PhaseProgressModel>> getPhaseProgress() async {
    final response = await _dioClient.get(ApiConstants.myActivePhaseProgress);
    return ApiResponse.fromJson(
      response.data,
      (json) => PhaseProgressModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Week View By Number — GET /phases/my-active-phase/weeks/{weekNumber}
  Future<ApiResponse<WeeklyViewModel>> getWeekByNumber(int weekNumber) async {
    final response = await _dioClient
        .get('${ApiConstants.myActivePhase}/weeks/$weekNumber');
    return ApiResponse.fromJson(
      response.data,
      (json) => WeeklyViewModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Task By ID — GET /phases/my-active-phase/tasks/{taskId}
  Future<ApiResponse<PatientTaskModel>> getTaskById(String taskId) async {
    final response =
        await _dioClient.get('${ApiConstants.myActivePhaseTasks}/$taskId');
    return ApiResponse.fromJson(
      response.data,
      (json) => PatientTaskModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Mark Task Completed — PATCH /phases/my-active-phase/tasks/{taskId}/complete
  // Future<ApiResponse<PatientTaskModel>> markTaskCompleted(
  //     String taskId) async {
  //   final response = await _dioClient
  //       .patch('${ApiConstants.myActivePhaseTasks}/$taskId/complete');
  //   return ApiResponse.fromJson(
  //     response.data,
  //     (json) => PatientTaskModel.fromJson(json as Map<String, dynamic>),
  //   );
  // }

  /// Update Task Status — PATCH /phases/my-active-phase/tasks/{taskId}/status
  Future<ApiResponse<PatientTaskModel>> updateTaskStatus(
      String taskId, String statusValue) async {
    final response = await _dioClient.patch(
      '${ApiConstants.myActivePhaseTasks}/$taskId/status',
      data: UpdateTaskStatusRequest(statusValue: statusValue).toJson(),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => PatientTaskModel.fromJson(json as Map<String, dynamic>),
    );
  }

  // ============================================
  // Diet Plan Endpoints
  // ============================================

  /// Get Diet Plan
  Future<ApiResponse<DietPlanModel>> getDietPlan() async {
    final response = await _dioClient.get(ApiConstants.dietPlans);
    
    return ApiResponse.fromJson(
      response.data,
      (json) => DietPlanModel.fromJson(json as Map<String, dynamic>),
    );
  }

  // ============================================
  // Guided Sessions Endpoints
  // ============================================

  /// Get Today's Exercise
  Future<ApiResponse<DailyExerciseModel>> getTodayExercise() async {
    final response = await _dioClient.get(ApiConstants.todayExercise);
    


    return ApiResponse.fromJson(
      response.data,
      (json) => DailyExerciseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Weekly Schedule
  Future<ApiResponse<WeeklyScheduleModel>> getWeeklySchedule() async {
    final response = await _dioClient.get(ApiConstants.weeklySchedule);
    return ApiResponse.fromJson(
      response.data,
      (json) => WeeklyScheduleModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Session Details
  Future<ApiResponse<GuidedSessionModel>> getSessionDetails(String id) async {
    final response = await _dioClient.get('${ApiConstants.sessionDetails}/$id');
    return ApiResponse.fromJson(
      response.data,
      (json) => GuidedSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Start Session
  Future<ApiResponse<SessionProgressModel>> startSession(String id) async {
    final response = await _dioClient.post('${ApiConstants.sessionDetails}/$id${ApiConstants.sessionStart}');
    return ApiResponse.fromJson(
      response.data,
      (json) => SessionProgressModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Complete Session
  Future<ApiResponse<SessionProgressModel>> completeSession(String id) async {
    final response = await _dioClient.post('${ApiConstants.sessionDetails}/$id${ApiConstants.sessionComplete}');
    return ApiResponse.fromJson(
      response.data,
      (json) => SessionProgressModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Sync Session Progress
  Future<ApiResponse<SessionProgressModel?>> syncSessionProgress(String id, Map<String, dynamic> data) async {
    // Note: The backend expects a PATCH request for updating progress
    final response = await _dioClient.patch(
      '${ApiConstants.sessionDetails}/$id${ApiConstants.sessionProgressUpdate}',
      data: data,
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => json == null ? null : SessionProgressModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Active Progress
  Future<ApiResponse<ActiveProgressModel?>> getActiveProgress() async {
    try {
      final response = await _dioClient.get(ApiConstants.sessionActiveProgress);
      return ApiResponse.fromJson(
        response.data,
        (json) => ActiveProgressModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is DioException) {
         if (e.response?.statusCode == 404) {
            // Assume 404 means no active session, return a successful response with null data
            return ApiResponse(success: true, message: 'No active session', data: null);
         }
      }
      rethrow;
    }
  }

  // ============================================
  // Specialist Endpoints
  // ============================================

  /// Get My Specialists
  Future<ApiResponse<List<SpecialistModel>>> getMySpecialists() async {
  final response = await _dioClient.get(ApiConstants.mySpecialists);

  return ApiResponse.fromJson(
    response.data,
    (json) {
      if (json is! Map<String, dynamic>) return [];

      final careTeam = json['careTeam'] as List<dynamic>? ?? [];

      return careTeam
          .map((item) => SpecialistModel.fromJson(item as Map<String, dynamic>))
          .toList();
    },
  );
}

  /// Get Specialist Details
  Future<ApiResponse<SpecialistModel>> getSpecialistDetails(String id) async {
    final response = await _dioClient.get('${ApiConstants.specialistDetails}/$id');
    return ApiResponse.fromJson(
      response.data,
      (json) => SpecialistModel.fromJson(json as Map<String, dynamic>),
    );
  }

  // ============================================
  // Payment & Subscription Endpoints
  // ============================================

  /// Get Payway Subscription Details
  Future<ApiResponse<SubscriptionPaywayDetails>> getSubscriptionPaywayDetails() async {
    final response = await _dioClient.get(ApiConstants.subscriptionPaywayDetails);
    return ApiResponse.fromJson(
      response.data,
      (json) => SubscriptionPaywayDetails.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Saved Cards (Payment Customer)
  Future<ApiResponse<PaymentCustomerDetails>> getSavedCards() async {
    final response = await _dioClient.get(ApiConstants.paymentCustomer);
    return ApiResponse.fromJson(
      response.data,
      (json) => PaymentCustomerDetails.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Tokenize Card
  Future<ApiResponse<SingleUseTokenResponse>> tokenizeCard(
      Map<String, dynamic> cardDetails) async {
    // API Expects URL-encoded form data
    final response = await _dioClient.post(
      ApiConstants.paymentToken,
      data: cardDetails,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => SingleUseTokenResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Save Card
  Future<ApiResponse<SaveCardResponse>> saveCard(
      String singleUseTokenId) async {
    final response = await _dioClient.post(
      ApiConstants.paymentSaveCard,
      data: {'singleUseTokenId': singleUseTokenId},
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => SaveCardResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get Billing Details (Subscription, Cards, History)
  Future<ApiResponse<BillingResponseData>> getBillingDetails() async {
    final response = await _dioClient.get(ApiConstants.billingDetails);
    return ApiResponse.fromJson(
      response.data,
      (json) => BillingResponseData.fromJson(json as Map<String, dynamic>),
    );
  }

  // ============================================
  // Questionnaire Endpoints
  // ============================================

  /// Get Questionnaire By ID
  Future<ApiResponse<dynamic>> getQuestionnaire(String id) async {
    final response = await _dioClient.get('${ApiConstants.questionnaires}/$id');
    return ApiResponse.fromJson(
      response.data,
      (json) => json, // We map this to the domain entity in the repository
    );
  }

  /// Submit Questionnaire Responses
  Future<ApiResponse<dynamic>> submitQuestionnaire(
      String patientTaskId, List<Map<String, dynamic>> responses) async {
    final response = await _dioClient.post(
      '${ApiConstants.questionnaires}/submit/$patientTaskId',
      data: {'responses': responses},
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => json, 
    );
  }
}