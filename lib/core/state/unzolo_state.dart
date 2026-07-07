import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local_cache.dart';
import '../offline_queue.dart';
import 'connectivity_provider.dart';

final _db = Supabase.instance.client;

// ==========================================
// OFFLINE-FIRST MUTATION HELPER
// ==========================================
// Always updates local cache + optimistic state first.
// Queues the Supabase op; if online, flushes immediately.

Future<void> _write({
  required String table,
  required String operation,
  required Map<String, dynamic> data,
  String? matchColumn,
  String? matchValue,
}) async {
  final op = QueuedOp(
    id: '${table}_${DateTime.now().millisecondsSinceEpoch}',
    table: table,
    operation: operation,
    data: data,
    matchColumn: matchColumn,
    matchValue: matchValue,
    timestamp: DateTime.now().millisecondsSinceEpoch,
  );
  await OfflineQueue.enqueue(op);
  if (await isOnlineNow()) {
    await OfflineQueue.flush();
  }
}

// ==========================================
// 1. AUTHENTICATION STATE
// ==========================================

class AuthState {
  final bool isLoggedIn;
  final String? email;
  final String? name;
  final String? userId;

  const AuthState({this.isLoggedIn = false, this.email, this.name, this.userId});

  AuthState copyWith({bool? isLoggedIn, String? email, String? name, String? userId}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      name: name ?? this.name,
      userId: userId ?? this.userId,
    );
  }
}

/// Pre-loaded by main() before the app starts, so AuthNotifier.build()
/// can return the correct state synchronously when offline.
AuthState? _cachedOfflineAuth;

/// Call this in main() after Supabase.initialize() and before runApp().
Future<void> preloadOfflineAuth() async {
  _cachedOfflineAuth = await _loadAuthCache();
}

// SharedPreferences keys for cached auth
const _kAuthEmail = 'auth_email';
const _kAuthName = 'auth_name';
const _kAuthUserId = 'auth_user_id';
const _kAuthLoggedIn = 'auth_logged_in';

Future<void> _saveAuthCache(String email, String name, String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kAuthEmail, email);
  await prefs.setString(_kAuthName, name);
  await prefs.setString(_kAuthUserId, userId);
  await prefs.setBool(_kAuthLoggedIn, true);
}

Future<void> _clearAuthCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kAuthEmail);
  await prefs.remove(_kAuthName);
  await prefs.remove(_kAuthUserId);
  await prefs.setBool(_kAuthLoggedIn, false);
}

Future<AuthState?> _loadAuthCache() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kAuthLoggedIn) != true) return null;
  final email = prefs.getString(_kAuthEmail);
  final name = prefs.getString(_kAuthName);
  final userId = prefs.getString(_kAuthUserId);
  if (userId == null) return null;
  return AuthState(isLoggedIn: true, email: email, name: name ?? 'Agent', userId: userId);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Check Supabase session (available offline if token not yet expired)
    final session = _db.auth.currentSession;
    if (session != null) {
      final user = session.user;
      final name = (user.userMetadata?['name'] as String?) ?? 'Agent';
      // Persist so we can restore offline even after token expiry
      _saveAuthCache(user.email ?? '', name, user.id);
      // Listen for Supabase auth changes but ignore sign-out when offline
      _db.auth.onAuthStateChange.listen((event) async {
        if (event.event == AuthChangeEvent.signedOut) {
          final online = await isOnlineNow();
          if (!online) return; // stay logged in offline
          await _clearAuthCache();
          state = const AuthState(isLoggedIn: false);
        } else if (event.event == AuthChangeEvent.tokenRefreshed) {
          final u = event.session?.user;
          if (u != null) {
            final n = (u.userMetadata?['name'] as String?) ?? state.name ?? 'Agent';
            await _saveAuthCache(u.email ?? '', n, u.id);
          }
        }
      });
      return AuthState(isLoggedIn: true, email: user.email, name: name, userId: user.id);
    }
        // No live session — fall back to pre-loaded offline auth cache
    return _cachedOfflineAuth ?? const AuthState(isLoggedIn: false);
  }

  Future<void> login(String email, String password) async {
    final response = await _db.auth.signInWithPassword(email: email, password: password);
    final user = response.user!;
    final name = (user.userMetadata?['name'] as String?) ?? 'Agent';
    await _saveAuthCache(user.email ?? '', name, user.id);
    state = AuthState(isLoggedIn: true, email: user.email, name: name, userId: user.id);
  }

  Future<void> signup(String name, String email, String password) async {
    final response = await _db.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    final user = response.user!;
    await _saveAuthCache(user.email ?? '', name, user.id);
    state = AuthState(isLoggedIn: true, email: user.email, name: name, userId: user.id);
  }

  Future<void> logout() async {
    await _clearAuthCache();
    await LocalCache.clearAll();
    await OfflineQueue.clear();
    try {
      await _db.auth.signOut();
    } catch (_) {}
    state = const AuthState(isLoggedIn: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

// ==========================================
// 2. TRIPS STATE
// ==========================================

Map<String, dynamic> _tripFromRow(Map<String, dynamic> row) => {
  'id': row['id'],
  'title': row['title'],
  'location': row['location'],
  'price': (row['price'] as num).toDouble(),
  'description': row['description'],
  'duration': row['duration'],
  'status': row['status'],
  'statusBg': Color((row['status_bg'] as int?) ?? 0xFFE2F3E2),
  'statusText': Color((row['status_text'] as int?) ?? 0xFF1E7E34),
  'imageUrl': row['image_url'],
  'category': row['category'],
  'startDate': row['start_date'],
  'endDate': row['end_date'],
  'advanceAmount': (row['advance_amount'] as num?)?.toDouble() ?? 0.0,
  if (row['group_size'] != null) 'groupSize': row['group_size'],
};

Map<String, dynamic> _tripToRow(Map<String, dynamic> trip, String userId) => {
  'id': trip['id'],
  'title': trip['title'],
  'location': trip['location'],
  'price': trip['price'],
  'description': trip['description'],
  'duration': trip['duration'],
  'status': trip['status'],
  'status_bg': (trip['statusBg'] as Color?)?.toARGB32(),
  'status_text': (trip['statusText'] as Color?)?.toARGB32(),
  'image_url': trip['imageUrl'],
  'category': trip['category'],
  'start_date': trip['startDate'],
  'end_date': trip['endDate'],
  'advance_amount': trip['advanceAmount'],
  if (trip['groupSize'] != null) 'group_size': trip['groupSize'],
  'is_deleted': false,
  'user_id': userId,
};

// Serialize Color for JSON storage
Map<String, dynamic> _tripForCache(Map<String, dynamic> trip) => {
  ...trip,
  'statusBg': (trip['statusBg'] as Color?)?.toARGB32(),
  'statusText': (trip['statusText'] as Color?)?.toARGB32(),
};

Map<String, dynamic> _tripFromCache(Map<String, dynamic> c) => {
  ...c,
  'statusBg': Color((c['statusBg'] as int?) ?? 0xFFE2F3E2),
  'statusText': Color((c['statusText'] as int?) ?? 0xFF1E7E34),
};

class TripsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final cached = (await LocalCache.load('trips')).map(_tripFromCache).toList();
    // Background sync — doesn't block UI
    _syncFromServer();
    return cached;
  }

  Future<void> _syncFromServer() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    if (!await isOnlineNow()) return;
    try {
      final rows = await _db.from('trips').select().eq('user_id', userId).eq('is_deleted', false).order('created_at', ascending: false);
      final data = (rows as List).map((r) => _tripFromRow(r as Map<String, dynamic>)).toList();
      await LocalCache.save('trips', data.map(_tripForCache).toList());
      state = AsyncData(data);
    } catch (_) {}
  }

  Future<void> _saveCache(List<Map<String, dynamic>> data) =>
      LocalCache.save('trips', data.map(_tripForCache).toList());

  Future<void> addTrip(Map<String, dynamic> trip) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    final updated = <Map<String, dynamic>>[trip, ...state.value ?? []];
    state = AsyncData(updated);
    await _saveCache(updated);
    await _write(table: 'trips', operation: 'insert', data: _tripToRow(trip, userId));
  }

  Future<void> updateTrip(Map<String, dynamic> trip) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    final updated = (state.value ?? []).map<Map<String, dynamic>>((t) => t['id'] == trip['id'] ? trip : t).toList();
    state = AsyncData(updated);
    await _saveCache(updated);
    final row = _tripToRow(trip, userId)..remove('user_id')..remove('is_deleted');
    await _write(table: 'trips', operation: 'update', data: row, matchColumn: 'id', matchValue: trip['id'] as String);
  }

  Future<void> deleteTrip(String id) async {
    final trip = (state.value ?? []).firstWhere((t) => t['id'] == id);
    final updated = (state.value ?? []).where((t) => t['id'] != id).cast<Map<String, dynamic>>().toList();
    state = AsyncData(updated);
    await _saveCache(updated);
    ref.read(deletedTripsProvider.notifier).addDeleted(trip);
    await _write(table: 'trips', operation: 'update', data: {'is_deleted': true}, matchColumn: 'id', matchValue: id);
  }

  Future<void> addRestoredTrip(Map<String, dynamic> trip) async {
    final updated = <Map<String, dynamic>>[trip, ...state.value ?? []];
    state = AsyncData(updated);
    await _saveCache(updated);
  }

  Future<void> syncNow() => _syncFromServer();
}

final tripsProvider = AsyncNotifierProvider<TripsNotifier, List<Map<String, dynamic>>>(() => TripsNotifier());

class DeletedTripsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final cached = (await LocalCache.load('deleted_trips')).map(_tripFromCache).toList();
    _syncFromServer();
    return cached;
  }

  Future<void> _syncFromServer() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    if (!await isOnlineNow()) return;
    try {
      final rows = await _db.from('trips').select().eq('user_id', userId).eq('is_deleted', true).order('created_at', ascending: false);
      final data = (rows as List).map((r) => _tripFromRow(r as Map<String, dynamic>)).toList();
      await LocalCache.save('deleted_trips', data.map(_tripForCache).toList());
      state = AsyncData(data);
    } catch (_) {}
  }

  void addDeleted(Map<String, dynamic> trip) {
    final updated = <Map<String, dynamic>>[trip, ...state.value ?? []];
    state = AsyncData(updated);
    LocalCache.save('deleted_trips', updated.map<Map<String, dynamic>>(_tripForCache).toList());
  }

  Future<void> restoreTrip(String id) async {
    final trip = (state.value ?? []).firstWhere((t) => t['id'] == id);
    final updated = (state.value ?? []).where((t) => t['id'] != id).cast<Map<String, dynamic>>().toList();
    state = AsyncData(updated);
    await LocalCache.save('deleted_trips', updated.map<Map<String, dynamic>>(_tripForCache).toList());
    ref.read(tripsProvider.notifier).addRestoredTrip(trip);
    await _write(table: 'trips', operation: 'update', data: {'is_deleted': false}, matchColumn: 'id', matchValue: id);
  }
}

final deletedTripsProvider =
    AsyncNotifierProvider<DeletedTripsNotifier, List<Map<String, dynamic>>>(() => DeletedTripsNotifier());

// ==========================================
// 3. BOOKINGS STATE
// ==========================================

Map<String, dynamic> _bookingFromRow(Map<String, dynamic> row) => {
  'id': row['id'],
  'tripId': row['trip_id'],
  'title': row['title'],
  'dates': row['dates'],
  'status': row['status'],
  'imageUrl': row['image_url'],
  'amount': row['amount'],
  'collected': (row['collected'] as num?)?.toDouble() ?? 0.0,
  'totalCollected': (row['collected'] as num?)?.toDouble() ?? 0.0,
  'membersCount': row['members_count'] ?? 1,
  'paymentDue': row['payment_due'] ?? false,
  'isActive': (row['is_active'] as bool?) ?? true,
  'concessionAmount': (row['concession_amount'] as num?)?.toDouble() ?? 0.0,
  if (row['rating'] != null) 'rating': row['rating'],
  if (row['stats'] != null) 'stats': row['stats'],
  'members': (row['members'] as List? ?? []).cast<Map<String, dynamic>>(),
  'transactions': (row['transactions'] as List? ?? []).cast<Map<String, dynamic>>(),
};

Map<String, dynamic> _bookingToRow(Map<String, dynamic> b, String userId) => {
  'id': b['id'],
  'trip_id': b['tripId'],
  'title': b['title'],
  'dates': b['dates'],
  'status': b['status'],
  'image_url': b['imageUrl'],
  'amount': b['amount'],
  'collected': b['collected'],
  'members_count': b['membersCount'],
  'payment_due': b['paymentDue'] ?? false,
  'concession_amount': b['concessionAmount'] ?? 0.0,
  'rating': b['rating'],
  'stats': b['stats'],
  'members': b['members'] ?? [],
  'transactions': b['transactions'] ?? [],
  'is_active': b['isActive'] ?? true,
  'user_id': userId,
};

class BookingsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final cached = await LocalCache.load('bookings');
    _syncFromServer();
    return cached;
  }

  Future<void> _syncFromServer() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    if (!await isOnlineNow()) return;
    try {
      final rows = await _db.from('bookings').select().eq('user_id', userId).eq('is_active', true).order('created_at', ascending: false);
      final data = (rows as List).map((r) => _bookingFromRow(r as Map<String, dynamic>)).toList();
      await LocalCache.save('bookings', data);
      state = AsyncData(data);
    } catch (_) {}
  }

  Future<void> addBooking(Map<String, dynamic> booking) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    final updated = <Map<String, dynamic>>[booking, ...state.value ?? []];
    state = AsyncData(updated);
    await LocalCache.save('bookings', updated);
    await _write(table: 'bookings', operation: 'insert', data: _bookingToRow(booking, userId));
  }

  Future<void> updateBooking(Map<String, dynamic> booking) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    final updated = (state.value ?? []).map<Map<String, dynamic>>((b) => b['id'] == booking['id'] ? booking : b).toList();
    state = AsyncData(updated);
    await LocalCache.save('bookings', updated);
    final row = _bookingToRow(booking, userId)..remove('user_id')..remove('is_active');
    await _write(table: 'bookings', operation: 'update', data: row, matchColumn: 'id', matchValue: booking['id'] as String);
  }

  Future<void> addRestoredBooking(Map<String, dynamic> booking) async {
    final updated = <Map<String, dynamic>>[booking, ...state.value ?? []];
    state = AsyncData(updated);
    await LocalCache.save('bookings', updated);
  }

  Future<void> deactivateBooking(String id) async {
    final booking = (state.value ?? []).firstWhere((b) => b['id'] == id);
    final updated = (state.value ?? []).where((b) => b['id'] != id).cast<Map<String, dynamic>>().toList();
    state = AsyncData(updated);
    await LocalCache.save('bookings', updated);
    ref.read(deactivatedBookingsProvider.notifier).addDeactivated(booking);
    await _write(table: 'bookings', operation: 'update', data: {'is_active': false, 'status': 'Cancelled'}, matchColumn: 'id', matchValue: id);
  }

  Future<void> syncNow() => _syncFromServer();
}

final bookingsProvider =
    AsyncNotifierProvider<BookingsNotifier, List<Map<String, dynamic>>>(() => BookingsNotifier());

class DeactivatedBookingsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final cached = await LocalCache.load('deactivated_bookings');
    _syncFromServer();
    return cached;
  }

  Future<void> _syncFromServer() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    if (!await isOnlineNow()) return;
    try {
      final rows = await _db.from('bookings').select().eq('user_id', userId).eq('is_active', false).order('created_at', ascending: false);
      final data = (rows as List).map((r) => _bookingFromRow(r as Map<String, dynamic>)).toList();
      await LocalCache.save('deactivated_bookings', data);
      state = AsyncData(data);
    } catch (_) {}
  }

  void addDeactivated(Map<String, dynamic> booking) {
    final updated = <Map<String, dynamic>>[booking, ...state.value ?? []];
    state = AsyncData(updated);
    LocalCache.save('deactivated_bookings', updated);
  }

  Future<void> recoverBooking(String id) async {
    final booking = (state.value ?? []).firstWhere((b) => b['id'] == id);
    final updated = (state.value ?? []).where((b) => b['id'] != id).cast<Map<String, dynamic>>().toList();
    state = AsyncData(updated);
    await LocalCache.save('deactivated_bookings', updated);
    ref.read(bookingsProvider.notifier).addRestoredBooking(booking);
    await _write(table: 'bookings', operation: 'update', data: {'is_active': true, 'status': 'Pending'}, matchColumn: 'id', matchValue: id);
  }
}

final deactivatedBookingsProvider =
    AsyncNotifierProvider<DeactivatedBookingsNotifier, List<Map<String, dynamic>>>(() => DeactivatedBookingsNotifier());

// ==========================================
// 4. EXPENSES STATE
// ==========================================

Map<String, dynamic> _expenseFromRow(Map<String, dynamic> row) => {
  'id': row['id'],
  'tripId': row['trip_id'],
  'category': row['category'],
  'amount': (row['amount'] as num?)?.toDouble() ?? 0.0,
  'description': row['description'],
  'date': row['date'],
  'payer': row['payer'],
  'notes': row['notes'],
};

class ExpensesNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final cached = await LocalCache.load('expenses');
    _syncFromServer();
    return cached;
  }

  Future<void> _syncFromServer() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    if (!await isOnlineNow()) return;
    try {
      final rows = await _db.from('expenses').select().eq('user_id', userId).order('created_at', ascending: false);
      final data = (rows as List).map((r) => _expenseFromRow(r as Map<String, dynamic>)).toList();
      await LocalCache.save('expenses', data);
      state = AsyncData(data);
    } catch (_) {}
  }

  Future<void> syncNow() => _syncFromServer();

  Future<void> addExpense(Map<String, dynamic> expense) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    final updated = <Map<String, dynamic>>[expense, ...state.value ?? []];
    state = AsyncData(updated);
    await LocalCache.save('expenses', updated);
    await _write(table: 'expenses', operation: 'insert', data: {
      'id': expense['id'],
      'trip_id': expense['tripId'],
      'category': expense['category'],
      'amount': expense['amount'],
      'description': expense['description'],
      'date': expense['date'],
      'payer': expense['payer'],
      'notes': expense['notes'],
      'user_id': userId,
    });
  }
}

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<Map<String, dynamic>>>(() => ExpensesNotifier());

// ==========================================
// 5. CUSTOMERS STATE
// ==========================================

Map<String, dynamic> _customerFromRow(Map<String, dynamic> row) => {
  'id': row['id'],
  'name': row['name'],
  'age': row['age'],
  'gender': row['gender'],
  'place': row['place'],
  'contact': row['contact'],
  'travelCount': row['travel_count'] ?? 0,
  'cancellationsCount': row['cancellations_count'] ?? 0,
  'lastDestination': row['last_destination'],
  'lastDate': row['last_date'],
};

class CustomersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final cached = await LocalCache.load('customers');
    _syncFromServer();
    return cached;
  }

  Future<void> _syncFromServer() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    if (!await isOnlineNow()) return;
    try {
      final rows = await _db.from('customers').select().eq('user_id', userId).order('created_at', ascending: false);
      final data = (rows as List).map((r) => _customerFromRow(r as Map<String, dynamic>)).toList();
      await LocalCache.save('customers', data);
      state = AsyncData(data);
    } catch (_) {}
  }

  Future<void> syncNow() => _syncFromServer();

  Future<void> updateCustomer(Map<String, dynamic> customer) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    final updated = (state.value ?? []).map<Map<String, dynamic>>((c) => c['id'] == customer['id'] ? customer : c).toList();
    state = AsyncData(updated);
    await LocalCache.save('customers', updated);
    await _write(table: 'customers', operation: 'update', data: {
      'name': customer['name'],
      'age': customer['age'],
      'gender': customer['gender'],
      'place': customer['place'],
      'contact': customer['contact'],
    }, matchColumn: 'id', matchValue: customer['id'] as String);
  }

  Future<void> deleteCustomer(String id) async {
    final updated = (state.value ?? []).where((c) => c['id'] != id).cast<Map<String, dynamic>>().toList();
    state = AsyncData(updated);
    await LocalCache.save('customers', updated);
    await _write(table: 'customers', operation: 'delete', data: {}, matchColumn: 'id', matchValue: id);
  }

  Future<void> addCustomer(Map<String, dynamic> customer) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    final updated = <Map<String, dynamic>>[customer, ...state.value ?? []];
    state = AsyncData(updated);
    await LocalCache.save('customers', updated);
    await _write(table: 'customers', operation: 'insert', data: {
      'id': customer['id'] ?? 'cust-${DateTime.now().millisecondsSinceEpoch}',
      'name': customer['name'],
      'age': customer['age'],
      'gender': customer['gender'],
      'place': customer['place'],
      'contact': customer['contact'],
      'travel_count': customer['travelCount'] ?? 0,
      'cancellations_count': customer['cancellationsCount'] ?? 0,
      'last_destination': customer['lastDestination'],
      'last_date': customer['lastDate'],
      'user_id': userId,
    });
  }
}

final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Map<String, dynamic>>>(() => CustomersNotifier());

class BookingsTripFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';
  void set(String tripId) => state = tripId;
}

final bookingsTripFilterProvider =
    NotifierProvider<BookingsTripFilterNotifier, String>(() => BookingsTripFilterNotifier());

// ==========================================
// 6. ENQUIRIES STATE
// ==========================================

Map<String, dynamic> _enquiryFromRow(Map<String, dynamic> row) => {
  'id': row['id'],
  'name': row['name'],
  'email': row['email'],
  'phone': row['phone'],
  'trip': row['trip'],
  'message': row['message'],
  'status': row['status'],
  'date': row['date'],
  'avatarColor': Color((row['avatar_color'] as int?) ?? 0xFF6B8E23),
  'followUpDate': row['follow_up_date'],
  'priority': row['priority'],
};

Map<String, dynamic> _enquiryForCache(Map<String, dynamic> e) => {
  ...e,
  'avatarColor': (e['avatarColor'] as Color?)?.toARGB32(),
};

Map<String, dynamic> _enquiryFromCache(Map<String, dynamic> c) => {
  ...c,
  'avatarColor': Color((c['avatarColor'] as int?) ?? 0xFF6B8E23),
};

class EnquiriesNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final cached = (await LocalCache.load('enquiries')).map(_enquiryFromCache).toList();
    _syncFromServer();
    return cached;
  }

  Future<void> _syncFromServer() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    if (!await isOnlineNow()) return;
    try {
      final rows = await _db.from('enquiries').select().eq('user_id', userId).order('created_at', ascending: false);
      final data = (rows as List).map((r) => _enquiryFromRow(r as Map<String, dynamic>)).toList();
      await LocalCache.save('enquiries', data.map(_enquiryForCache).toList());
      state = AsyncData(data);
    } catch (_) {}
  }

  Future<void> syncNow() => _syncFromServer();

  Future<void> addEnquiry(Map<String, dynamic> enquiry) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    final updated = <Map<String, dynamic>>[enquiry, ...state.value ?? []];
    state = AsyncData(updated);
    await LocalCache.save('enquiries', updated.map<Map<String, dynamic>>(_enquiryForCache).toList());
    await _write(table: 'enquiries', operation: 'insert', data: {
      'id': enquiry['id'],
      'name': enquiry['name'],
      'email': enquiry['email'],
      'phone': enquiry['phone'],
      'trip': enquiry['trip'],
      'message': enquiry['message'],
      'status': enquiry['status'],
      'date': enquiry['date'],
      'avatar_color': (enquiry['avatarColor'] as Color?)?.toARGB32(),
      'follow_up_date': enquiry['followUpDate'],
      'priority': enquiry['priority'],
      'user_id': userId,
    });
  }

  Future<void> updateEnquiryStatus(String id, String status) async {
    final updated = (state.value ?? []).map<Map<String, dynamic>>((e) => e['id'] == id ? {...e, 'status': status} : e).toList();
    state = AsyncData(updated);
    await LocalCache.save('enquiries', updated.map<Map<String, dynamic>>(_enquiryForCache).toList());
    await _write(table: 'enquiries', operation: 'update', data: {'status': status}, matchColumn: 'id', matchValue: id);
  }
}

final enquiriesProvider =
    AsyncNotifierProvider<EnquiriesNotifier, List<Map<String, dynamic>>>(() => EnquiriesNotifier());
