/// API Configuration Constants
/// IMPORTANT: Update these with actual backend URLs before deployment
class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://nuevo-medical-be.simelabs.in/api/v1';
  
  // Endpoints
  // Auth
  static const String myActivePhaseTasks = '/phases/my-active-phase/tasks';
  static const String myActivePhase = '/phases/my-active-phase';
  static const String myActivePhaseWeekly = '/phases/my-active-phase/weekly';
  static const String myActivePhaseProgress = '/phases/my-active-phase/progress';
  static const String login = '/auth/login';
  static const String generateOtp = '/auth/generate-otp';
  static const String loginOtp = '/auth/login-otp';
  static const String register = '/auth/register';
  static const String googleLogin = '/auth/register-or-login-google';
  static const String appleLogin = '/auth/register-or-login-apple';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resendResetCode = '/auth/resend-reset-code';
  static const String verifyResetCode = '/auth/verify-reset-code';
  static const String resetPassword = '/auth/reset-password';
  static const String userProfile = '/auth/profile';
  static const String checkEmail = '/auth/check-email';
  static const String updateProfile = '/auth/profile'; // Typically PUT or PATCH on profile endpoint
  static const String preferences = '/preferences';
  
  // Programs
  static const String programs = '/programs';
  // Note: For dynamic IDs, we'll use string interpolation in the client
  
  // Bookings
  static const String bookings = '/bookings';
  static const String timeSlots = '/timeslots/day'; // legacy, kept for reference
  static const String createAppointment = '/bookings'; // legacy, kept for reference
  static const String specialistTimeSlots = '/specialist-timeslots';
  static const String allAppointments = '/bookings/appointments/all';
  
  // Payments
  static const String paymentCustomer = '/payments/customer';
  static const String paymentToken = '/payments/token';
  static const String paymentSaveCard = '/payments/save-card';
  static const String billingDetails = '/mobile/billing';
  
  // Subscriptions (Using existing constants if they map to Programs/Bookings, 
  // but keeping placeholders if not explicitly in the Postman subset provided)
  static const String subscriptionStatus = '/subscription/status'; // To be verified
  static const String subscriptionDetails = '/subscription/details'; // To be verified
  static const String subscriptionPaywayDetails = '/subscriptions/payway-details';
  
  // Video Consultations
  static const String appointments = '/bookings'; // Mapping appointments to bookings
  static const String scheduleAppointment = '/bookings';
  static const String agoraToken = '/video/token'; // To be verified with backend
  
  // Health
  static const String healthMetrics = '/health/metrics';
  static const String labResults = '/health/lab-results';
  static const String wellnessData = '/health/wellness';
  static const String labReports = '/lab-reports';  // Added integrated lab reports API endpoint
  static const String labRequests = '/lab-requests';
  static const String dietPlans = '/diet-plans';
  static const String patientHabits = '/patient-habits';
  static const String patientHabitsHistory = '/patient-habits/history';

  // Goals
  static const String goals = '/goals';

  // Specialists
  static const String mySpecialists = '/care-team/my-care-team';
  static const String specialistDetails = '/patients/specialists';
  
  // Guided Sessions
  static const String todayExercise = '/guided-sessions/today';
  static const String weeklySchedule = '/guided-sessions/weekly-schedule';
  static const String sessionDetails = '/guided-sessions'; // Base for /guided-sessions/{id}
  static const String sessionStart = '/start'; // Base for /guided-sessions/{id}/start
  static const String sessionComplete = '/complete'; // Base for /guided-sessions/{id}/complete
  static const String sessionProgressUpdate = '/progress'; // Base for /guided-sessions/{id}/progress
  static const String sessionActiveProgress = '/guided-sessions/active-progress';
  
  // Support
  static const String contactSupport = '/support/contact';

  // Home
  static const String home = '/mobile/home';
  
  // Phases
  static const String phases = '/phases';
  
  // Questionnaires
  static const String questionnaires = '/questionnaires';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}

/// Storage Keys for Secure Storage and SharedPreferences
class StorageKeys {
  // Secure Storage (for sensitive data)
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  
  // SharedPreferences (for non-sensitive data)
  static const String isFirstLaunch = 'is_first_launch';
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String lastSyncTime = 'last_sync_time';
  
  // HIPAA/GDPR Compliance: No PII in SharedPreferences
  // All health data and personal info must use Secure Storage
}

/// Feature Names (for subscription-based access control)
class FeatureNames {
  static const String videoConsultations = 'video_consultations';
  static const String wellnessReset = 'wellness_reset';
  static const String healthTracking = 'health_tracking';
  static const String labResults = 'lab_results';
  static const String exerciseVideos = 'exercise_videos';
  static const String dietTracking = 'diet_tracking';
}

/// Agora Configuration (Video Calling)
class AgoraConstants {
  // TODO: Replace with actual Agora App ID from dashboard
  static const String appId = 'YOUR_AGORA_APP_ID';
  
  // Channel naming convention (compatible with React.js web)
  // Format: "medical_consultation_{appointmentId}"
  static String getChannelName(String appointmentId) {
    return 'medical_consultation_$appointmentId';
  }
  
  // UID generation strategy (ensure uniqueness across platforms)
  static int generateUid(String userId) {
    // Use hash of userId to ensure consistency
    return userId.hashCode.abs();
  }
}

/// Error Messages
class ErrorMessages {
  // Network Errors
  static const String noInternet = 'No internet connection. Please check your network.';
  static const String serverError = 'Server error. Please try again later.';
  static const String serviceUnavailable = 'The service is currently unavailable. Please try again later.';
  static const String timeout = 'Request timeout. Please try again.';
  
  // Auth Errors
  static const String invalidCredentials = 'Invalid email or password.';
  static const String sessionExpired = 'Your session has expired. Please login again.';
  static const String unauthorized = 'You are not authorized to access this resource.';
  
  // Subscription Errors
  static const String subscriptionInactive = 'Your subscription is inactive. Please contact support to activate your plan.';
  static const String featureLocked = 'This feature is not available in your current plan.';
  
  // Video Call Errors
  static const String cameraPermissionDenied = 'Camera permission is required for video calls.';
  static const String microphonePermissionDenied = 'Microphone permission is required for video calls.';
  static const String videoCallFailed = 'Failed to connect to video call. Please try again.';
  
  // Generic
  static const String somethingWentWrong = 'Something went wrong. Please try again.';
}

/// Success Messages
class SuccessMessages {
  static const String loginSuccess = 'Login successful!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String appointmentScheduled = 'Appointment scheduled successfully!';
  static const String dataSync = 'Data synced successfully!';
}

/// Validation Constants
class ValidationConstants {
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // Email regex pattern
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  // Password must contain: uppercase, lowercase, number, special char
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
  );
}

/// App Configuration
class AppConfig {
  static const String appName = 'Medical Care';
  static const String appVersion = '1.0.0';
  
  // Support Contact (for inactive subscriptions)
  static const String supportEmail = 'support@yourmedicalapp.com';
  static const String supportPhone = '+1-800-MEDICAL';
  
  // CRITICAL: Apple Policy Compliance
  // This app is a companion tool for PHYSICAL MEDICAL SERVICES
  // Subscription covers real-world doctor consultations and clinical care
  // Digital content is supplementary to physical medical treatment
  static const String appDescription = 
    'Companion app for medical consultation services. '
    'Access your care team, schedule video consultations with doctors, '
    'and track your health metrics as part of your medical treatment plan.';
}
