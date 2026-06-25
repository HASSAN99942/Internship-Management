import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';

/// Hits GET /api/v1/health/ and shows the result.
/// Proves the Dio client + dotenv base URL are wired correctly end-to-end.
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  _Status _status = _Status.loading;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _status = _Status.loading;
      _message = '';
    });
    try {
      final response = await apiClient.get('health/');
      setState(() {
        _status = _Status.ok;
        _message = response.data.toString();
      });
    } on ApiError catch (e) {
      setState(() {
        _status = _Status.error;
        _message = e.message;
      });
    } catch (e) {
      setState(() {
        _status = _Status.error;
        _message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internship Platform'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Retry',
            onPressed: _check,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: switch (_status) {
            _Status.loading => const CircularProgressIndicator.adaptive(),
            _Status.ok => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'API OK',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            _Status.error => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Connection failed',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _message,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _check,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}

enum _Status { loading, ok, error }
