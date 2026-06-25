import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/internship.dart';
import '../data/models/task.dart';
import '../providers/tasks_providers.dart';
import 'task_card.dart';
import 'new_task_sheet.dart';
import 'submit_task_sheet.dart';

/// Tasks tab body shown inside the internship detail screen.
class TasksSection extends ConsumerWidget {
  const TasksSection({
    super.key,
    required this.internship,
  });
  final Internship internship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isStudent = user?.id == internship.student.id;
    final isSupervisor = user?.id == internship.company.id ||
        user?.id == internship.teacher?.id;
    final isActive = internship.status == 'active';

    final async = ref.watch(tasksProvider(internship.id));

    return async.when(
      loading: () => const _TasksSkeleton(),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () =>
            ref.read(tasksProvider(internship.id).notifier).load(),
      ),
      data: (tasks) => _TasksList(
        tasks: tasks,
        internship: internship,
        isStudent: isStudent,
        isSupervisor: isSupervisor,
        isActive: isActive,
      ),
    );
  }
}

class _TasksList extends ConsumerWidget {
  const _TasksList({
    required this.tasks,
    required this.internship,
    required this.isStudent,
    required this.isSupervisor,
    required this.isActive,
  });

  final List<Task> tasks;
  final Internship internship;
  final bool isStudent;
  final bool isSupervisor;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        if (tasks.isEmpty)
          _EmptyState(
            message: isSupervisor && isActive
                ? 'No tasks yet. Tap + to create one.'
                : 'No tasks have been assigned yet.',
          )
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final task = tasks[i];
              return TaskCard(
                task: task,
                onSubmit: isStudent &&
                        isActive &&
                        (task.status == 'open' ||
                            task.status == 'changes_requested')
                    ? () => SubmitTaskSheet.show(
                        context, internship.id, task)
                    : null,
                onValidate: isSupervisor &&
                        isActive &&
                        task.status == 'submitted'
                    ? () => _confirmValidate(context, ref, task)
                    : null,
                onRequestChanges: isSupervisor &&
                        isActive &&
                        task.status == 'submitted'
                    ? () => _confirmRequestChanges(context, ref, task)
                    : null,
              );
            },
          ),
        // FAB for supervisor to create tasks
        if (isSupervisor && isActive)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'new_task_fab',
              onPressed: () =>
                  NewTaskSheet.show(context, internship.id),
              icon: const Icon(Icons.add),
              label: const Text('New task'),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmValidate(
      BuildContext context, WidgetRef ref, Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validate task?'),
        content: Text('Mark "${task.title}" as validated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Validate')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref
            .read(tasksProvider(internship.id).notifier)
            .validateTask(task.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _confirmRequestChanges(
      BuildContext context, WidgetRef ref, Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request changes?'),
        content: Text('The student will be asked to resubmit "${task.title}".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Request changes')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref
            .read(tasksProvider(internship.id).notifier)
            .requestChanges(task.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())));
        }
      }
    }
  }
}

class _TasksSkeleton extends StatelessWidget {
  const _TasksSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 88,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ],
      ),
    );
  }
}
