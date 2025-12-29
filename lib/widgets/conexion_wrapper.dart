import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConexionWrapper extends StatefulWidget {
  final Widget child;
  const ConexionWrapper({required this.child, super.key});

  @override
  State<ConexionWrapper> createState() => _ConexionWrapperState();
}

class _ConexionWrapperState extends State<ConexionWrapper> {
  late StreamSubscription<ConnectivityResult> _sub;
  bool _sinConexion = false;

  @override
  void initState() {
    super.initState();
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        // Mostrar banner cuando no haya datos moviles
        _sinConexion = result != ConnectivityResult.mobile;
      });
    });
    // chequeo inicial
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _sinConexion = result != ConnectivityResult.mobile;
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_sinConexion)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Material(
              color: Colors.red,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: const Center(
                    child: Text('Sin conexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
