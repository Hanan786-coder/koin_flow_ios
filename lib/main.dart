import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo.dart';
import 'home.dart';
import 'ios.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  // The preview build shows the app inside an iPhone frame.
  runApp(
    kDemo ? const IPhoneFrame(child: KoinFlowBoot()) : const KoinFlowBoot(),
  );
}

class KoinFlowApp extends StatelessWidget {
  const KoinFlowApp({super.key, this.now});

  /// Injected clock for tests.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Koin Flow',
    theme: K.theme(),
    darkTheme: K.theme(),
    themeMode: ThemeMode.dark,
    home: HomePage(now: now),
  );
}

/// The app plus a short splash: the coin settles, then the ledger fades in.
class KoinFlowBoot extends StatefulWidget {
  const KoinFlowBoot({super.key});

  @override
  State<KoinFlowBoot> createState() => _KoinFlowBootState();
}

class _KoinFlowBootState extends State<KoinFlowBoot>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Stack(
      children: [
        const KoinFlowApp(),
        if (!_done)
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final enter = Curves.easeOutBack.transform(
                (t / .55).clamp(0.0, 1.0),
              );
              final exit = Curves.easeInCubic.transform(
                ((t - .72) / .28).clamp(0.0, 1.0),
              );
              return IgnorePointer(
                ignoring: t > .8,
                child: Opacity(
                  opacity: 1 - exit,
                  child: ColoredBox(
                    color: K.ledger,
                    child: Center(
                      child: Transform.scale(
                        scale: 1 + exit * .25,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform(
                              alignment: Alignment.center,
                              // A coin turning to face you.
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, .0015)
                                ..rotateY((1 - enter) * 1.4),
                              child: Opacity(
                                opacity: enter.clamp(0.0, 1.0),
                                child: const KoinLogo(size: 84),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Opacity(
                              opacity: ((t - .2) / .3).clamp(0.0, 1.0),
                              child: Text(
                                'Koin Flow',
                                style: K.display(30, color: K.brass),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}
