import '../api/api_client.dart';
import '../models/appointment_model.dart';
import '../models/category_model.dart';
import '../models/owner_booking_model.dart';
import '../models/owner_dashboard_model.dart';
import '../models/owner_insights_model.dart';
import '../models/owner_salon_model.dart';
import '../models/payment_model.dart';
import '../models/portfolio_model.dart';
import '../models/profile_model.dart';
import '../models/review_model.dart';
import '../models/salon_model.dart';
import '../models/subscription_model.dart';
import '../models/service_model.dart';
import '../models/smart_search_model.dart';
import '../models/support_model.dart';
import '../models/waitlist_model.dart';
import '../models/working_hours_model.dart';
import '../models/service_catalog_model.dart';
import 'loomea_repository.dart';

/// Repository implementation that communicates with the Spring Boot backend.
class ApiRepository implements LoomeeaRepository {
  final ApiClient _client;

  ApiRepository({required ApiClient client}) : _client = client;

  // ─── Auth ────────────────────────────────────────────────────────────

  @override
  Future<PendingResult> registerPending({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String role = 'CLIENT',
  }) async {
    final response = await _client.post('/api/auth/register', body: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null) 'phone': phone,
    });
    final data = response['data'] as Map<String, dynamic>;
    return PendingResult(
      email: data['email'] as String? ?? email,
      role: data['role'] as String? ?? role,
      message: data['message'] as String? ?? '',
    );
  }

  @override
  Future<void> sendOtp({required String email}) async {
    await _client.post('/api/auth/request-otp', body: {
      'email': email,
    });
  }

  @override
  Future<AuthResult> verifyEmail(
      {required String email, required String otp}) async {
    final response = await _client.post('/api/auth/verify-email', body: {
      'email': email,
      'otp': otp,
    });
    final data = response['data'] as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final user = _mapUserToProfile(data['user'] as Map<String, dynamic>);
    await _client.setToken(accessToken);
    await _client.setUserRole(user.role);
    return AuthResult(accessToken: accessToken, user: user);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final response = await _client.post('/api/auth/login', body: {
      'email': email,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    if (data['accessToken'] == null) {
      throw EmailNotVerifiedException(
        email: data['email'] as String? ?? email,
      );
    }
    final accessToken = data['accessToken'] as String;
    final user = _mapUserToProfile(data['user'] as Map<String, dynamic>);
    await _client.setToken(accessToken);
    await _client.setUserRole(user.role);
    return AuthResult(accessToken: accessToken, user: user);
  }

  @override
  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    final response = await _client.post('/api/auth/forgot-password', body: {
      'email': email,
    });
    final data = response['data'] as Map<String, dynamic>;
    return ForgotPasswordResult(
      hint: data['hint'] as String? ?? '',
    );
  }

  @override
  Future<bool> validateResetToken(String token) async {
    final response = await _client.get(
      '/api/auth/validate-reset-token',
      queryParams: {'token': token},
    );
    final data = response['data'] as Map<String, dynamic>;
    return data['valid'] as bool? ?? false;
  }

  @override
  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _client.post('/api/auth/reset-password', body: {
      'resetToken':  resetToken,
      'newPassword': newPassword,
    });
    final data       = response['data'] as Map<String, dynamic>;
    final token      = data['accessToken'] as String;
    final user       = _mapUserToProfile(data['user'] as Map<String, dynamic>);
    await _client.setToken(token);
    await _client.setUserRole(user.role);
    return token;
  }

  @override
  Future<void> logout() async => _client.clearToken();

  @override
  Future<Profile> deleteAccount() async {
    final response = await _client.delete('/api/auth/me');
    return _mapUserToProfile(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Profile> cancelDeletion() async {
    final response = await _client.post('/api/auth/me/cancel-deletion');
    return _mapUserToProfile(response['data'] as Map<String, dynamic>);
  }

  @override
  bool get isLoggedIn => _client.isLoggedIn;

  // ─── Profile ─────────────────────────────────────────────────────────

  @override
  Future<Profile> getProfile() async {
    final response = await _client.get('/api/auth/me');
    return _mapUserToProfile(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Profile> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final response = await _client.put('/api/auth/me', body: {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    return _mapUserToProfile(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Profile> uploadAvatar(String base64Image) async {
    final response = await _client.put('/api/auth/me/avatar',
        body: {'imageData': base64Image});
    return _mapUserToProfile(response['data'] as Map<String, dynamic>);
  }

  // ─── Salons ──────────────────────────────────────────────────────────

  @override
  Future<List<Salon>> getSalons() async {
    final response = await _client.get('/api/salons');
    final data = response['data'] as List;
    return data.map((s) => _mapApiSalon(s as Map<String, dynamic>)).toList();
  }

  @override
  Future<Salon?> getSalonById(String id) async {
    try {
      final response = await _client.get('/api/salons/$id');
      return _mapApiSalon(response['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Salon?> getSalonByName(String name) async {
    try {
      final encoded = Uri.encodeComponent(name);
      final response = await _client.get('/api/salons/by-name/$encoded');
      return _mapApiSalon(response['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Salon>> searchSalons(String query) async {
    final response =
        await _client.get('/api/search', queryParams: {'q': query});
    final data = response['data'] as List;
    return data.map((s) => _mapApiSalon(s as Map<String, dynamic>)).toList();
  }

  @override
  Future<SmartSearchResult> smartSearch(String query) async {
    final response =
        await _client.get('/api/search/smart', queryParams: {'q': query});
    final data = response['data'] as Map<String, dynamic>;
    final filters = data['filters'] as Map<String, dynamic>?;
    return SmartSearchResult(
      salons: (data['salons'] as List? ?? [])
          .map((s) => _mapApiSalon(s as Map<String, dynamic>))
          .toList(),
      aiUsed: data['aiUsed'] as bool? ?? false,
      filters: filters == null ? null : SmartSearchFilters.fromJson(filters),
    );
  }

  @override
  Future<List<Salon>> searchAvailable({
    required String date,
    required String time,
    int durationMinutes = 60,
  }) async {
    final response = await _client.get('/api/search/available', queryParams: {
      'date': date,
      'time': time,
      'duration': durationMinutes.toString(),
    });
    final data = response['data'] as List;
    return data.map((s) => _mapApiSalon(s as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Salon>> getSalonsByCategory(String category) async {
    final encoded = Uri.encodeComponent(category);
    final response = await _client.get('/api/search/category/$encoded');
    final data = response['data'] as List;
    return data.map((s) => _mapApiSalon(s as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Salon>> getNearbySalons(double lat, double lng,
      {double radiusKm = 5.0}) async {
    final response = await _client.get('/api/salons/nearby', queryParams: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius': radiusKm.toString(),
    });
    final data = response['data'] as List;
    return data.map((s) => _mapApiSalon(s as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Salon>> getSavedSalons(List<String> salonIds) async {
    if (salonIds.isEmpty) return [];
    final all = await getSalons();
    return all.where((s) => salonIds.contains(s.id)).toList();
  }

  @override
  Future<void> saveSalon(String salonId) async {
    await _client.post('/api/auth/me/saved-salons/$salonId');
  }

  @override
  Future<void> unsaveSalon(String salonId) async {
    await _client.delete('/api/auth/me/saved-salons/$salonId');
  }

  // ─── Bookings ────────────────────────────────────────────────────────

  @override
  Future<List<Appointment>> getUpcomingAppointments() async {
    final response = await _client.get('/api/bookings/upcoming');
    final data = response['data'] as List;
    return data
        .map((a) => _mapApiAppointment(a as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Appointment>> getPastAppointments() async {
    final response = await _client.get('/api/bookings/past');
    final data = response['data'] as List;
    return data
        .map((a) => _mapApiAppointment(a as Map<String, dynamic>))
        .toList();
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
    final response = await _client.post('/api/bookings', body: {
      'salonId': salonId,
      'date': date,
      'startTime': startTime,
      'serviceIds': serviceIds,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (notes != null) 'notes': notes,
    });
    return _mapApiAppointment(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Appointment> rescheduleBooking({
    required String bookingId,
    required String date,
    required String startTime,
  }) async {
    final response =
        await _client.put('/api/bookings/$bookingId/reschedule', body: {
      'date': date,
      'startTime': startTime,
    });
    return _mapApiAppointment(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Appointment> cancelBooking(String bookingId) async {
    final response = await _client.put('/api/bookings/$bookingId/cancel');
    return _mapApiAppointment(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Appointment> confirmAttendance(String bookingId) async {
    final response =
        await _client.put('/api/bookings/$bookingId/confirm-attendance');
    return _mapApiAppointment(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<TimeSlot>> getAvailableSlots({
    required String salonId,
    required String date,
    int durationMinutes = 60,
  }) async {
    final response = await _client.get('/api/bookings/slots', queryParams: {
      'salonId': salonId,
      'date': date,
      'duration': durationMinutes.toString(),
    });
    final data = response['data'] as List;
    return data
        .map((s) => TimeSlot.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  // ─── Reviews ─────────────────────────────────────────────────────────

  @override
  Future<List<Review>> getReviews(String salonId) async {
    final response = await _client.get('/api/reviews/salon/$salonId');
    final data = response['data'] as List;
    return data
        .map((r) => Review.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Review> createReview({
    required String salonId,
    required int rating,
    String? comment,
  }) async {
    final response = await _client.post('/api/reviews', body: {
      'salonId': salonId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return Review.fromJson(
        (response['data'] as Map<String, dynamic>));
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _client.delete('/api/reviews/$reviewId');
  }

  // ─── Portfolio ───────────────────────────────────────────────────────

  /// Prepends the base URL to relative imageUrl paths returned by the backend
  /// (e.g. "/api/portfolio/{id}/image" → "http://server:8080/api/portfolio/{id}/image").
  Map<String, dynamic> _fixImageUrl(Map<String, dynamic> p) {
    final url = p['imageUrl'] as String? ?? '';
    if (url.startsWith('/')) {
      return {...p, 'imageUrl': '${_client.baseUrl}$url'};
    }
    return p;
  }

  @override
  Future<List<PortfolioPost>> getPortfolioPosts(String salonId) async {
    final response = await _client.get('/api/salons/$salonId/portfolio');
    final data = response['data'] as List;
    return data
        .map((p) => PortfolioPost.fromJson(_fixImageUrl(p as Map<String, dynamic>)))
        .toList();
  }

  // ─── Categories ──────────────────────────────────────────────────────

  @override
  Future<List<Category>> getCategories() async {
    return const [
      Category(name: 'Haircut', icon: 'content_cut'),
      Category(name: 'Nails', icon: 'brush'),
      Category(name: 'Massage', icon: 'spa'),
      Category(name: 'Shave', icon: 'face'),
      Category(name: 'Lashes', icon: 'visibility'),
    ];
  }

  @override
  Future<List<CatalogCategory>> getServiceCatalog() async {
    final response = await _client.get('/api/services/catalog');
    final data = response['data'] as List;
    return data
        .map((c) => CatalogCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ─── Owner: Salon CRUD ──────────────────────────────────────────────

  @override
  Future<List<OwnerSalon>> getOwnerSalons() async {
    final response = await _client.get('/api/owner/salons');
    final data = response['data'] as List;
    return data
        .map((s) => _parseOwnerSalon(s as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OwnerSalon> getOwnerSalon(String salonId) async {
    final response = await _client.get('/api/owner/salons/$salonId');
    return _parseOwnerSalon(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<OwnerSalon> createSalon(Map<String, dynamic> data) async {
    final response = await _client.post('/api/owner/salons', body: data);
    return _parseOwnerSalon(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<OwnerSalon> updateOwnerSalon(
      String salonId, Map<String, dynamic> data) async {
    final response =
        await _client.put('/api/owner/salons/$salonId', body: data);
    return _parseOwnerSalon(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteSalon(String salonId) async {
    await _client.delete('/api/owner/salons/$salonId');
  }

  // ─── Owner: Service CRUD ────────────────────────────────────────────

  @override
  Future<OwnerSalon> addService(
      String salonId, Map<String, dynamic> data) async {
    final response =
        await _client.post('/api/owner/salons/$salonId/services', body: data);
    return _parseOwnerSalon(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<OwnerSalon> updateService(
      String salonId, String serviceId, Map<String, dynamic> data) async {
    final response = await _client
        .put('/api/owner/salons/$salonId/services/$serviceId', body: data);
    return _parseOwnerSalon(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<OwnerSalon> deleteService(String salonId, String serviceId) async {
    final response = await _client
        .delete('/api/owner/salons/$salonId/services/$serviceId');
    return _parseOwnerSalon(response['data'] as Map<String, dynamic>);
  }

  // ─── Owner: Working Hours ───────────────────────────────────────────

  @override
  Future<List<WorkingHoursModel>> getWorkingHours(String salonId) async {
    final response =
        await _client.get('/api/owner/salons/$salonId/working-hours');
    final data = response['data'] as List;
    return data
        .map((e) => WorkingHoursModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WorkingHoursModel>> saveWorkingHours(
      String salonId, List<WorkingHoursModel> hours) async {
    final response = await _client.putList(
      '/api/owner/salons/$salonId/working-hours',
      hours.map((h) => h.toJson()).toList(),
    );
    final data = response['data'] as List;
    return data
        .map((e) => WorkingHoursModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Owner: Bookings ────────────────────────────────────────────────

  @override
  Future<List<OwnerBooking>> getOwnerBookings(String salonId) async {
    final response =
        await _client.get('/api/owner/salons/$salonId/bookings');
    return _parseOwnerBookings(response);
  }

  @override
  Future<List<OwnerBooking>> getOwnerUpcomingBookings(String salonId) async {
    final response =
        await _client.get('/api/owner/salons/$salonId/bookings/upcoming');
    return _parseOwnerBookings(response);
  }

  @override
  Future<List<OwnerBooking>> getOwnerPastBookings(String salonId) async {
    final response =
        await _client.get('/api/owner/salons/$salonId/bookings/past');
    return _parseOwnerBookings(response);
  }

  @override
  Future<OwnerBooking> confirmBooking(String bookingId) async {
    final response =
        await _client.put('/api/owner/bookings/$bookingId/confirm');
    return OwnerBooking.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<OwnerBooking> completeBooking(String bookingId) async {
    final response =
        await _client.put('/api/owner/bookings/$bookingId/complete');
    return OwnerBooking.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<OwnerBooking> rejectBooking(String bookingId, {required String reason}) async {
    final response = await _client.put(
      '/api/owner/bookings/$bookingId/reject',
      body: {'reason': reason},
    );
    return OwnerBooking.fromJson(response['data'] as Map<String, dynamic>);
  }


  // ─── Owner: Dashboard ───────────────────────────────────────────────

  @override
  Future<Dashboard> getOwnerDashboard(String salonId) async {
    final response =
        await _client.get('/api/owner/salons/$salonId/dashboard');
    return Dashboard.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<OwnerInsights> getOwnerInsights(String salonId, String language) async {
    final response = await _client.get('/api/owner/salons/$salonId/insights',
        queryParams: {'lang': language});
    return OwnerInsights.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<SupportReply> askSupport(
      List<SupportMessage> messages, String language) async {
    final response = await _client.post('/api/support/chat', body: {
      'language': language,
      'messages': messages.map((m) => m.toJson()).toList(),
    });
    return SupportReply.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ─── Owner: Portfolio ───────────────────────────────────────────────

  @override
  Future<List<PortfolioPost>> getOwnerPortfolioPosts(String salonId) async {
    final response =
        await _client.get('/api/owner/salons/$salonId/portfolio');
    final data = response['data'] as List;
    return data
        .map((p) => PortfolioPost.fromJson(_fixImageUrl(p as Map<String, dynamic>)))
        .toList();
  }

  @override
  Future<PortfolioPost> addPortfolioPost(
      String salonId, Map<String, dynamic> data) async {
    final response =
        await _client.post('/api/owner/salons/$salonId/portfolio', body: data);
    return PortfolioPost.fromJson(
        _fixImageUrl(response['data'] as Map<String, dynamic>));
  }

  @override
  Future<PortfolioPost> updateOwnerPortfolioPost(
      String salonId, String postId, Map<String, dynamic> data) async {
    final response = await _client.put(
        '/api/owner/salons/$salonId/portfolio/$postId',
        body: data);
    return PortfolioPost.fromJson(
        _fixImageUrl(response['data'] as Map<String, dynamic>));
  }

  @override
  Future<void> deletePortfolioPost(String salonId, String postId) async {
    await _client.delete('/api/owner/salons/$salonId/portfolio/$postId');
  }

  @override
  Future<OwnerSalon> uploadSalonImage(String salonId, String base64Image) async {
    final response = await _client.post(
      '/api/owner/salons/$salonId/image',
      body: {'imageData': base64Image},
    );
    return _parseOwnerSalon(response['data'] as Map<String, dynamic>);
  }

  // ─── Waitlist ────────────────────────────────────────────────────────────

  @override
  Future<List<WaitlistEntry>> getMyWaitlist() async {
    final response = await _client.get('/api/waitlist/my');
    final data = response['data'] as List;
    return data.map((e) => WaitlistEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<WaitlistEntry> joinWaitlist({required String salonId, required String date}) async {
    final response = await _client.post('/api/waitlist',
        body: {'salonId': salonId, 'date': date});
    return WaitlistEntry.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> leaveWaitlist(String entryId) async {
    await _client.delete('/api/waitlist/$entryId');
  }

  List<OwnerBooking> _parseOwnerBookings(Map<String, dynamic> response) {
    final data = response['data'] as List;
    return data
        .map((b) => OwnerBooking.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  // ─── Mappers ─────────────────────────────────────────────────────────

  Profile _mapUserToProfile(Map<String, dynamic> json) {
    final rawIds = json['savedSalonIds'] as List?;
    final savedIds = rawIds?.map((e) => e as String).toList() ?? const <String>[];
    return Profile(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      location: json['location'] as String? ?? '',
      role: json['role'] as String? ?? 'CLIENT',
      paymentMethods: const [],
      savedSalonIds: savedIds,
      reliabilityScore: json['reliabilityScore'] as int? ?? 100,
      reliabilityTier: json['reliabilityTier'] as String? ?? 'TRUSTED',
      scheduledDeletionAt: json['scheduledDeletionAt'] as String?,
    );
  }

  OwnerSalon _parseOwnerSalon(Map<String, dynamic> json) =>
      OwnerSalon.fromJson(_fixImageUrl(json));

  Salon _mapApiSalon(Map<String, dynamic> json) {
    json = _fixImageUrl(json);
    final services = (json['services'] as List? ?? [])
        .map((s) => _mapApiService(s as Map<String, dynamic>))
        .toList();

    final categories = services.map((s) => s.category).toSet().toList();

    return Salon(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      fullAddress: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      website: '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      distance: 0.0,
      isVerified: true,
      openTime: _parseOpenTime(json['openingHours'] as String?),
      closeTime: _parseCloseTime(json['openingHours'] as String?),
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      categories: categories,
      imageUrl: json['imageUrl'] as String? ?? '',
      services: services,
      reviews: const [],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Service _mapApiService(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      duration: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      icon: json['icon'] as String? ?? 'content_cut',
    );
  }

  // ─── Payments (Stripe Checkout) ──────────────────────────────────────

  @override
  Future<PaymentCheckout> startBookingPayment({
    required String salonId,
    required String date,
    required String startTime,
    required List<String> serviceIds,
    String? notes,
  }) async {
    final response = await _client.post('/api/payments/initiate', body: {
      'type': 'BOOKING',
      'salonId': salonId,
      'date': date,
      'startTime': startTime,
      'serviceIds': serviceIds,
      if (notes != null) 'notes': notes,
    });
    return PaymentCheckout.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<PaymentCheckout> startSubscriptionPayment(String plan) async {
    final response = await _client.post('/api/payments/initiate', body: {
      'type': 'SUBSCRIPTION',
      'plan': plan,
    });
    return PaymentCheckout.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<PaymentStatusInfo> getPaymentStatus(String paymentRef) async {
    final response = await _client.get('/api/payments/status/$paymentRef');
    return PaymentStatusInfo.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<PaymentStatusInfo> cancelPayment(String paymentRef) async {
    final response = await _client.post('/api/payments/$paymentRef/cancel');
    return PaymentStatusInfo.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<PaymentHistoryItem>> getPaymentHistory() async {
    final response = await _client.get('/api/payments/history');
    return (response['data'] as List? ?? [])
        .map((p) => PaymentHistoryItem.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  // ─── Owner: Subscription ──────────────────────────────────────────────

  @override
  Future<SubscriptionModel?> getSubscription() async {
    final response = await _client.get('/api/subscriptions/me');
    final data = response['data'];
    return data == null
        ? null
        : SubscriptionModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    final response = await _client.get('/api/subscriptions/plans');
    return (response['data'] as List? ?? [])
        .map((p) => SubscriptionPlanModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Appointment _mapApiAppointment(Map<String, dynamic> json) {
    final serviceNames = (json['services'] as List? ?? [])
        .map((s) =>
            (s as Map<String, dynamic>)['serviceName'] as String? ?? '')
        .toList();

    return Appointment(
      id: json['id'] as String? ?? '',
      bookingId: json['id'] as String? ?? '',
      salonId: json['salonId'] as String? ?? '',
      salonName: json['salonName'] as String? ?? '',
      salonImageUrl: json['salonImageUrl'] as String? ?? '',
      serviceNames: serviceNames,
      date: json['date'] as String? ?? '',
      time: _to12h(json['startTime'] as String? ?? ''),
      endTime: _to12h(json['endTime'] as String? ?? ''),
      address: json['salonAddress'] as String? ?? '',
      status: (json['status'] as String? ?? 'CONFIRMED').toLowerCase(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? 'PAY_AT_SALON',
      paymentStatus: json['paymentStatus'] as String?,
      requiresClientConfirmation:
          json['requiresClientConfirmation'] as bool? ?? false,
      clientConfirmedAt: json['clientConfirmedAt'] as String?,
    );
  }

  /// Converts "HH:mm" or "HH:mm:ss" (24h) → "h:mm AM/PM" for display.
  String _to12h(String t) {
    if (t.isEmpty) return t;
    final parts = t.split(':');
    var h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final isPm = h >= 12;
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:${m.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';
  }

  // --- Parse "Mon–Sat 9AM–8PM" style opening hours ---

  String _parseOpenTime(String? hours) {
    if (hours == null || hours.isEmpty) return '9:00';
    final match = RegExp(r'(\d{1,2})(AM|PM)').firstMatch(hours);
    if (match == null) return '9:00';
    int hour = int.parse(match.group(1)!);
    if (match.group(2) == 'PM' && hour != 12) hour += 12;
    return '$hour:00';
  }

  String _parseCloseTime(String? hours) {
    if (hours == null || hours.isEmpty) return '20:00';
    final matches = RegExp(r'(\d{1,2})(AM|PM)').allMatches(hours).toList();
    if (matches.length < 2) return '20:00';
    int hour = int.parse(matches[1].group(1)!);
    if (matches[1].group(2) == 'PM' && hour != 12) hour += 12;
    return '$hour:00';
  }
}
