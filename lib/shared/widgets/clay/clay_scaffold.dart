import 'package:cond_manager/shared/widgets/clay/clay_background.dart';
import 'package:flutter/material.dart';

class ClayScaffold extends StatelessWidget {
  const ClayScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showOrbs = true,
    this.padding,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showOrbs;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: ClayBackground(
        showOrbs: showOrbs,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (appBar != null) appBar!,
              Expanded(
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: body,
                ),
              ),
              if (bottomNavigationBar != null) bottomNavigationBar!,
            ],
          ),
        ),
      ),
    );
  }
}
