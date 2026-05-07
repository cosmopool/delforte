import "dart:async";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/app_shell.dart";
import "package:delforte/router/app_route_state.dart";
import "package:delforte/router/app_router.dart";
import "package:delforte/store/quote_store.dart";
import "package:flutter/material.dart";

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Delforte",
      theme: VigilTheme.light(),
      home: const AppMainWidget(),
    );
  }
}

enum StoreState { opening, opened, error }

class AppMainWidget extends StatefulWidget {
  const AppMainWidget({super.key});

  @override
  State<AppMainWidget> createState() => _AppMainWidgetState();
}

class _AppMainWidgetState extends State<AppMainWidget> {
  final QuoteStore _store = QuoteStore();
  late final AppRouterDelegate _router = AppRouterDelegate(store: _store);

  StoreState _storeState = .opening;

  @override
  void initState() {
    super.initState();
    unawaited(_openStore());
  }

  Future<void> _openStore() async {
    final bool opened = await _store.open();
    if (opened) _seedEmptyStore();
    if (!mounted) return;
    setState(() => _storeState = opened ? .opened : .error);
  }

  void _seedEmptyStore() {
    if (_store.clients.count == 0) {
      _store.addClient("Residencial Oliveira", "(11) 98888-1010", "", "Rua das Flores, 142");
      _store.addClient("Comercio Santos", "(11) 97777-2020", "", "Av. Central, 88 - Bloco B");
      _store.addClient("Casa Joao Silva", "(11) 96666-3030", "", "Estrada do Morro, 55");
    }
    if (_store.services.count == 0) {
      _store.addService("CCTV Installation", "Camera installation and setup", 60000);
      _store.addService("Alarm System Setup", "Panel, sensors, and configuration", 40000);
      _store.addService("Gate Motor Install", "Gate motor installation labor", 20000);
    }
    if (_store.items.count == 0) {
      _store.addItem("IP Camera 4MP", "Outdoor infrared camera", 35000);
      _store.addItem("Gate Motor Kit", "Motor, remotes, and rails", 85000);
      _store.addItem("Control Panel Pro", "Alarm and automation control panel", 95000);
    }
  }

  @override
  void dispose() {
    _router.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_storeState) {
      case .opening:
        return AppShell(body: const Center(child: CircularProgressIndicator()));

      case .opened:
        return Router<AppRoute>(
          routerDelegate: _router,
          backButtonDispatcher: RootBackButtonDispatcher(),
        );

      case .error:
        final String error = _store.latestErrorMessage();
        return AppShell(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
                const SizedBox(height: 12),
                Text(
                  error.isEmpty ? "Could not open the quote database." : error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: VigilColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _storeState = .opening);
                    unawaited(_openStore());
                  },
                  child: const Text("Try again"),
                ),
              ],
            ),
          ),
        );
    }
  }
}
