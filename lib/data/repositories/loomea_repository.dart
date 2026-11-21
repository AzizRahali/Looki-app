import '../models/appointment_model.dart';
import '../models/waitlist_model.dart';
import '../models/category_model.dart';
import '../models/owner_booking_model.dart';
import '../models/owner_dashboard_model.dart';
import '../models/owner_insights_model.dart';
import '../models/owner_salon_model.dart';
import '../models/portfolio_model.dart';
import '../models/profile_model.dart';
import '../models/review_model.dart';
import '../models/salon_model.dart';
import '../models/smart_search_model.dart';
import '../models/support_model.dart';
import '../models/working_hours_model.dart';
import '../models/service_catalog_model.dart';

/// Abstract repository contract.
/// Both [MockRepository] and [ApiRepository] implement this.
abstract class LoomeeaRepository {
  // --- Auth ---

  /// Step 1: create account. Returns [PendingResult] — no JWT yet.
  Future<PendingResult> registerPending({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String role = 'CLIENT',
  });

  /// Step 2: send (or resend) OTP to email.
  Future<void> sendOtp({required String email});

  /// Step 3: verify email OTP → returns [AuthResult] with JWT.
  Future<AuthResult> verifyEmail({required String email, required String otp});

  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  });

  Future<void> logout();

  /// Schedule account for deletion (30-day grace period). Returns updated profile.
  Future<Profile> deleteAccount();

  /// Cancel a pending deletion. Returns updated profile.
  Future<Profile> cancelDeletion();

  /// Initiate password reset (email only). Returns [ForgotPasswordResult].
  Future<ForgotPasswordResult> forgotPassword({required String email});

  /// Validate an email reset token (from deep link). Returns true if still valid.
  Future<bool> validateResetToken(String token);

  /// Set a new password with a valid reset token. Returns the new access token.
  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  bool get isLoggedIn;

  // --- Profile ---
  Future<Profile> getProfile();

  Future<Profile> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  });

  Future<Profile> uploadAvatar(String base64Image);

  // --- Salons ---
  Future<List<Salon>> getSalons();

  Future<Salon?> getSalonById(String id);

  Future<Salon?> getSalonByName(String name);

  Future<List<Salon>> searchSalons(String query);

  /// Natural-language search; the backend may fall back to keyword search.
  Future<SmartSearchResult> smartSearch(String query);

  Future<List<Salon>> searchAvailable({
    required String date,
    required String time,
    int durationMinutes = 60,
  });

  Future<List<Salon>> getSalonsByCategory(String category);

  Future<List<Salon>> getNearbySalons(double lat, double lng,
      {double radiusKm = 5.0});

  Future<List<Salon>> getSavedSalons(List<String> salonIds);

  Future<void> saveSalon(String salonId);

  Future<void> unsaveSalon(String salonId);

  // --- Bookings ---
  Future<List<Appointment>> getUpcomingAppointments();

  Future<List<Appointment>> getPastAppointments();

  Future<Appointment> createBooking({
    required String salonId,
    required String date,
    required String startTime,
    required List<String> serviceIds,
    String? paymentMethod,
    String? notes,
  });

  Future<Appointment> rescheduleBooking({
    required String bookingId,
    required String date,
    required String startTime,
  });

  Future<Appointment> cancelBooking(String bookingId);

  /// Confirm attendance for a risky-tier appointment.
  Future<Appointment> confirmAttendance(String bookingId);

  Future<List<TimeSlot>> getAvailableSlots({
    required String salonId,
    required String date,
    int durationMinutes = 60,
  });

  // --- Categories ---
  Future<List<Category>> getCategories();
  Future<List<CatalogCategory>> getServiceCatalog();

  // --- Reviews ---
  Future<List<Review>> getReviews(String salonId);
  Future<Review> createReview({required String salonId, required int rating, String? comment});
  Future<void> deleteReview(String reviewId);

  // --- Portfolio ---
  Future<List<PortfolioPost>> getPortfolioPosts(String salonId);

  // ─── Owner: Salon CRUD ──────────────────────────────────────────────
  Future<List<OwnerSalon>> getOwnerSalons();
  Future<OwnerSalon> getOwnerSalon(String salonId);
  Future<OwnerSalon> createSalon(Map<String, dynamic> data);
  Future<OwnerSalon> updateOwnerSalon(String salonId, Map<String, dynamic> data);
  Future<void> deleteSalon(String salonId);

  // ─── Owner: Service CRUD ────────────────────────────────────────────
  Future<OwnerSalon> addService(String salonId, Map<String, dynamic> data);
  Future<OwnerSalon> updateService(String salonId, String serviceId, Map<String, dynamic> data);
  Future<OwnerSalon> deleteService(String salonId, String serviceId);

  // ─── Owner: Bookings ────────────────────────────────────────────────
  Future<List<OwnerBooking>> getOwnerBookings(String salonId);
  Future<List<OwnerBooking>> getOwnerUpcomingBookings(String salonId);
  Future<List<OwnerBooking>> getOwnerPastBookings(String salonId);
  Future<OwnerBooking> confirmBooking(String bookingId);
  Future<OwnerBooking> completeBooking(String bookingId);
  Future<OwnerBooking> rejectBooking(String bookingId, {required String reason});

  // ─── Owner: Dashboard ───────────────────────────────────────────────
  Future<Dashboard> getOwnerDashboard(String salonId);

  /// Business insights for the last 28 days; [language] is the app locale.
  Future<OwnerInsights> getOwnerInsights(String salonId, String language);

  // ─── Support assistant ─────────────────────────────────────────────
  /// Sends the conversation so far (last message from the user) to the AI
  /// support assistant; [language] is the app locale.
  Future<SupportReply> askSupport(List<SupportMessage> messages, String language);

  // ─── Owner: Portfolio ───────────────────────────────────────────────
  Future<List<PortfolioPost>> getOwnerPortfolioPosts(String salonId);
  Future<PortfolioPost> addPortfolioPost(String salonId, Map<String, dynamic> data);
  Future<PortfolioPost> updateOwnerPortfolioPost(String salonId, String postId, Map<String, dynamic> data);
  Future<void> deletePortfolioPost(String salonId, String postId);
  Future<OwnerSalon> uploadSalonImage(String salonId, String base64Image);

  // ─── Owner: Working Hours ───────────────────────────────────────────
  Future<List<WorkingHoursModel>> getWorkingHours(String salonId);
  Future<List<WorkingHoursModel>> saveWorkingHours(String salonId, List<WorkingHoursModel> hours);

  // ─── Waitlist ────────────────────────────────────────────────────────────
  Future<List<WaitlistEntry>> getMyWaitlist();
  Future<WaitlistEntry> joinWaitlist({required String salonId, required String date});
  Future<void> leaveWaitlist(String entryId);


}

/// Result of forgotPassword — masked email hint for the UI.
class ForgotPasswordResult {
  final String hint;

  const ForgotPasswordResult({this.hint = ''});
}

/// Auth result returned by login/verifyEmail.
class AuthResult {
  final String accessToken;
  final Profile user;

  const AuthResult({
    required this.accessToken,
    required this.user,
  });
}

/// Pending result returned by registerPending (no JWT).
class PendingResult {
  final String email;
  final String role;
  final String message;

  const PendingResult({
    required this.email,
    required this.role,
    required this.message,
  });
}

/// Thrown when login succeeds but the email is not yet verified.
/// The backend has already sent a fresh OTP.
class EmailNotVerifiedException implements Exception {
  final String email;
  const EmailNotVerifiedException({required this.email});

  @override
  String toString() => 'Email not verified';
}

/// Time slot availability.
class TimeSlot {
  final String time;
  final String status; // AVAILABLE, LIMITED, BOOKED

  const TimeSlot({required this.time, required this.status});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time'] as String? ?? '',
      status: json['status'] as String? ?? 'AVAILABLE',
    );
  }
}
