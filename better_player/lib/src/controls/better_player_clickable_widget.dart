import 'package:flutter/material.dart';

class BetterPlayerMaterialClickableWidget extends StatelessWidget {
  const BetterPlayerMaterialClickableWidget({
    Key? key,
    required this.onTap,
    this.onLongPress,
    required this.child,
  }) : super(key: key);

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(60),
      ),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
