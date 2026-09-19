import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';
import '../core/network/realtime_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/app_repository.dart';
import '../shared/models/models.dart';

final secureStorageProvider =
    Provider((_) => SecureStorageService(const FlutterSecureStorage()));
final apiClientProvider =
    Provider((ref) => ApiClient(ref.watch(secureStorageProvider)));
final appRepositoryProvider =
    Provider((ref) => AppRepository(ref.watch(apiClientProvider)));
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(service.dispose);
  return service;
});
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
    (ref) => AuthNotifier(
          ref.watch(appRepositoryProvider),
          ref.watch(secureStorageProvider),
          ref.watch(realtimeServiceProvider),
        )..restore());
final directoryProvider = FutureProvider.family<List<User>, UserRole>(
    (ref, role) => ref.watch(appRepositoryProvider).users(role));
final eventsProvider = FutureProvider<List<EventItem>>(
    (ref) => ref.watch(appRepositoryProvider).events());
final connectionsProvider = FutureProvider<List<ConnectionItem>>(
    (ref) => ref.watch(appRepositoryProvider).connections());
final notificationsProvider = FutureProvider<List<NotificationItem>>(
    (ref) => ref.watch(appRepositoryProvider).notifications());
final unreadNotificationCountProvider = FutureProvider<int>(
    (ref) => ref.watch(appRepositoryProvider).unreadCount());
final conversationsProvider = FutureProvider<List<Conversation>>(
    (ref) => ref.watch(appRepositoryProvider).conversations());
final allUsersProvider = FutureProvider<List<User>>(
    (ref) => ref.watch(appRepositoryProvider).allUsers());
final adminEventsProvider = FutureProvider<List<EventItem>>(
    (ref) => ref.watch(appRepositoryProvider).events(all: true));

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._repo, this._storage, this._realtime)
      : super(const AsyncLoading());
  final AppRepository _repo;
  final SecureStorageService _storage;
  final RealtimeService _realtime;

  Future<void> restore() async {
    // Hard ceiling: never leave the router in AsyncLoading indefinitely if
    // platform secure-storage stalls beyond Future.timeout (seen on emulators).
    final watchdog = Timer(const Duration(seconds: 3), () {
      if (state.isLoading) {
        state = const AsyncData(null);
      }
    });
    try {
      final token =
          await _storage.readToken().timeout(const Duration(seconds: 2));

      if (token == null || token.isEmpty) {
        state = const AsyncData(null);
        return;
      }

      final user = _fromJwt(token);
      if (user == null) {
        await _storage.clearAuth();
        state = const AsyncData(null);
        return;
      }
      _realtime.connect(token);
      state = AsyncData(user);
    } catch (_) {
      // Unusable persisted session — fall through to logged-out.
      state = const AsyncData(null);
    } finally {
      watchdog.cancel();
    }
  }

  Future<String?> signIn(String email, String password, UserRole role) async {
    // Avoid AsyncLoading here: router treats loading as splash-only.
    try {
      final result = await _repo.login(email, password, role);
      if (result == 'WAIT_APPROVAL') {
        state = const AsyncData(null);
        return result;
      }
      if (result.contains('.')) {
        final user = _fromJwt(result);
        if (user == null) {
          state = const AsyncData(null);
          return 'Invalid credentials';
        }
        await _storage.writeToken(result);
        _realtime.connect(result);
        state = AsyncData(user);
        return null;
      }
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString();
    }
  }

  Future<void> signOut() async {
    _realtime.disconnect();
    await _storage.clearAuth();
    state = const AsyncData(null);
  }

  /// Returns null when the JWT payload is missing email/role.
  User? _fromJwt(String token) {
    try {
      final chunk = base64Url.normalize(token.split('.')[1]);
      final data = jsonDecode(utf8.decode(base64Url.decode(chunk)))
          as Map<String, dynamic>;
      final email = data['sub'] as String? ?? '';
      final role = userRole(data['role'] as String?);
      if (email.isEmpty || role == UserRole.unknown) {
        return null;
      }
      return User(
          id: 0, name: '', email: email, role: role, status: 'APPROVED');
    } catch (_) {
      return null;
    }
  }
}
