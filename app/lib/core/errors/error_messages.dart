import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'failure.dart';

/// Translate any thrown object into a short, plain-English message that's
/// safe to put in front of a user. Strips stack traces, "Exception:" prefixes,
/// and rewrites known server codes.
String friendlyError(Object? err) {
  if (err == null) return 'Something went wrong. Please try again.';

  // Known internal Failure with server code/message.
  if (err is Failure) {
    return _byCode(err.code) ??
        _byStatus(err.statusCode) ??
        _clean(err.message);
  }

  // Dio errors — translate network + status conditions.
  if (err is DioException) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Please check your internet connection and try again.';
      case DioExceptionType.connectionError:
        return 'Please check your internet connection and try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.unknown:
      case DioExceptionType.badResponse:
      default:
        final code = err.response?.data is Map
            ? err.response?.data['code']?.toString()
            : null;
        final msg = err.response?.data is Map
            ? err.response?.data['message']?.toString()
            : null;
        return _byCode(code) ??
            _byStatus(err.response?.statusCode) ??
            _clean(msg ?? '');
    }
  }

  // Generic Dart Exception — strip prefix and use the remainder if it looks safe.
  final s = err.toString();
  return _clean(s);
}

/// Show the friendly message as a snackbar, themed to match the app.
void showErrorSnack(BuildContext context, Object? err, {String? fallback}) {
  final msg = friendlyError(err).isEmpty
      ? (fallback ?? 'Something went wrong.')
      : friendlyError(err);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
}

/// Show the friendly message as a success snackbar.
void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child:
                    Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
}

String _clean(String s) {
  if (s.isEmpty) return 'Something went wrong. Please try again.';
  final stripped = s
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^Failure\([^)]*\):\s*'), '')
      .trim();
  // If it still smells technical, fall back to generic.
  final looksTechnical = stripped.contains(' at ') ||
      stripped.contains('packages/') ||
      stripped.contains('TypeError') ||
      stripped.contains('NoSuchMethodError') ||
      stripped.contains('FormatException') ||
      stripped.contains('Null check') ||
      stripped.startsWith('_');
  return looksTechnical ? 'Something went wrong. Please try again.' : stripped;
}

String? _byCode(String? code) {
  switch (code) {
    case 'INVALID_CREDENTIALS':
      return 'Wrong email or password.';
    case 'EMAIL_TAKEN':
    case 'DUPLICATE':
      return 'An account with this email already exists. Please sign in instead.';
    case 'USE_GOOGLE':
      return 'This account was created with Google Sign-In. Please use the "Continue with Google" button.';
    case 'USER_NOT_FOUND':
      return 'No account found with that email address.';
    case 'EMAIL_NOT_REGISTERED':
      // Server message already explains how to resolve — pass it through.
      return null;
    case 'OTP_COOLDOWN':
      return 'Please wait before requesting another code.';
    case 'OTP_EXPIRED':
      return 'The code has expired. Please request a new one.';
    case 'OTP_INVALID':
      return null; // use server message which includes remaining attempts
    case 'OTP_MAX_ATTEMPTS':
      return 'Too many incorrect attempts. Please request a new code.';
    case 'GOOGLE_NOT_CONFIGURED':
      return 'Google Sign-In is not available right now.';
    case 'ACCOUNT_DELETED_COOLDOWN':
      return null; // server message includes hours remaining — use it as-is
    case 'UNAUTHORIZED':
      return 'Your session has expired. Please sign in again.';
    case 'FORBIDDEN':
      return "You don't have permission to do that.";
    case 'NOT_FOUND':
      return 'We couldn\'t find what you were looking for.';
    case 'VALIDATION':
    case 'BAD_REQUEST':
      return 'Some of the details look wrong. Please double-check and try again.';
    case 'INTERNAL':
      return 'Our server hit a snag. Please try again in a moment.';
    default:
      return null;
  }
}

String? _byStatus(int? code) {
  if (code == null) return null;
  if (code == 401) return 'Your session has expired. Please sign in again.';
  if (code == 403) return "You don't have permission to do that.";
  if (code == 404) return 'We couldn\'t find what you were looking for.';
  if (code == 429) return 'Too many requests. Slow down and try again.';
  if (code >= 500)
    return 'Our server hit a snag. Please try again in a moment.';
  return null;
}
