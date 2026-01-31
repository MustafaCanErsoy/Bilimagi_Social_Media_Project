import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Çevrimdışı durumunu gösteren banner widget
class ConnectivityIndicator extends StatefulWidget {
  final Widget child;

  const ConnectivityIndicator({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _checkConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final isOffline = result.contains(ConnectivityResult.none);
    if (isOffline != _isOffline) {
      setState(() {
        _isOffline = isOffline;
      });
      if (_isOffline) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        SizeTransition(
          sizeFactor: _animation,
          child: const _OfflineBanner(),
        ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red[700],
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Çevrimdışı - İnternet bağlantısı yok',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
