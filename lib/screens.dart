import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models.dart';
import 'providers.dart';
import 'services.dart';
import 'widgets.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.index});
  final int index;
  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(studyDataProvider.notifier).load());
  }

  void navigate(int index) =>
      context.go(['/home', '/progress', '/achievements', '/settings'][index]);
  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const ProgressScreen(),
      const AchievementsScreen(),
      const SettingsScreen()
    ];
    return Scaffold(
      body: SafeArea(child: pages[widget.index]),
      bottomNavigationBar: NavigationBar(
          selectedIndex: widget.index,
          onDestinationSelected: navigate,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Progress'),
            NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events),
                label: 'Rewards'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
          ]),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(studyDataProvider.notifier);
    final device =
        ref.watch(deviceProvider).valueOrNull ?? const DeviceStatus();
    final today = DateTime.now();
    final minutes = data.sessions
        .where((s) =>
            s.status == SessionStatus.completed &&
            s.startedAt.day == today.day &&
            s.startedAt.month == today.month)
        .fold(0, (sum, s) => sum + s.actualMinutes);
    final greeting = today.hour < 12
        ? 'Good morning'
        : today.hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(greeting, style: Theme.of(context).textTheme.bodyLarge),
              Text('Ready to grow?',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800))
            ]),
            const PetMascot(size: 54, mood: ''),
          ]),
          const SizedBox(height: 22),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Today's focus",
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text('$minutes / 120 min',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))
                            ]),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                            value: (minutes / 120).clamp(0, 1),
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(8)),
                        const SizedBox(height: 18),
                        Row(children: [
                          const Icon(Icons.local_fire_department,
                              color: Colors.orange),
                          const SizedBox(width: 6),
                          Text('${calculateStreak(data.sessions)} day streak')
                        ]),
                      ]))),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: () => context.push('/session'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Padding(
                  padding: EdgeInsets.all(6),
                  child:
                      Text('Start studying', style: TextStyle(fontSize: 17)))),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
                child: _metric(context, Icons.timer_outlined, '$minutes min',
                    'Focused today')),
            const SizedBox(width: 12),
            Expanded(
                child: _metric(
                    context,
                    Icons.check_circle_outline,
                    '${data.sessions.where((s) => s.status == SessionStatus.completed).length}',
                    'Sessions done'))
          ]),
          const SizedBox(height: 22),
          SectionTitle('StudyPet status'),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const PetMascot(size: 62, mood: 'Watching over you'),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Hardware connection'),
                          const SizedBox(height: 8),
                          StatusPill(status: device),
                          const SizedBox(height: 6),
                          Text(
                              device.connected
                                  ? 'Monitoring is available in demo mode.'
                                  : 'You can still study without the robot.',
                              style: Theme.of(context).textTheme.bodySmall)
                        ]))
                  ]))),
          const SizedBox(height: 22),
          SectionTitle('Recent activity',
              action: 'Goals', onTap: () => context.push('/goals')),
          if (data.sessions.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                        'Your completed sessions will appear here. Start a focus session to begin your story.')))
          else
            ...data.sessions.reversed.take(3).map((s) => ListTile(
                leading: CircleAvatar(
                    child: Icon(s.status == SessionStatus.completed
                        ? Icons.check
                        : Icons.pause)),
                title: Text(s.subject),
                subtitle: Text(s.task),
                trailing: Text('${s.actualMinutes}m'))),
        ]);
  }

  Widget _metric(BuildContext c, IconData icon, String value, String label) =>
      Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Theme.of(c).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(value,
                        style: Theme.of(c)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(label)
                  ])));
}

class StartSessionScreen extends ConsumerStatefulWidget {
  const StartSessionScreen({super.key});
  @override
  ConsumerState<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends ConsumerState<StartSessionScreen> {
  final subject = TextEditingController();
  final task = TextEditingController();
  int duration = 25;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('New focus session')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const PetMascot(mood: 'Let’s make progress!'),
        const SizedBox(height: 24),
        TextField(
            controller: subject,
            decoration: const InputDecoration(
                labelText: 'Subject', hintText: 'e.g. Biology')),
        const SizedBox(height: 14),
        TextField(
            controller: task,
            decoration: const InputDecoration(
                labelText: 'What will you work on?',
                hintText: 'e.g. Review cell structure')),
        const SizedBox(height: 24),
        Text('Session duration',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
            spacing: 10,
            children: [25, 45, 60]
                .map((m) => ChoiceChip(
                    label: Text('$m min'),
                    selected: duration == m,
                    onSelected: (_) => setState(() => duration = m)))
                .toList()),
        const SizedBox(height: 30),
        FilledButton(
            onPressed: () {
              if (subject.text.trim().isEmpty || task.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Add a subject and task to begin.')));
                return;
              }
              Navigator.of(context).pop();
              context.push('/active',
                  extra: [subject.text.trim(), task.text.trim(), duration]);
            },
            child: const Padding(
                padding: EdgeInsets.all(5),
                child: Text('Begin focus session'))),
      ]));
}

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({
    super.key,
    required this.subject,
    required this.task,
    required this.duration,
  });
  final String subject;
  final String task;
  final int duration;
  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  late final DateTime started;
  Timer? timer;
  late final int duration;
  late final String subject;
  late final String task;
  BackendStatus? backendStatus;
  String? deviceError;
  bool puzzleOpen = false;
  Timer? pollTimer;
  bool ending = false;

  @override
  void initState() {
    super.initState();
    subject = widget.subject;
    task = widget.task;
    duration = widget.duration;
    started = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    Future.microtask(_startRemoteSession);
    pollTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _pollBackend());
  }

  @override
  void dispose() {
    timer?.cancel();
    pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRemoteSession() async {
    final draft = StudySession(
      id: started.microsecondsSinceEpoch.toString(),
      subject: subject,
      task: task,
      plannedMinutes: duration,
      startedAt: started,
      status: SessionStatus.active,
    );
    try {
      await ref.read(deviceServiceProvider).startSession(draft);
      if (mounted) setState(() {});
    } catch (error) {
      deviceError = 'Could not start the Raspberry Pi session: $error';
      timer?.cancel();
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Device connection failed'),
            content: Text(
                '$deviceError\n\nCheck the Pi URL and Wi-Fi connection, then try again.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        );
        if (mounted) context.pop();
      }
    }
  }

  Future<void> _pollBackend() async {
    if (ending) return;
    try {
      final status = await ref.read(deviceServiceProvider).backendStatus();
      if (!mounted) return;
      setState(() => backendStatus = status);
      if (status.puzzleRequired && !puzzleOpen) {
        puzzleOpen = true;
        await _showPuzzle();
        puzzleOpen = false;
      }
    } catch (error) {
      if (mounted && deviceError == null) {
        setState(() => deviceError = 'Raspberry Pi status unavailable: $error');
      }
    }
  }

  Future<void> _showPuzzle() async {
    final answer = TextEditingController();
    var submitting = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('StudyPet needs your attention'),
          content: TextField(
            controller: answer,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter the answer',
              hintText: 'Puzzle provided by the Raspberry Pi',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final value = int.tryParse(answer.text.trim());
                      if (value == null) return;
                      setDialogState(() => submitting = true);
                      try {
                        final correct = await ref
                            .read(deviceServiceProvider)
                            .submitPuzzleAnswer(value);
                        if (dialogContext.mounted) {
                          if (correct) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Correct. Keep focusing!')));
                          } else {
                            setDialogState(() => submitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Not quite. Try again.')));
                          }
                        }
                      } catch (error) {
                        setDialogState(() => submitting = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Puzzle error: $error')));
                        }
                      }
                    },
              child: const Text('Submit answer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> finish(bool completed) async {
    if (ending) return;
    ending = true;
    timer?.cancel();
    final actual =
        DateTime.now().difference(started).inMinutes.clamp(0, duration);
    final session = StudySession(
        id: started.microsecondsSinceEpoch.toString(),
        subject: subject,
        task: task,
        plannedMinutes: duration,
        startedAt: started,
        endedAt: DateTime.now(),
        actualMinutes: actual,
        status: completed ? SessionStatus.completed : SessionStatus.interrupted,
        points: completed ? duration : 0);
    try {
      await ref.read(deviceServiceProvider).endSession();
    } catch (error) {
      deviceError = 'Could not stop the Raspberry Pi session: $error';
    }
    await ref.read(studyDataProvider.notifier).saveSession(session);
    if (mounted) {
      context.go('/home');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(deviceError ??
              (completed
                  ? 'Session complete! +$duration points'
                  : 'Session saved as interrupted.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(started).inSeconds;
    final remaining = (duration * 60 - elapsed).clamp(0, duration * 60);
    if (remaining == 0 && !ending) Future.microtask(() => finish(true));
    final progress = elapsed / (duration * 60);
    return Scaffold(
        appBar: AppBar(title: const Text('Focus mode')),
        body: Center(
            child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
              const PetMascot(size: 96, mood: 'You’re doing great'),
              const SizedBox(height: 30),
              Text(subject,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(task, textAlign: TextAlign.center),
              const SizedBox(height: 35),
              SizedBox(
                  height: 220,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(
                        width: 210,
                        height: 210,
                        child: CircularProgressIndicator(
                            value: progress.clamp(0, 1), strokeWidth: 14)),
                    Text(
                        '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800))
                  ])),
              const SizedBox(height: 35),
              StatusPill(
                  status: ref.watch(deviceProvider).valueOrNull ??
                      const DeviceStatus()),
              const SizedBox(height: 28),
              if (backendStatus != null)
                Card(
                    child: ListTile(
                        leading: Icon(backendStatus!.puzzleRequired
                            ? Icons.warning_amber_rounded
                            : Icons.visibility_outlined),
                        title: Text(backendStatus!.studyState),
                        subtitle: Text(
                            'Eyes: ${backendStatus!.eyeState} • Alerts: ${backendStatus!.alertCount}'))),
              if (deviceError != null)
                Text(deviceError!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              OutlinedButton(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                              title: const Text('End session early?'),
                              content: const Text(
                                  'Your progress will be saved as an interrupted session.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Keep studying')),
                                FilledButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      finish(false);
                                    },
                                    child: const Text('End session'))
                              ])),
                  child: const Text('End session')),
            ])));
  }
}

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(studyDataProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Study goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGoal(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: data.goals.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                      'Create a goal to give each session a clear direction.')))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: data.goals
                  .map((goal) => Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const CircleAvatar(
                              child: Icon(Icons.flag_outlined)),
                          title: Text(goal.subject,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${goal.task}\n${goal.dailyTarget} minutes daily • ${goal.sessionDuration} minute sessions'),
                          isThreeLine: true,
                        ),
                      ))
                  .toList()),
    );
  }

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final subject = TextEditingController();
    final task = TextEditingController();
    final target = TextEditingController(text: '120');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create study goal'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 10),
          TextField(
              controller: task,
              decoration: const InputDecoration(labelText: 'Task')),
          const SizedBox(height: 10),
          TextField(
              controller: target,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Daily target (minutes)')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (result == true &&
        subject.text.trim().isNotEmpty &&
        task.text.trim().isNotEmpty) {
      await ref.read(studyDataProvider.notifier).addGoal(subject.text.trim(),
          task.text.trim(), int.tryParse(target.text) ?? 120, 25);
    }
  }
}

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(studyDataProvider.notifier);
    final completed = data.sessions
        .where((s) => s.status == SessionStatus.completed)
        .toList();
    final total = completed.fold(0, (sum, s) => sum + s.actualMinutes);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your progress',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _stat(context, '$total', 'Total minutes')),
          const SizedBox(width: 12),
          Expanded(child: _stat(context, '${completed.length}', 'Completed')),
          const SizedBox(width: 12),
          Expanded(
              child: _stat(
                  context, '${calculateStreak(data.sessions)}', 'Day streak')),
        ]),
        const SizedBox(height: 24),
        const SectionTitle('This week'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final day = DateTime.now().subtract(Duration(days: 6 - i));
                  final value = completed
                      .where((s) => s.startedAt.day == day.day)
                      .fold(0, (sum, s) => sum + s.actualMinutes);
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                            child: FractionallySizedBox(
                                heightFactor: (value / 120).clamp(.04, 1),
                                child: Container(
                                    width: 24,
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius:
                                            BorderRadius.circular(8))))),
                        const SizedBox(height: 8),
                        Text([
                          'M',
                          'T',
                          'W',
                          'T',
                          'F',
                          'S',
                          'S'
                        ][day.weekday % 7]),
                      ]);
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Session history'),
        if (data.sessions.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Complete a session to see your history.')))
        else
          ...data.sessions.reversed.map((s) => ListTile(
                leading: Icon(s.status == SessionStatus.completed
                    ? Icons.check_circle
                    : Icons.pause_circle),
                title: Text(s.subject),
                subtitle:
                    Text('${s.startedAt.month}/${s.startedAt.day} • ${s.task}'),
                trailing: Text('${s.actualMinutes} min'),
              )),
      ],
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, textAlign: TextAlign.center),
          ]),
        ),
      );
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(studyDataProvider.notifier);
    final sessions =
        data.sessions.where((s) => s.status == SessionStatus.completed).length;
    final items = [
      ('First Focus', 'Complete your first session', sessions >= 1, Icons.spa),
      ('Focus Starter', 'Complete three sessions', sessions >= 3, Icons.bolt),
      (
        'Study Champion',
        'Complete ten sessions',
        sessions >= 10,
        Icons.emoji_events
      ),
      (
        'Consistent Learner',
        'Build a five day streak',
        calculateStreak(data.sessions) >= 5,
        Icons.auto_awesome
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your rewards',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('$sessions completed sessions • ${sessions * 25} points'),
        const SizedBox(height: 24),
        ...items.map((a) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                    backgroundColor: a.$3
                        ? Colors.amber.withValues(alpha: .2)
                        : Colors.grey.withValues(alpha: .15),
                    child: Icon(a.$4,
                        color: a.$3 ? Colors.amber[800] : Colors.grey)),
                title: Text(a.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(a.$2),
                trailing: Icon(a.$3 ? Icons.check_circle : Icons.lock_outline,
                    color: a.$3 ? Colors.green : Colors.grey),
              ),
            )),
      ],
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoModeProvider);
    final baseUrl = ref.watch(apiBaseUrlProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Settings',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Card(
          child: Column(children: [
            SwitchListTile(
                title: const Text('Demo mode'),
                subtitle: const Text('Use simulated StudyPet hardware'),
                value: demo,
                onChanged: (v) {
                  ref.read(demoModeProvider.notifier).state = v;
                  ref.read(prefsProvider).setBool('demoMode', v);
                  ref.invalidate(deviceProvider);
                }),
            const ListTile(
                leading: Icon(Icons.timer_outlined),
                title: Text('Default session duration'),
                trailing: Text('25 min')),
            const ListTile(
                leading: Icon(Icons.flag_outlined),
                title: Text('Daily study goal'),
                trailing: Text('120 min')),
            const ListTile(
                leading: Icon(Icons.notifications_outlined),
                title: Text('Notifications'),
                trailing: Icon(Icons.chevron_right)),
          ]),
        ),
        const SizedBox(height: 16),
        Card(
            child: ListTile(
                leading: const Icon(Icons.router_outlined),
                title: const Text('Hardware connection'),
                subtitle: Text(
                    demo ? 'StudyPet Demo • Simulated monitoring' : baseUrl),
                onTap: () => _editConnection(context, ref),
                trailing: const Icon(Icons.chevron_right))),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Reset demo data?'),
              content: const Text(
                  'This removes saved sessions and goals on this device.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      ref.read(studyDataProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset')),
              ],
            ),
          ),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Reset demo data'),
        ),
        const SizedBox(height: 28),
        Center(
            child: Text(
                'StudyPet 1.0.0 • Your little companion for better focus.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }

  Future<void> _editConnection(BuildContext context, WidgetRef ref) async {
    final controller =
        TextEditingController(text: ref.read(apiBaseUrlProvider));
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Raspberry Pi connection'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'API base URL',
            hintText: 'http://192.168.1.50:8000',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save and test')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final normalized = result.replaceFirst(RegExp(r'/$'), '');
    await ref.read(prefsProvider).setString('apiBaseUrl', normalized);
    ref.read(apiBaseUrlProvider.notifier).state = normalized;
    ref.read(demoModeProvider.notifier).state = false;
    await ref.read(prefsProvider).setBool('demoMode', false);
    ref.invalidate(deviceProvider);
    try {
      await ref.read(deviceServiceProvider).healthCheck();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Raspberry Pi connected.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Connection failed: $error'),
            duration: const Duration(seconds: 6)));
      }
    }
  }
}
