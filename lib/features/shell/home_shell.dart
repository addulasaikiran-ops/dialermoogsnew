import 'package:flutter/material.dart';

import '../../core/widgets/aurora_backdrop.dart';
import 'glass_nav_bar.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.pages,
    this.header,
    this.missedCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<Widget> pages;
  final Widget? header;
  final int missedCount;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuroraBackdrop(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (header != null) header!,
                Expanded(
                  child: IndexedStack(
                    index: selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInset,
            child: GlassNavBar(
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              missedCount: missedCount,
            ),
          ),
        ],
      ),
    );
  }
}
