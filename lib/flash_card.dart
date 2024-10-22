library flash_card;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class FlashCardController {
  /// Allow control flip card
  /// if return true, card is front
  /// else card is back
  late Future<bool> Function() toggleSide;
}

/// UI flash card, commonly found in language teaching to children
class FlashCard extends StatefulWidget {
  /// constructor: Default height 200dp, width 200dp, duration  500 milliseconds
  const FlashCard({
    required this.frontWidget,
    required this.backWidget,
    Key? key,
    this.duration = const Duration(milliseconds: 500),
    this.height = 200,
    this.width = 200,
    this.controller,
  }) : super(key: key);

  /// this is the front of the card
  final Widget Function() frontWidget;

  /// this is the back of the card
  final Widget Function() backWidget;

  /// flip time
  final Duration duration;

  /// height of card
  final double height;

  /// width of card
  final double width;

  final FlashCardController? controller;

  @override
  _FlashCardState createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard>
    with SingleTickerProviderStateMixin {
  /// controller flip animation
  late AnimationController _controller;

  /// animation for flip from front to back
  late Animation<double> _frontAnimation;

  ///animation for flip from back  to front
  late Animation<double> _backAnimation;

  /// state of card is front or back
  bool isFrontVisible = true;

  Completer<bool>? _completer;
  late Widget backWidget;
  late Widget frontWidget;

  @override
  void initState() {
    super.initState();
    backWidget = widget.backWidget.call();
    frontWidget = widget.frontWidget.call();
    if (widget.controller != null) {
      widget.controller!.toggleSide = _toggleSide;
    }
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _frontAnimation = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.0, end: math.pi / 2)
              .chain(CurveTween(curve: Curves.linear)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(math.pi / 2),
          weight: 50.0,
        ),
      ],
    ).animate(_controller);

    _backAnimation = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(math.pi / 2),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: -math.pi / 2, end: 0.0)
              .chain(CurveTween(curve: Curves.linear)),
          weight: 50.0,
        ),
      ],
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FlashCard oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller!.toggleSide = _toggleSide;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleSide,
          child: AnimatedCard(
            animation: _frontAnimation,
            child: backWidget,
            height: widget.height,
            width: widget.width,
          ),
        ),
        GestureDetector(
          onTap: _toggleSide,
          child: AnimatedCard(
            animation: _backAnimation,
            child: frontWidget,
            height: widget.height,
            width: widget.width,
          ),
        ),
      ],
    );
  }

  /// when user onTap, It will run function
  Future<bool> _toggleSide() async {
    backWidget = widget.backWidget.call();
    frontWidget = widget.frontWidget.call();
    setState(() {});
    _completer = Completer<bool>();
    if (isFrontVisible) {
      isFrontVisible = false;
      await _controller.forward().then((_) {
        _completer?.complete(true);
      });
    } else {
      isFrontVisible = true;
      await _controller.reverse().then((_) {
        _completer?.complete(false);
      });
    }

    return _completer!.future;
  }
}

class AnimatedCard extends StatelessWidget {
  AnimatedCard(
      {required this.child,
      required this.animation,
      required this.height,
      required this.width,
      Key? key})
      : super(key: key);

  final Widget child;
  final Animation<double> animation;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: _builder,
      child: SizedBox(
        height: height,
        width: width,
        child: Card(
          elevation: 0,
          color: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          borderOnForeground: false,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _builder(BuildContext context, Widget? child) {
    var transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.001);
    transform.rotateY(animation.value);
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: child,
    );
  }
}
