import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/appointment_model.dart';
import '../models/category_model.dart';
import '../models/owner_booking_model.dart';
import '../models/owner_dashboard_model.dart';
import '../models/owner_salon_model.dart';
import '../models/portfolio_model.dart';
import '../models/profile_model.dart';
import '../models/review_model.dart';
import '../models/salon_model.dart';
import '../models/waitlist_model.dart';
import '../models/working_hours_model.dart';
import '../models/service_catalog_model.dart';
import 'loomea_repository.dart';

class MockRepository implements LoomeeaRepository {
  Map<String, dynamic>? _cache;
  Profile? _profile;
  final List<Appointment> _extraAppointments = [];

  /// Force reload on next access (call after hot restart).
  void clearCache() => _cache = null;

  Future<Map<String, dynamic>> _loadData() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/mock_data.json');
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  @override
  Future<List<Salon>> getSalons() async {
    final data = await _loadData();
    return (data['salons'] as List)
        .map((s) => Salon.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Salon?> getSalonById(String id) async {
    final salons = await getSalons();
    return salons.where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<Salon?> getSalonByName(String name) async {
    final salons = await getSalons();
    return salons.where((s) => s.name == name).firstOrNull;
  }

  @override
  Future<List<Salon>> searchSalons(String query) async {
    final salons = await getSalons();
    if (query.isEmpty) return salons;
    final q = query.toLowerCase();
    return salons.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.tags.any((t) => t.toLowerCase().contains(q)) ||
          s.categories.any((c) => c.toLowerCase().contains(q)) ||
          s.services.any((svc) => svc.name.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Future<List<Salon>> searchAvailable({
    required String date,
    required String time,
    int durationMinutes = 60,
  }) async => getSalons();

  @override
  Future<List<Salon>> getSalonsByCategory(String category) async {
    final salons = await getSalons();
    final cat = category.toLowerCase();
    return salons.where((s) {
      return s.categories.any((c) => c.toLowerCase() == cat) ||
          s.tags.any((t) => t.toLowerCase().contains(cat)) ||
          s.services.any((svc) => svc.category.toLowerCase() == cat);
    }).toList();
  }

  @override
  Future<Profile> getProfile() async {
    if (_profile != null) return _profile!;
    final data = await _loadData();
    return Profile.fromJson(data['profile'] as Map<String, dynamic>);
  }

  /// Pick the client or owner mock profile based on the email used to log in.
  /// Any email containing "owner" signs in as the salon owner; anything else
  /// is treated as a client.
  Future<Profile> _profileForEmail(String email) async {
    final data = await _loadData();
    final isOwner = email.toLowerCase().contains('owner');
    final key = isOwner ? 'ownerProfile' : 'profile';
    return Profile.fromJson(data[key] as Map<String, dynamic>);
  }

  Future<List<Appointment>> getAppointments() async {
    final data = await _loadData();
    final fromJson = (data['appointments'] as List)
        .map((a) => Appointment.fromJson(a as Map<String, dynamic>))
        .toList();
    return [...fromJson, ..._extraAppointments];
  }

  @override
  Future<List<Appointment>> getUpcomingAppointments() async {
    final all = await getAppointments();
    return all.where((a) => a.isUpcoming).toList();
  }

  @override
  Future<List<Appointment>> getPastAppointments() async {
    final all = await getAppointments();
    return all.where((a) => a.isCompleted).toList();
  }

  @override
  Future<List<CatalogCategory>> getServiceCatalog() async => const [];

  @override
  Future<List<Category>> getCategories() async {
    final data = await _loadData();
    return (data['categories'] as List)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Salon>> getSavedSalons(List<String> salonIds) async {
    final salons = await getSalons();
    return salons.where((s) => salonIds.contains(s.id)).toList();
  }

  // ─── Stub implementations for LoomeeaRepository interface ────────────

  @override
  Future<PendingResult> registerPending({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String role = 'CLIENT',
  }) async {
    return PendingResult(
      email: email,
      role: role,
      message: 'Mock: verify your phone.',
    );
  }

  @override
  Future<void> sendOtp({required String email}) async {}

  @override
  Future<AuthResult> verifyEmail(
      {required String email, required String otp}) async {
    final profile = await _profileForEmail(email);
    _profile = profile;
    return AuthResult(accessToken: 'mock-access-token', user: profile);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final profile = await _profileForEmail(email);
    _profile = profile;
    return AuthResult(
      accessToken: 'mock-access-token',
      user: profile,
    );
  }

  @override
  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return ForgotPasswordResult(hint: 'u*****@example.com');
  }

  @override
  Future<bool> validateResetToken(String token) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  @override
  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return 'mock-access-token';
  }

  @override
  Future<void> logout() async {
    _profile = null;
  }

  @override
  Future<Profile> deleteAccount() async {
    final current = _profile ?? await getProfile();
    _profile = current.copyWith(
      scheduledDeletionAt: DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String(),
    );
    return _profile!;
  }

  @override
  Future<Profile> cancelDeletion() async {
    final current = _profile ?? await getProfile();
    _profile = current.copyWith(scheduledDeletionAt: null);
    return _profile!;
  }

  @override
  bool get isLoggedIn => true;

  @override
  Future<Profile> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final current = _profile ?? await getProfile();
    _profile = current.copyWith(
      fullName: fullName,
      phone: phone,
    );
    return _profile!;
  }

  @override
  Future<Profile> uploadAvatar(String base64Image) async =>
      _profile ?? await getProfile();

  @override
  Future<List<Salon>> getNearbySalons(double lat, double lng,
      {double radiusKm = 5.0}) async {
    return getSalons();
  }

  @override
  Future<Appointment> createBooking({
    required String salonId,
    required String date,
    required String startTime,
    required List<String> serviceIds,
    String? paymentMethod,
    String? notes,
  }) async {
    final salons = await getSalons();
    final salon = salons.firstWhere(
      (s) => s.id == salonId,
      orElse: () => salons.first,
    );
    final booked = salon.services
        .where((s) => serviceIds.contains(s.id))
        .toList();
    final totalDuration =
        booked.fold<int>(0, (sum, s) => sum + s.duration);
    final totalPrice =
        booked.fold<double>(0, (sum, s) => sum + s.price);
    final ms = DateTime.now().millisecondsSinceEpoch;
    final appointment = Appointment(
      id: 'mock-$ms',
      bookingId: 'BK-${ms.toString().substring(ms.toString().length - 6)}',
      salonId: salon.id,
      salonName: salon.name,
      serviceNames: booked.map((s) => s.name).toList(),
      date: date,
      time: startTime,
      endTime: _offsetTime(startTime, totalDuration),
      address: salon.fullAddress,
      status: 'confirmed',
      totalPrice: totalPrice,
      paymentMethod: paymentMethod ?? 'PAY_AT_SALON',
    );
    _extraAppointments.add(appointment);
    return appointment;
  }

  String _offsetTime(String timeStr, int addMinutes) {
    final parts = timeStr.split(' ');
    if (parts.length < 2) return timeStr;
    final hm = parts[0].split(':');
    var h = int.tryParse(hm[0]) ?? 0;
    var m = int.tryParse(hm.length > 1 ? hm[1] : '0') ?? 0;
    final isPm = parts[1].toUpperCase() == 'PM';
    if (isPm && h != 12) h += 12;
    if (!isPm && h == 12) h = 0;
    final total = h * 60 + m + addMinutes;
    var eh = (total ~/ 60) % 24;
    final em = total % 60;
    final ePm = eh >= 12;
    if (eh > 12) eh -= 12;
    if (eh == 0) eh = 12;
    return '$eh:${em.toString().padLeft(2, '0')} ${ePm ? 'PM' : 'AM'}';
  }

  @override
  Future<Appointment> rescheduleBooking({
    required String bookingId,
    required String date,
    required String startTime,
  }) async {
    return Appointment(
      id: bookingId,
      bookingId: bookingId,
      salonId: '',
      salonName: '',
      serviceNames: const [],
      date: date,
      time: startTime,
      endTime: startTime,
      address: '',
      status: 'confirmed',
      totalPrice: 0,
      paymentMethod: 'PAY_AT_SALON',
    );
  }

  @override
  Future<Appointment> cancelBooking(String bookingId) async {
    return Appointment(
      id: bookingId,
      bookingId: bookingId,
      salonId: '',
      salonName: '',
      serviceNames: const [],
      date: '',
      time: '',
      endTime: '',
      address: '',
      status: 'cancelled',
      totalPrice: 0,
      paymentMethod: 'PAY_AT_SALON',
    );
  }

  @override
  Future<Appointment> confirmAttendance(String bookingId) async {
    return Appointment(
      id: bookingId,
      bookingId: bookingId,
      salonId: '',
      salonName: '',
      serviceNames: const [],
      date: '',
      time: '',
      endTime: '',
      address: '',
      status: 'confirmed',
      totalPrice: 0,
      paymentMethod: 'PAY_AT_SALON',
      requiresClientConfirmation: true,
      clientConfirmedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<List<TimeSlot>> getAvailableSlots({
    required String salonId,
    required String date,
    int durationMinutes = 60,
  }) async {
    return List.generate(
      20,
      (i) => TimeSlot(
        time: '${9 + i ~/ 2}:${i.isEven ? "00" : "30"}',
        status: i < 16 ? 'AVAILABLE' : 'BOOKED',
      ),
    );
  }

  @override
  Future<void> saveSalon(String salonId) async {
    // Mock: no-op
  }

  @override
  Future<void> unsaveSalon(String salonId) async {
    // Mock: no-op
  }

  @override
  Future<List<Review>> getReviews(String salonId) async => [];

  @override
  Future<Review> createReview({required String salonId, required int rating, String? comment}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteReview(String reviewId) async {}

  @override
  Future<List<PortfolioPost>> getPortfolioPosts(String salonId) async => [];

  // ─── Owner mock implementations (read from mock_data.json) ───────────

  Future<List<OwnerBooking>> _ownerBookings() async {
    final data = await _loadData();
    return (data['ownerBookings'] as List? ?? [])
        .map((b) => OwnerBooking.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<OwnerSalon>> getOwnerSalons() async {
    final data = await _loadData();
    return (data['ownerSalons'] as List? ?? [])
        .map((s) => OwnerSalon.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OwnerSalon> getOwnerSalon(String salonId) async {
    final salons = await getOwnerSalons();
    return salons.firstWhere(
      (s) => s.id == salonId,
      orElse: () => salons.first,
    );
  }

  @override
  Future<OwnerSalon> createSalon(Map<String, dynamic> data) => throw UnimplementedError();
  @override
  Future<OwnerSalon> updateOwnerSalon(String salonId, Map<String, dynamic> data) => throw UnimplementedError();
  @override
  Future<void> deleteSalon(String salonId) async {}
  @override
  Future<OwnerSalon> addService(String salonId, Map<String, dynamic> data) => throw UnimplementedError();
  @override
  Future<OwnerSalon> updateService(String salonId, String serviceId, Map<String, dynamic> data) => throw UnimplementedError();
  @override
  Future<OwnerSalon> deleteService(String salonId, String serviceId) => throw UnimplementedError();

  @override
  Future<List<OwnerBooking>> getOwnerBookings(String salonId) async {
    final bookings = await _ownerBookings();
    return bookings.where((b) => b.salonId == salonId).toList();
  }

  @override
  Future<List<OwnerBooking>> getOwnerUpcomingBookings(String salonId) async {
    final bookings = await getOwnerBookings(salonId);
    return bookings.where((b) => b.isPending || b.isConfirmed).toList();
  }

  @override
  Future<List<OwnerBooking>> getOwnerPastBookings(String salonId) async {
    final bookings = await getOwnerBookings(salonId);
    return bookings.where((b) => b.isCompleted || b.isCancelled).toList();
  }

  @override
  Future<OwnerBooking> confirmBooking(String bookingId) => throw UnimplementedError();
  @override
  Future<OwnerBooking> completeBooking(String bookingId) => throw UnimplementedError();
  @override
  Future<OwnerBooking> rejectBooking(String bookingId, {required String reason}) => throw UnimplementedError();

  @override
  Future<Dashboard> getOwnerDashboard(String salonId) async {
    final data = await _loadData();
    return Dashboard.fromJson(data['dashboard'] as Map<String, dynamic>);
  }
  @override
  Future<List<PortfolioPost>> getOwnerPortfolioPosts(String salonId) async => [];
  @override
  Future<PortfolioPost> addPortfolioPost(String salonId, Map<String, dynamic> data) => throw UnimplementedError();
  @override
  Future<PortfolioPost> updateOwnerPortfolioPost(String salonId, String postId, Map<String, dynamic> data) => throw UnimplementedError();
  @override
  Future<void> deletePortfolioPost(String salonId, String postId) async {}
  @override
  Future<OwnerSalon> uploadSalonImage(String salonId, String base64Image) => throw UnimplementedError();

  Future<List<WaitlistEntry>> getMyWaitlist() async => [];

  @override
  Future<WaitlistEntry> joinWaitlist({required String salonId, required String date}) async =>
      WaitlistEntry(id: 'mock-w-1', salonId: salonId, salonName: 'Salon', date: date, status: 'WAITING', createdAt: DateTime.now().toIso8601String());

  @override
  Future<void> leaveWaitlist(String entryId) async {}

  @override
  Future<List<WorkingHoursModel>> getWorkingHours(String salonId) async =>
      WorkingHoursModel.defaultSchedule();

  @override
  Future<List<WorkingHoursModel>> saveWorkingHours(
      String salonId, List<WorkingHoursModel> hours) async => hours;

}
