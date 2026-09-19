import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/providers.dart';
import '../shared/models/models.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext c) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});
  @override
  Widget build(BuildContext c) => const Scaffold(
      body: Center(child: Text('Your account is pending approval.')));
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
                              minHeight: constraints.maxHeight),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Alumni Connect',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                TextField(
                                    controller: _email,
                                    decoration: const InputDecoration(
                                        labelText: 'Email')),
                                TextField(
                                    controller: _pass,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Password')),
                                const SizedBox(height: 8),
                                InputDecorator(
                                    decoration: const InputDecoration(
                                        labelText: 'Role'),
                                    child: DropdownButtonHideUnderline(
                                        child: DropdownButton<UserRole>(
                                            value: _role,
                                            isExpanded: true,
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
                                                  }))),
                                if (_error != null) ...[
                                  const SizedBox(height: 8),
                                  Text(_error!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error)),
                                ],
                                const SizedBox(height: 12),
                                FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () async {
                                            setState(() {
                                              _busy = true;
                                              _error = null;
                                            });
                                            final x = await ref
                                                .read(authProvider.notifier)
                                                .signIn(_email.text.trim(),
                                                    _pass.text, _role);
                                            if (!context.mounted) return;
                                            setState(() => _busy = false);
                                            if (x == 'WAIT_APPROVAL') {
                                              context.go('/pending-approval');
                                            } else if (x != null) {
                                              setState(() => _error = x);
                                            }
                                          },
                                    child: Text(_busy
                                        ? 'Signing in…'
                                        : 'Sign in')),
                                TextButton(
                                    onPressed: () => context.go('/register'),
                                    child: const Text('Create account')),
                                TextButton(
                                    onPressed: () =>
                                        context.go('/forgot-password'),
                                    child: const Text('Forgot password?'))
                              ])));
                }))));
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final n = TextEditingController(),
        e = TextEditingController(),
        p = TextEditingController();
    return Scaffold(
        appBar: AppBar(),
        body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              TextField(
                  controller: n,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: e,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: p,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password')),
              FilledButton(
                  onPressed: () async {
                    await ProviderScope.containerOf(c)
                        .read(appRepositoryProvider)
                        .signup(
                            User(
                                id: 0,
                                name: n.text,
                                email: e.text,
                                role: UserRole.student,
                                status: 'PENDING'),
                            p.text);
                    if (c.mounted) {
                      c.go('/login');
                    }
                  },
                  child: const Text('Submit for approval'))
            ])));
  }
}

class PasswordScreen extends StatelessWidget {
  const PasswordScreen({super.key, this.forgot = false});
  final bool forgot;
  @override
  Widget build(BuildContext c) {
    final e = TextEditingController(), p = TextEditingController();
    return Scaffold(
        appBar: AppBar(),
        body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              TextField(
                  controller: e,
                  decoration: const InputDecoration(labelText: 'Email')),
              if (!forgot)
                TextField(
                    controller: p,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'New password')),
              FilledButton(
                  onPressed: () async {
                    final repo = ProviderScope.containerOf(c)
                        .read(appRepositoryProvider);
                    if (forgot) {
                      await repo.forgotPassword(e.text);
                    } else {
                      await repo.resetPassword(e.text, p.text);
                    }
                    if (c.mounted) {
                      c.go(forgot ? '/otp-verify' : '/login');
                    }
                  },
                  child: Text(forgot ? 'Send OTP' : 'Reset password'))
            ])));
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
                  decoration: const InputDecoration(labelText: 'OTP')),
              FilledButton(
                  onPressed: () async {
                    await ProviderScope.containerOf(c)
                        .read(appRepositoryProvider)
                        .verifyOtp(e.text, o.text);
                    if (c.mounted) {
                      c.go('/reset-password');
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
              for (final t in tabs)
                NavigationDestination(
                    icon: const Icon(Icons.circle_outlined), label: t)
            ],
            onDestinationSelected: (i) => c.go('/${role.name}/${tabs[i]}')));
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext c) =>
      ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Welcome to Alumni Connect',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Wrap(spacing: 12, children: [
          OutlinedButton(
              onPressed: () => c.push('/connections'),
              child: const Text('Connections')),
          OutlinedButton(
              onPressed: () => c.push('/chat/inbox'),
              child: const Text('Inbox'))
        ])
      ]);
}

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) => _list<User>(
      r.watch(directoryProvider(UserRole.alumni)),
      (u) => ListTile(
          title: Text(u.name),
          subtitle: Text(u.email),
          onTap: () => c.push('/user/${u.id}')));
}

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) => _list<EventItem>(
      r.watch(eventsProvider),
      (e) => ListTile(
          title: Text(e.title),
          subtitle: Text(e.eventDate ?? ''),
          onTap: () => c.push('/event/${e.id}')));
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) {
    final u = r.watch(authProvider).valueOrNull;
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(u?.email ?? ''),
      OutlinedButton(
          onPressed: () => r.read(authProvider.notifier).signOut(),
          child: const Text('Sign out'))
    ]));
  }
}

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) => Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: _list<ConnectionItem>(
          r.watch(connectionsProvider),
          (x) => ListTile(
              title:
                  Text(x.requester?.name ?? x.receiver?.name ?? 'Connection'),
              subtitle: Text(x.status))));
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef r) => Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _list<NotificationItem>(
          r.watch(notificationsProvider),
          (n) => ListTile(
              title: Text(n.message),
              leading: Icon(
                  n.isRead ? Icons.notifications_none : Icons.notifications))));
}

class UserScreen extends ConsumerWidget {
  const UserScreen({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext c, WidgetRef r) => Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<User>(
          future: r.read(appRepositoryProvider).user(id),
          builder: (_, s) => s.hasData
              ? Center(child: Text(s.data!.name))
              : const Center(child: CircularProgressIndicator())));
}

class EventScreen extends StatelessWidget {
  const EventScreen({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext c) =>
      Scaffold(appBar: AppBar(), body: Center(child: Text('Event #$id')));
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
              (x) => ListTile(
                  title: Text(x.email),
                  subtitle: Text(x.latestMessage),
                  onTap: () => c.push('/chat/${x.email}'))));
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
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            color: mine
                                                ? Theme.of(c)
                                                    .colorScheme
                                                    .primaryContainer
                                                : Theme.of(c)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(8)),
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
                                hintText: 'Type a message',
                                border: OutlineInputBorder()),
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
      (u) => ListTile(
          title: Text(u.name),
          trailing: FilledButton(
              onPressed: () =>
                  r.read(appRepositoryProvider).approveAlumni(u.id),
              child: const Text('Approve'))));
}

Widget _list<T>(AsyncValue<List<T>> v, Widget Function(T) item) => v.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text('$e')),
    data: (x) => x.isEmpty
        ? const Center(child: Text('Nothing here yet.'))
        : ListView.builder(
            itemCount: x.length, itemBuilder: (_, i) => item(x[i])));
