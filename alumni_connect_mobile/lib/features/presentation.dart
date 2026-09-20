import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/providers.dart';
import '../shared/models/models.dart';
import '../shared/widgets/ui_components.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext c) => const Scaffold(body: LoadingState());
}

class InvalidRouteScreen extends StatelessWidget {
  const InvalidRouteScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: const Center(child: Text('The requested resource is invalid.')));
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        body: SafeArea(
          child: responsiveContent(
            c,
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 64, color: AppColors.warning),
                  const SizedBox(height: 20),
                  Text('Approval in progress',
                      style: Theme.of(c).textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text(
                      'Your account was created successfully and is waiting for administrator approval. You can return to sign in once it is active.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  const StatusBadge('PENDING'),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                      onPressed: () => c.go('/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('Back to sign in')),
                ],
              ),
            ),
          ),
        ),
      );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  UserRole _role = UserRole.student;
  String? _error;
  bool _busy = false;
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: constraints.maxHeight, maxWidth: 520),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Form(
                                  key: _formKey,
                                  child: Column(children: [
                                const Icon(Icons.hub_rounded,
                                    size: 54, color: AppColors.blue),
                                const SizedBox(height: 8),
                                Text('Welcome back',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                                const Text('Connect, grow, and give back.',
                                    style: TextStyle(color: AppColors.muted)),
                                const SizedBox(height: 16),
                                TextField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email_outlined)),
                                    onChanged: (_) {
                                      if (_error != null) setState(() => _error = null);
                                    }),
                                TextField(
                                    controller: _pass,
                                    obscureText: !_showPassword,
                                    decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                            tooltip: _showPassword
                                                ? 'Hide password'
                                                : 'Show password',
                                            onPressed: () => setState(() =>
                                                _showPassword = !_showPassword),
                                            icon: Icon(_showPassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined))),
                                    onSubmitted: (_) => _submit()),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<UserRole>(
                                    initialValue: _role,
                                    decoration: const InputDecoration(
                                        labelText: 'Sign in as',
                                        prefixIcon: Icon(Icons.badge_outlined)),
                                    items: const [
                                      DropdownMenuItem(
                                          value: UserRole.student,
                                          child: Text('Student')),
                                      DropdownMenuItem(
                                          value: UserRole.alumni,
                                          child: Text('Alumni')),
                                      DropdownMenuItem(
                                          value: UserRole.admin,
                                          child: Text('Admin')),
                                    ],
                                    onChanged: _busy
                                        ? null
                                        : (v) {
                                            if (v != null) {
                                              setState(() => _role = v);
                                            }
                                          }),
                                if (_error != null) ...[
                                  const SizedBox(height: 8),
                                  InlineError(_error!),
                                ],
                                const SizedBox(height: 12),
                                FilledButton(
                                    onPressed: _busy ? null : _submit,
                                    child: Text(
                                        _busy ? 'Signing in…' : 'Sign in')),
                                TextButton(
                                    onPressed: () => context.go('/register'),
                                    child: const Text('Create account')),
                                TextButton(
                                    onPressed: () =>
                                        context.go('/forgot-password'),
                                    child: const Text('Forgot password?'))
                              ]),
                                ),
                              ])));
                }))));
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@') || _pass.text.isEmpty) {
      setState(() => _error = 'Enter a valid email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final x = await ref.read(authProvider.notifier).signIn(
          email, _pass.text, _role);
      if (!mounted) return;
      if (x == 'WAIT_APPROVAL') {
        context.go('/pending-approval');
      } else {
        setState(() => _error = x);
      }
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.student;
  String? _error;
  bool _busy = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: responsiveContent(c, Column(children: [
              TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline))),
              TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined))),
              TextField(
                  controller: _password,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: 'Use at least 8 characters',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(_showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined)))),
              DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                      labelText: 'I’m joining as',
                      prefixIcon: Icon(Icons.groups_outlined)),
                  items: const [
                    DropdownMenuItem(
                        value: UserRole.student, child: Text('Student')),
                    DropdownMenuItem(
                        value: UserRole.alumni, child: Text('Alumni'))
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) setState(() => _role = value);
                        }),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InlineError(_error!)),
              FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() {
                            _busy = true;
                            _error = null;
                          });
                          final email = _email.text.trim();
                          if (_name.text.trim().isEmpty ||
                              !email.contains('@') ||
                              _password.text.length < 8) {
                            setState(() {
                              _busy = false;
                              _error =
                                  'Enter a name, a valid email, and a password of at least 8 characters.';
                            });
                            return;
                          }
                          try {
                            await ProviderScope.containerOf(c)
                                .read(appRepositoryProvider)
                                .signup(
                                    User(
                                        id: 0,
                                        name: _name.text.trim(),
                                        email: _email.text.trim(),
                                        role: _role,
                                        status: 'PENDING'),
                                    _password.text);
                            if (!c.mounted) return;
                            c.go('/login');
                          } catch (error) {
                            if (!c.mounted) return;
                            setState(() {
                              _busy = false;
                              _error = userFacingError(error);
                            });
                          }
                        },
                  child: Text(_busy ? 'Submitting…' : 'Submit for approval'))
            ])),
          ),
        ));
  }
}

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key, this.forgot = false});
  final bool forgot;
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: responsiveContent(c, Column(children: [
              TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
              if (!widget.forgot)
                TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'New password',
                        helperText: 'Use at least 8 characters',
                        prefixIcon: Icon(Icons.lock_outline))),
              if (_error != null) ...[
                const SizedBox(height: 8),
                InlineError(_error!)
              ],
              FilledButton(
                  onPressed: _busy ? null : () async {
                    if (_email.text.trim().isEmpty ||
                        !_email.text.contains('@') ||
                        (!widget.forgot && _password.text.length < 8)) {
                      setState(() => _error = widget.forgot
                          ? 'Enter a valid email address.'
                          : 'Enter a valid email and a password of at least 8 characters.');
                      return;
                    }
                    setState(() {
                      _busy = true;
                      _error = null;
                    });
                    final repo = ProviderScope.containerOf(c)
                        .read(appRepositoryProvider);
                    try {
                      if (widget.forgot) {
                        await repo.forgotPassword(_email.text.trim());
                      } else {
                        await repo.resetPassword(
                            _email.text.trim(), _password.text);
                      }
                      if (c.mounted) {
                        c.go(widget.forgot ? '/otp-verify' : '/login');
                      }
                    } catch (error) {
                      if (mounted) setState(() => _error = userFacingError(error));
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                  child: Text(_busy
                      ? 'Working…'
                      : widget.forgot
                          ? 'Send OTP'
                          : 'Reset password'))
            ])),
          ),
        ));
  }
}

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final e = TextEditingController(), o = TextEditingController();
    return Scaffold(
        appBar: AppBar(),
        body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              TextField(
                  controller: e,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: o,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'OTP', prefixIcon: Icon(Icons.pin_outlined))),
              FilledButton(
                  onPressed: () async {
                    if (e.text.trim().isEmpty || o.text.trim().isEmpty) {
                      ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
                          content: Text('Enter your email and OTP.')));
                      return;
                    }
                    try {
                      await ProviderScope.containerOf(c)
                          .read(appRepositoryProvider)
                          .verifyOtp(e.text.trim(), o.text.trim());
                      if (c.mounted) {
                        c.go('/reset-password');
                      }
                    } catch (error) {
                      if (c.mounted) {
                        ScaffoldMessenger.of(c).showSnackBar(SnackBar(
                            content: Text(userFacingError(error))));
                      }
                    }
                  },
                  child: const Text('Verify OTP'))
            ])));
  }
}

class RoleShell extends ConsumerWidget {
  const RoleShell({super.key, required this.role, required this.tab});
  final UserRole role;
  final String tab;
  @override
  Widget build(BuildContext c, WidgetRef r) {
    final tabs = role == UserRole.admin
        ? ['dashboard', 'approvals', 'events', 'profile']
        : ['home', 'directory', 'events', 'profile'];
    final index = tabs.contains(tab) ? tabs.indexOf(tab) : 0;
    final pages = [
      const HomeScreen(),
      role == UserRole.admin
          ? const ApprovalsScreen()
          : const DirectoryScreen(),
      const EventsScreen(),
      const ProfileScreen()
    ];
    final labels = role == UserRole.admin
        ? ['Dashboard', 'Approvals', 'Events', 'Profile']
        : ['Home', 'Directory', 'Events', 'Profile'];
    final icons = role == UserRole.admin
        ? [
            Icons.dashboard_outlined,
            Icons.verified_user_outlined,
            Icons.event_outlined,
            Icons.person_outline
          ]
        : [
            Icons.home_outlined,
            Icons.people_outline,
            Icons.event_outlined,
            Icons.person_outline
          ];
    return Scaffold(
        appBar: AppBar(title: const Text('Alumni Connect'), actions: [
          IconButton(
              onPressed: () => c.push('/notifications'),
              icon: const Icon(Icons.notifications_outlined))
        ]),
        body: pages[index],
        bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            destinations: [
              for (var i = 0; i < tabs.length; i++)
                NavigationDestination(icon: Icon(icons[i]), label: labels[i])
            ],
            onDestinationSelected: (i) => c.go('/${role.name}/${tabs[i]}')));
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext c) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Your community awaits',
              style: Theme.of(c).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text('Build meaningful connections with students and alumni.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 24),
          const AppCard(
              child: Row(children: [
            CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xffe4efff),
                child: Icon(Icons.hub, color: AppColors.blue)),
            SizedBox(width: 14),
            Expanded(
                child: Text(
                    'Stay curious. Share your journey. Help others grow.',
                    style: TextStyle(fontWeight: FontWeight.w600))),
          ])),
          const SizedBox(height: 20),
          const AppSectionTitle('Quick actions'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _QuickAction(
                    icon: Icons.people_outline,
                    label: 'Connections',
                    onTap: () => c.push('/connections'))),
            const SizedBox(width: 12),
            Expanded(
                child: _QuickAction(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    onTap: () => c.push('/chat/inbox'))),
          ])
        ],
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppCard(
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(children: [
            Icon(icon, color: AppColors.blue, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700))
          ])));
}

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discover people', style: Theme.of(c).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text(
            'Find alumni and grow your professional network.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _list<User>(
              r.watch(directoryProvider(UserRole.alumni)),
              (u) => AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(name: u.name),
                  title: Text(
                    u.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [u.company, u.location, u.email]
                        .whereType<String>()
                        .where((x) => x.isNotEmpty)
                        .join(' • '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => c.push('/user/${u.id}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) {
    final user = r.watch(authProvider).valueOrNull;
    final events = user?.role == UserRole.admin
        ? r.watch(adminEventsProvider)
        : r.watch(eventsProvider);
    return _list<EventItem>(
        events,
        (e) => AppCard(
            child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                    backgroundColor: Color(0xffe7f5f2),
                    child: Icon(Icons.event, color: AppColors.teal)),
                title: Text(e.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${e.eventDate ?? 'Date to be announced'}\n${e.location ?? 'Online'}'),
                trailing: user?.role == UserRole.admin
                    ? Wrap(children: [
                        IconButton(
                            tooltip: 'Approve',
                            onPressed: e.status == 'APPROVED'
                                ? null
                                : () async {
                                    await r
                                        .read(appRepositoryProvider)
                                        .approveEvent(e.id);
                                    r.invalidate(adminEventsProvider);
                                  },
                            icon: const Icon(Icons.check)),
                        IconButton(
                            tooltip: 'Reject',
                            onPressed: () async {
                              await r
                                  .read(appRepositoryProvider)
                                  .rejectEvent(e.id);
                              r.invalidate(adminEventsProvider);
                            },
                            icon: const Icon(Icons.close))
                      ])
                    : null,
                onTap: () => c.push('/event/${e.id}'))));
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _location = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(authProvider).valueOrNull;
    if (u != null && !_loaded) {
      _loaded = true;
      _name.text = u.name;
      _bio.text = u.bio ?? '';
      _location.text = u.location ?? '';
    }
    return ListView(padding: const EdgeInsets.all(20), children: [
      AppCard(
          child: Row(children: [
        UserAvatar(name: u?.name, radius: 34),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u?.name ?? 'Your profile',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 3),
          Text(u?.email ?? '', style: const TextStyle(color: AppColors.muted)),
          if (u != null) ...[
            const SizedBox(height: 8),
            StatusBadge(u.role.name)
          ]
        ]))
      ])),
      const SizedBox(height: 18),
      const AppSectionTitle('Edit your profile'),
      const SizedBox(height: 10),
      TextField(
          controller: _name,
          decoration: const InputDecoration(
              labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
      TextField(
          controller: _bio,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'About you', prefixIcon: Icon(Icons.notes_outlined))),
      TextField(
          controller: _location,
          decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on_outlined))),
      const SizedBox(height: 12),
      FilledButton(
          onPressed: u == null || _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  final updated = User(
                      id: u.id,
                      name: _name.text.trim(),
                      email: u.email,
                      role: u.role,
                      status: u.status,
                      bio: _bio.text.trim(),
                      location: _location.text.trim(),
                      college: u.college,
                      branch: u.branch,
                      passoutYear: u.passoutYear,
                      rollno: u.rollno,
                      section: u.section,
                      skills: u.skills,
                      company: u.company,
                      jobRole: u.jobRole,
                      linkedin: u.linkedin,
                      github: u.github,
                      profileImage: u.profileImage,
                      interests: u.interests);
                  try {
                    final saved = await ref
                        .read(appRepositoryProvider)
                        .updateUser(updated);
                    ref.read(authProvider.notifier).setUser(saved);
                    if (!context.mounted) return;
                    setState(() => _saving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile saved')));
                  } catch (error) {
                    if (!context.mounted) return;
                    setState(() => _saving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(userFacingError(error))));
                  }
                },
          child: Text(_saving ? 'Saving…' : 'Save profile')),
      const SizedBox(height: 8),
      OutlinedButton(
          onPressed: () => ref.read(authProvider.notifier).signOut(),
          child: const Text('Sign out'))
    ]);
  }
}

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: _list<ConnectionItem>(
        r.watch(connectionsProvider),
        (x) => AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: UserAvatar(
              name: x.requester?.name ?? x.receiver?.name,
            ),
            title: Text(
              x.requester?.name ?? x.receiver?.name ?? 'Connection',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(x.status),
            trailing: x.status.toUpperCase() == 'PENDING'
                ? Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Accept',
                        onPressed: () async {
                          await r
                              .read(appRepositoryProvider)
                              .respondConnection(x.id, 'ACCEPTED');
                          r.invalidate(connectionsProvider);
                        },
                        icon: const Icon(Icons.check),
                      ),
                      IconButton(
                        tooltip: 'Reject',
                        onPressed: () async {
                          await r
                              .read(appRepositoryProvider)
                              .respondConnection(x.id, 'REJECTED');
                          r.invalidate(connectionsProvider);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  )
                : StatusBadge(x.status),
          ),
        ),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) => Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _list<NotificationItem>(
          r.watch(notificationsProvider),
          (n) => AppCard(
              child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(n.message,
                      style: TextStyle(
                          fontWeight:
                              n.isRead ? FontWeight.normal : FontWeight.w700)),
                  leading: Icon(
                      n.type?.toUpperCase() == 'MESSAGE'
                          ? Icons.chat_bubble_outline
                          : n.type?.toUpperCase() == 'EVENT'
                              ? Icons.event_outlined
                              : Icons.people_outline,
                      color: n.isRead ? AppColors.muted : AppColors.blue),
                  onTap: n.isRead
                      ? null
                      : () async {
                          await r.read(appRepositoryProvider).markRead(n.id);
                          r.invalidate(notificationsProvider);
                          r.invalidate(unreadNotificationCountProvider);
                        }))));
}

class UserScreen extends ConsumerWidget {
  const UserScreen({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext c, WidgetRef r) => Scaffold(
      appBar: AppBar(actions: [
        IconButton(
            tooltip: 'Connect',
            onPressed: () async {
              await r.read(appRepositoryProvider).requestConnection(id);
              if (c.mounted) {
                ScaffoldMessenger.of(c).showSnackBar(
                    const SnackBar(content: Text('Connection requested')));
              }
            },
            icon: const Icon(Icons.person_add))
      ]),
      body: FutureBuilder<User>(
          future: r.read(appRepositoryProvider).user(id),
          builder: (_, s) => s.hasData
              ? ListView(padding: const EdgeInsets.all(24), children: [
                  Text(s.data!.name,
                      style: Theme.of(c).textTheme.headlineSmall),
                  Text(s.data!.email),
                  if (s.data!.bio?.isNotEmpty == true) Text(s.data!.bio!),
                  if (s.data!.company?.isNotEmpty == true)
                    Text('${s.data!.jobRole ?? ''} at ${s.data!.company}'),
                  if (s.data!.location?.isNotEmpty == true)
                    Text(s.data!.location!)
                ])
              : s.hasError
                  ? ErrorState(message: userFacingError(s.error!))
                  : const LoadingState()));
}

class EventScreen extends StatelessWidget {
  const EventScreen({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext c) => _EventDetails(id: id);
}

class _EventDetails extends ConsumerWidget {
  const _EventDetails({required this.id});
  final int id;
  @override
  Widget build(BuildContext c, WidgetRef r) {
    final isAdmin = r.watch(authProvider).valueOrNull?.role == UserRole.admin;
    return Scaffold(
        appBar: AppBar(title: const Text('Event')),
        body: FutureBuilder<List<EventItem>>(
            future: r.read(appRepositoryProvider).events(all: isAdmin),
            builder: (_, snapshot) {
              if (snapshot.hasError) {
                return ErrorState(message: userFacingError(snapshot.error!));
              }
              if (!snapshot.hasData) {
                return const LoadingState();
              }
              final matches = snapshot.data!.where((e) => e.id == id);
              if (matches.isEmpty) {
                return const Center(child: Text('Event not found'));
              }
              final event = matches.first;
              return ListView(padding: const EdgeInsets.all(24), children: [
                Text(event.title, style: Theme.of(c).textTheme.headlineSmall),
                if (event.description?.isNotEmpty == true)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(event.description!)),
                Text(event.location ?? 'Online'),
                Text(event.eventDate ?? ''),
                FilledButton(
                    onPressed: () async {
                      await r.read(appRepositoryProvider).registerEvent(id);
                      if (c.mounted) {
                        ScaffoldMessenger.of(c).showSnackBar(
                            const SnackBar(content: Text('Registered')));
                      }
                    },
                    child: const Text('Register')),
                OutlinedButton(
                    onPressed: () async {
                      await r
                          .read(appRepositoryProvider)
                          .cancelRegistration(id);
                      if (c.mounted) {
                        ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
                            content: Text('Registration cancelled')));
                      }
                    },
                    child: const Text('Cancel registration'))
              ]);
            }));
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.email});
  final String email;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _messages = <ChatMessage>[];
  StreamSubscription<ChatMessage>? _sub;
  bool _loading = true;
  String? _error;
  String? _sendError;

  bool get _isInbox => widget.email == 'inbox';

  @override
  void initState() {
    super.initState();
    if (!_isInbox) {
      _loadHistory();
      _sub = ref.read(realtimeServiceProvider).messages.listen((m) {
        final me = ref.read(authProvider).valueOrNull?.email ?? '';
        final other = widget.email;
        final involves = (m.senderEmail == me && m.receiverEmail == other) ||
            (m.senderEmail == other && m.receiverEmail == me);
        if (!involves || !mounted) return;
        setState(() {
          if (!_messages.any((e) => e.id != null && m.id != null
              ? e.id == m.id
              : e.content == m.content &&
                  e.senderEmail == m.senderEmail &&
                  e.timestamp == m.timestamp)) {
            _messages.add(m);
          }
        });
      });
    }
  }

  Future<void> _loadHistory() async {
    final me = ref.read(authProvider).valueOrNull?.email;
    if (me == null || me.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    try {
      final list =
          await ref.read(appRepositoryProvider).messages(me, widget.email);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _send() async {
    final me = ref.read(authProvider).valueOrNull?.email ?? '';
    final text = _input.text.trim();
    if (text.isEmpty || me.isEmpty) return;
    final msg = ChatMessage(
        senderEmail: me, receiverEmail: widget.email, content: text);
    final ok = ref.read(realtimeServiceProvider).send(msg);
    if (!ok) {
      setState(() => _sendError = 'Not connected. Try again in a moment.');
      return;
    }
    setState(() {
      _sendError = null;
      _input.clear();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    if (_isInbox) {
      return Scaffold(
          appBar: AppBar(title: const Text('Inbox')),
          body: _list<Conversation>(
              ref.watch(conversationsProvider),
              (x) => AppCard(
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: UserAvatar(name: x.email),
                      title: Text(x.email,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(x.latestMessage),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          c.push('/chat/${Uri.encodeComponent(x.email)}')))));
    }
    return Scaffold(
        appBar: AppBar(title: Text(widget.email)),
        body: Column(children: [
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _messages.isEmpty
                          ? const Center(child: Text('No messages yet.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) {
                                final m = _messages[i];
                                final me =
                                    ref.read(authProvider).valueOrNull?.email;
                                final mine = m.senderEmail == me;
                                return Align(
                                    alignment: mine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: mine
                                                ? Theme.of(c)
                                                    .colorScheme
                                                    .primaryContainer
                                                : Theme.of(c)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(18)),
                                        child: Text(m.content)));
                              })),
          if (_sendError != null)
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(_sendError!,
                    style: TextStyle(color: Theme.of(c).colorScheme.error))),
          SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _input,
                            decoration: const InputDecoration(
                                hintText: 'Write a message',
                                prefixIcon: Icon(Icons.edit_outlined)),
                            onSubmitted: (_) => _send())),
                    IconButton(onPressed: _send, icon: const Icon(Icons.send))
                  ])))
        ]));
  }
}

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) => _list<User>(
      r.watch(allUsersProvider),
      (u) => AppCard(
          child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(name: u.name),
              title: Text(u.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(u.email),
              trailing: FilledButton(
                  onPressed: () =>
                      r.read(appRepositoryProvider).approveAlumni(u.id),
                  child: const Text('Approve')))));
}

Widget _list<T>(AsyncValue<List<T>> v, Widget Function(T) item) => v.when(
    loading: () => const LoadingState(),
    error: (e, _) => ErrorState(message: userFacingError(e)),
    data: (x) => x.isEmpty
        ? const EmptyState(
            title: 'Nothing here yet',
            message: 'New activity will appear here when it is available.',
            icon: Icons.inbox_outlined)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: x.length,
            itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: item(x[i]))));
