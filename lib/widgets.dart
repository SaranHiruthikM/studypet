import 'package:flutter/material.dart';
import 'models.dart';

class PetMascot extends StatelessWidget {
  const PetMascot({super.key, this.size = 76, this.mood = 'Ready to focus'});
  final double size;
  final String mood;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle),
            child: Center(
                child: Text('🐾', style: TextStyle(fontSize: size * .48))),
          ),
          const SizedBox(height: 6),
          Text(mood, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final DeviceStatus status;
  @override
  Widget build(BuildContext context) {
    final connected = status.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color:
              (connected ? Colors.green : Colors.orange).withValues(alpha: .12),
          borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle,
            size: 9, color: connected ? Colors.green : Colors.orange),
        const SizedBox(width: 7),
        Text(connected ? (status.deviceName ?? 'Connected') : 'Device offline'),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ]);
}
