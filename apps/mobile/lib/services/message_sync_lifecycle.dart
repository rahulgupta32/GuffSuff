import 'package:flutter/widgets.dart';
import 'message_sync.dart';

class MessageSyncLifecycle extends StatefulWidget {
  final MessageSync sync;
  final Widget child;
  const MessageSyncLifecycle({
    super.key,
    required this.sync,
    required this.child,
  });
  @override
  State<MessageSyncLifecycle> createState() => _MessageSyncLifecycleState();
}

class _MessageSyncLifecycleState extends State<MessageSyncLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.sync.setForeground(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.sync.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.sync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
