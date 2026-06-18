import 'package:flutter/material.dart';

/// Shows a dialog deferred to the next rendering frame.
///
/// On iOS, calling [showDialog] while a provider rebuild is pending installs
/// the [ModalBarrier] before dialog content is positioned — the barrier
/// absorbs all touches invisibly, freezing the app. Awaiting
/// [WidgetsBinding.instance.endOfFrame] lets pending rebuilds settle first.
///
/// Use this instead of [showDialog] whenever the call may follow a state
/// change (provider notification, setState, or any awaited operation).
Future<T?> showDialogDeferred<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) async {
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return null;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}
