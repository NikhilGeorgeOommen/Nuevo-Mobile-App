import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../data/models/appointment_model.dart';
import 'core_providers.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppointmentRepositoryImpl(apiClient);
});

/// Family key for time slots: (memberId, date)
typedef TimeSlotsKey = ({String memberId, String date});

final timeSlotsProvider =
    FutureProvider.family<TimeSlotResponse, TimeSlotsKey>((ref, key) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  final response =
      await repository.getTimeSlots(memberId: key.memberId, date: key.date);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message ?? 'Failed to fetch time slots');
});

/// Fetch appointment details by appointmentId
final appointmentDetailProvider =
    FutureProvider.family<AppointmentResponseData, String>(
        (ref, appointmentId) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  final response = await repository.getAppointmentById(appointmentId);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message ?? 'Failed to fetch appointment details');
});

/// Fetch all user appointments
final userAppointmentsProvider =
    FutureProvider<UserAppointmentsResponse>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  final response = await repository.getUserAppointments();
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message ?? 'Failed to fetch appointments');
});
