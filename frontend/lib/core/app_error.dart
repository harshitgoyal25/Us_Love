enum AppErrorType { network, server, auth, client, timeout, socket, unknown }

class AppError {
  final AppErrorType type;
  final String title;
  final String message;
  final dynamic technicalDetails;
  final Function()? onRetry;

  AppError({
    required this.type,
    required this.title,
    required this.message,
    this.technicalDetails,
    this.onRetry,
  });

  factory AppError.network() => AppError(
    type: AppErrorType.network,
    title: 'Network Error',
    message:
        'Could not reach the server. Please check your internet or if the server is running.',
  );

  factory AppError.server([String? msg]) => AppError(
    type: AppErrorType.server,
    title: 'Server Error',
    message: msg ?? 'Our servers are acting up. We are looking into it!',
  );

  factory AppError.auth([String? msg]) => AppError(
    type: AppErrorType.auth,
    title: 'Authentication Failed',
    message: msg ?? 'Your session expired or credentials were incorrect.',
  );

  factory AppError.client([String? msg]) => AppError(
    type: AppErrorType.client,
    title: 'Request Error',
    message: msg ?? 'Please check your input and try again.',
  );

  factory AppError.timeout() => AppError(
    type: AppErrorType.timeout,
    title: 'Request Timeout',
    message: 'The server is taking too long to respond. Please try again.',
  );

  factory AppError.socket() => AppError(
    type: AppErrorType.socket,
    title: 'Real-time Disconnect',
    message: 'Lost connection to the game. Reconnecting...',
  );

  factory AppError.unknown([dynamic details]) => AppError(
    type: AppErrorType.unknown,
    title: 'Oops!',
    message: 'Something went wrong. Please try again.',
    technicalDetails: details,
  );
}
