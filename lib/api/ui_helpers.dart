import 'package:flutter/material.dart';

import 'api_client.dart';

/// Show a backend error (or any exception) as a snackbar.
void showApiError(BuildContext context, Object error) {
  final message = error is ApiException
      ? error.message
      : 'Network error — is the server reachable?';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFB3261E),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF1E1E1E),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// A tiny white spinner sized for buttons.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2.2, color: Colors.white),
      );
}
