import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/routing/app_router.dart';

void main() {
  test('unauthenticated users are redirected to login', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/splash',
      isAuthLoading: false,
      isLoggedIn: false,
      currentUser: const AsyncData(null),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/login');
  });

  test('technicians can open AC installations route', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech/ac-installs',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(uid: 'tech-1', name: 'Tech One', email: 'tech@example.com'),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, isNull);
  });

  test('inactive users are redirected back to login', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(
          uid: 'tech-1',
          name: 'Tech One',
          email: 'tech@example.com',
          isActive: false,
        ),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/login');
  });

  test('missing approval config falls back to defaults', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(uid: 'tech-1', name: 'Tech One', email: 'tech@example.com'),
      ),
      approvalConfig: null,
    );

    expect(redirect, isNull);
  });

  test(
    'authenticated profile reload does not redirect away from admin flush',
    () {
      final redirect = resolveAppRedirect(
        matchedLocation: '/admin/flush',
        isAuthLoading: false,
        isLoggedIn: true,
        currentUser: const AsyncLoading(),
        approvalConfig: ApprovalConfig.defaults(),
      );

      expect(redirect, isNull);
    },
  );

  test('admin users are redirected away from technician routes', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech/ac-installs',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(
          uid: 'admin-1',
          name: 'Admin',
          email: 'admin@example.com',
          role: 'admin',
        ),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/admin');
  });

  // ── RBAC adversarial tests ────────────────────────────────────────────────

  test('technician cannot access admin dashboard', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/admin',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(uid: 'tech-1', name: 'Tech One', email: 'tech@example.com'),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/tech');
  });

  test('technician cannot access admin approvals', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/admin/approvals',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(uid: 'tech-1', name: 'Tech One', email: 'tech@example.com'),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/tech');
  });

  test('technician cannot access admin team management', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/admin/team',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(uid: 'tech-1', name: 'Tech One', email: 'tech@example.com'),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/tech');
  });

  test('technician cannot access database flush screen', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/admin/flush',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(uid: 'tech-1', name: 'Tech One', email: 'tech@example.com'),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/tech');
  });

  test('admin cannot access technician submit screen', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech/submit',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(
          uid: 'admin-1',
          name: 'Admin',
          email: 'admin@example.com',
          role: 'admin',
        ),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/admin');
  });

  test('admin cannot access technician history', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/tech/history',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(
          uid: 'admin-1',
          name: 'Admin',
          email: 'admin@example.com',
          role: 'admin',
        ),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/admin');
  });

  test('inactive admin cannot access any route', () {
    final redirect = resolveAppRedirect(
      matchedLocation: '/admin',
      isAuthLoading: false,
      isLoggedIn: true,
      currentUser: const AsyncData(
        UserModel(
          uid: 'admin-2',
          name: 'Inactive Admin',
          email: 'admin2@example.com',
          role: 'admin',
          isActive: false,
        ),
      ),
      approvalConfig: ApprovalConfig.defaults(),
    );

    expect(redirect, '/login');
  });
}
