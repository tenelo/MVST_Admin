import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardHeightProvider extends StatefulWidget {
  final Widget Function(BuildContext context, double keyboardHeight) builder;
  const KeyboardHeightProvider({super.key, required this.builder});

  @override
  State<KeyboardHeightProvider> createState() => _KeyboardHeightProviderState();
}

class _KeyboardHeightProviderState extends State<KeyboardHeightProvider> {
  static const _channel = EventChannel('com.app.mvst_admin/keyboard_height');
  double _keyboardHeight = 0;
  late final dynamic _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _channel.receiveBroadcastStream().listen((height) {
      if (mounted) setState(() => _keyboardHeight = (height as double));
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _keyboardHeight);
}
