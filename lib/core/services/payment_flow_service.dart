import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/local/hive_storage.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_status.dart';
import '../../domain/entities/pending_payment.dart';
import 'auth_session_service.dart';
import 'upi_parser_service.dart';
import 'upi_payment_service.dart' show UpiLaunchException, UpiPaymentService;

class PaymentFlowService {
  PaymentFlowService({
    required HiveStorage storage,
    required ExpenseRepository expenseRepo,
    required UpiPaymentService upiService,
    required UpiParserService parserService,
    required SharedPreferences prefs,
    required AuthSessionService authSession,
  })  : _storage = storage,
        _expenseRepo = expenseRepo,
        _upiService = upiService,
        _parser = parserService,
        _prefs = prefs,
        _authSession = authSession;

  final HiveStorage _storage;
  final ExpenseRepository _expenseRepo;
  final UpiPaymentService _upiService;
  final UpiParserService _parser;
  final SharedPreferences _prefs;
  final AuthSessionService _authSession;
  final _uuid = const Uuid();

  String? _activePendingId;

  String? get activePendingId => _activePendingId;

  Future<PendingPayment> startPaymentFlow({
    required String upiId,
    required double amount,
    required List<String> tagIds,
    String? merchantName,
    String? notes,
    String? rawQrPayload,
    required String paymentAppId,
    required String paymentAppName,
    required String packageName,
  }) async {
    final pending = await _createPending(
      upiId: upiId,
      amount: amount,
      tagIds: tagIds,
      merchantName: merchantName,
      notes: notes,
      rawQrPayload: rawQrPayload,
      paymentAppId: paymentAppId,
      paymentAppName: paymentAppName,
    );

    await _recordAppUsage(paymentAppId);
    _authSession.suspendLockForExternalFlow();

    final uri = _parser.buildPaymentUri(
      upiId: upiId,
      merchantName: merchantName,
      amount: amount,
      transactionNote: pending.transactionNote ?? 'PayTrack expense',
      rawQrPayload: rawQrPayload,
    );

    await _upiService.launchPayment(
      upiUri: uri,
      packageName: packageName,
      appName: paymentAppName,
      appId: paymentAppId,
    );

    return pending;
  }

  /// Saves pending payment and opens system UPI chooser (no fixed package).
  Future<PendingPayment> startPaymentViaChooser({
    required String upiId,
    required double amount,
    required List<String> tagIds,
    String? merchantName,
    String? notes,
    String? rawQrPayload,
  }) async {
    final pending = await _createPending(
      upiId: upiId,
      amount: amount,
      tagIds: tagIds,
      merchantName: merchantName,
      notes: notes,
      rawQrPayload: rawQrPayload,
      paymentAppId: 'other',
      paymentAppName: 'Other',
    );

    _authSession.suspendLockForExternalFlow();

    final uri = pending.upiLaunchUri;
    if (uri == null) {
      throw UpiLaunchException('Invalid payment link');
    }
    final launched = await _upiService.launchGenericChooser(uri);
    if (!launched) {
      await _storage.clearPending(pending.id);
      _activePendingId = null;
      throw UpiLaunchException('No UPI app available to handle payment');
    }

    return pending;
  }

  Future<PendingPayment> _createPending({
    required String upiId,
    required double amount,
    required List<String> tagIds,
    String? merchantName,
    String? notes,
    String? rawQrPayload,
    required String paymentAppId,
    required String paymentAppName,
  }) async {
    final id = _uuid.v4();
    final note = notes ?? 'PayTrack expense';
    final uri = _parser.buildPaymentUri(
      upiId: upiId,
      merchantName: merchantName,
      amount: amount,
      transactionNote: note,
      rawQrPayload: rawQrPayload,
    );

    final pending = PendingPayment(
      id: id,
      amount: amount,
      tagIds: tagIds,
      upiId: upiId,
      startedAt: DateTime.now(),
      merchantName: merchantName,
      notes: notes,
      paymentAppId: paymentAppId,
      paymentAppName: paymentAppName,
      transactionNote: note,
      upiLaunchUri: uri,
    );

    await _storage.savePending(pending);
    _activePendingId = id;
    return pending;
  }

  Future<void> _recordAppUsage(String appId) async {
    final usageKey = '${AppConstants.prefUpiAppUsage}_$appId';
    final count = (_prefs.getInt(usageKey) ?? 0) + 1;
    await _prefs.setInt(usageKey, count);
    await _prefs.setString(AppConstants.prefLastUpiApp, appId);
  }

  Future<Expense?> completePayment({
    required String pendingId,
    required ExpenseStatus status,
  }) async {
    final pending = await _storage.getPending(pendingId);
    if (pending == null) return null;

    final expense = Expense(
      id: pendingId,
      amount: pending.amount,
      tagIds: pending.tagIds,
      createdAt: DateTime.now(),
      notes: pending.notes,
      merchantName: pending.merchantName,
      upiId: pending.upiId,
      paymentAppId: pending.paymentAppId,
      paymentAppName: pending.paymentAppName,
      status: status,
      isManual: false,
    );

    await _expenseRepo.save(expense);
    await _storage.clearPending(pendingId);
    if (_activePendingId == pendingId) _activePendingId = null;

    return expense;
  }

  Future<PendingPayment?> checkPendingOnResume() async {
    final pending = await _storage.getLatestPending();
    if (pending == null) {
      _activePendingId = null;
      return null;
    }

    final elapsed = DateTime.now().difference(pending.startedAt);
    if (elapsed.inSeconds > AppConstants.paymentConfirmationTimeoutSec) {
      _activePendingId = pending.id;
      return pending;
    }

    _activePendingId = pending.id;
    return pending;
  }

  Future<void> cancelPending(String pendingId) async {
    await completePayment(
      pendingId: pendingId,
      status: ExpenseStatus.cancelled,
    );
  }

  int getAppUsageCount(String appId) {
    return _prefs.getInt('${AppConstants.prefUpiAppUsage}_$appId') ?? 0;
  }

  String? getLastUsedAppId() => _prefs.getString(AppConstants.prefLastUpiApp);
}
