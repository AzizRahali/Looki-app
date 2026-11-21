import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loomea/data/models/payment_model.dart';
import 'package:loomea/data/repositories/loomea_repository.dart';
import 'package:loomea/logic/blocs/payment/payment_event.dart';
import 'package:loomea/presentation/features/payment/payment_page.dart';

class _FakeRepository implements LoomeeaRepository {
  _FakeRepository(this.finalStatus);

  final String finalStatus;
  int cancels = 0;

  @override
  Future<PaymentCheckout> startBookingPayment({
    required String salonId,
    required String date,
    required String startTime,
    required List<String> serviceIds,
    String? notes,
  }) async =>
      const PaymentCheckout(
        paymentRef: 'cs_test_1',
        payUrl: 'https://checkout.stripe.com/c/pay/cs_test_1',
        amount: 15,
        currency: 'usd',
      );

  @override
  Future<PaymentStatusInfo> getPaymentStatus(String paymentRef) async =>
      PaymentStatusInfo(
        paymentRef: paymentRef,
        status: finalStatus,
        type: 'BOOKING',
        referenceId: 'appt-1',
        amount: 15,
        currency: 'usd',
      );

  @override
  Future<PaymentStatusInfo> cancelPayment(String paymentRef) async {
    cancels++;
    return getPaymentStatus(paymentRef);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _args = PaymentArgs(
  request: BookingPaymentRequest(
    salonId: 'salon-1',
    date: '2026-11-24',
    startTime: '08:00',
    serviceIds: ['svc-1'],
  ),
  title: 'Barber & Co.',
  subtitle: 'Classic Haircut',
  priceLabel: '15 TND',
);

/// Opens [PaymentPage] from a launcher screen and records what it pops with.
Future<List<Object?>> _pumpPaymentPage(
    WidgetTester tester, _FakeRepository repo) async {
  final popped = <Object?>[];
  await tester.pumpWidget(
    RepositoryProvider<LoomeeaRepository>.value(
      value: repo,
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              popped.add(await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const PaymentPage(args: _args)),
              ));
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  return popped;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  // Desktop: Checkout opens in the browser and the page polls. (url_launcher
  // has no plugin in tests — the page handles that and keeps polling.)
  final desktop = TargetPlatformVariant.only(TargetPlatform.windows);

  testWidgets('shows the summary and Stripe amount, then success pops true',
      (tester) async {
    final popped = await _pumpPaymentPage(tester, _FakeRepository('COMPLETED'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Barber & Co.'), findsOneWidget);
    expect(find.text('15 TND'), findsOneWidget);
    // Strings are untranslated keys in tests.
    expect(find.text('payment_in_browser_title'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3)); // first status poll
    await tester.pump();
    expect(find.text('payment_success_title'), findsOneWidget);

    await tester.tap(find.text('continue_label'));
    await tester.pumpAndSettle();
    expect(popped, [true]);
  }, variant: desktop);

  testWidgets('leaving an unpaid checkout cancels it and pops false',
      (tester) async {
    final repo = _FakeRepository('PENDING');
    final popped = await _pumpPaymentPage(tester, repo);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('payment_cancel'));
    await tester.pump();
    await tester.pump();
    expect(find.text('payment_cancelled_title'), findsOneWidget);
    expect(repo.cancels, 1);

    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(popped, [false]);
  }, variant: desktop);
}
