import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/owner_booking_model.dart';

@pragma('vm:entry-point')
void _onNotificationTap(NotificationResponse response) {
  NotificationService.instance._handleTap(response.payload);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<String?>.broadcast();

  Stream<String?> get onTap => _tapController.stream;

  static const _bookingChannel = AndroidNotificationDetails(
    'loomea_bookings',
    'Booking Updates',
    channelDescription: 'Alerts for booking status changes',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  static const _newBookingChannel = AndroidNotificationDetails(
    'loomea_new_bookings',
    'New Bookings',
    channelDescription: 'Alerts for incoming salon bookings',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  static const _reviewChannel = AndroidNotificationDetails(
    'loomea_reviews',
    'New Reviews',
    channelDescription: 'Alerts for new salon reviews',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _reminderChannel = AndroidNotificationDetails(
    'loomea_reminders',
    'Appointment Reminders',
    channelDescription: 'Reminders 1 hour before your appointments',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showNewBooking(OwnerBooking booking) async {
    await _plugin.show(
      booking.id.hashCode & 0x7FFFFFFF,
      'New Booking!',
      '${booking.servicesText} · ${booking.timeRange}',
      const NotificationDetails(android: _newBookingChannel, iOS: _iosDetails),
      payload: 'bookings',
    );
  }

  Future<void> showBookingStatusChange(String salonName, String newStatus) async {
    final (title, body) = switch (newStatus.toUpperCase()) {
      'CONFIRMED' => ('Booking Confirmed ✓', 'Your appointment at $salonName has been confirmed'),
      'CANCELLED' => ('Booking Cancelled', 'Your appointment at $salonName was cancelled'),
      'COMPLETED' => ('Appointment Completed', 'Hope you enjoyed your visit at $salonName!'),
      'PENDING'   => ('Reschedule Requested', 'Your reschedule request at $salonName is pending approval'),
      _           => ('Booking Update', 'Your booking at $salonName has been updated'),
    };
    await _plugin.show(
      salonName.hashCode & 0x7FFFFFFF,
      title,
      body,
      const NotificationDetails(android: _bookingChannel, iOS: _iosDetails),
      payload: 'bookings',
    );
  }

  Future<void> showRescheduledByClient(String clientName, String timeRange) async {
    await _plugin.show(
      clientName.hashCode & 0x7FFFFFFF,
      'Reschedule Request',
      '$clientName wants to reschedule · $timeRange',
      const NotificationDetails(android: _newBookingChannel, iOS: _iosDetails),
      payload: 'bookings',
    );
  }

  Future<void> showWaitlistAvailable(String salonName, String date) async {
    await _plugin.show(
      'waitlist_$salonName'.hashCode & 0x7FFFFFFF,
      'Slot Available!',
      'A slot opened up at $salonName on $date — book now!',
      const NotificationDetails(android: _reminderChannel, iOS: _iosDetails),
      payload: 'bookings',
    );
  }

  Future<void> showBookingReminder(String salonName, String time) async {
    await _plugin.show(
      'reminder_$salonName'.hashCode & 0x7FFFFFFF,
      'Upcoming Appointment',
      'Your appointment at $salonName starts at $time',
      const NotificationDetails(android: _reminderChannel, iOS: _iosDetails),
      payload: 'bookings',
    );
  }

  Future<void> showNewReview(String reviewerName, double rating) async {
    await _plugin.show(
      reviewerName.hashCode & 0x7FFFFFFF,
      'New Review ⭐',
      '$reviewerName rated your salon ${rating.toStringAsFixed(1)} stars',
      const NotificationDetails(android: _reviewChannel, iOS: _iosDetails),
      payload: 'salon',
    );
  }

  void _handleTap(String? payload) => _tapController.add(payload);

  void dispose() => _tapController.close();
}
