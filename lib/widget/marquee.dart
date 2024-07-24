import 'package:flutter/material.dart';

class Marquee extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Axis scrollAxis;
  final CrossAxisAlignment crossAxisAlignment;
  final double blankSpace;
  final double velocity;
  final Duration pauseAfterRound;
  final double startPadding;
  final Duration accelerationDuration;
  final Curve accelerationCurve;
  final Duration decelerationDuration;
  final Curve decelerationCurve;

  const Marquee({super.key, 
    required this.text,
    required this.style,
    this.scrollAxis = Axis.horizontal,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.blankSpace = 0.0,
    this.velocity = 50.0,
    this.pauseAfterRound = Duration.zero,
    this.startPadding = 0.0,
    this.accelerationDuration = Duration.zero,
    this.accelerationCurve = Curves.linear,
    this.decelerationDuration = Duration.zero,
    this.decelerationCurve = Curves.linear,
  });

  @override
  _MarqueeState createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMarquee();
    });
  }

  void _startMarquee() {
    double maxScrollExtent = _scrollController.position.maxScrollExtent;
    double width = context.size!.width;
    double duration = (maxScrollExtent + width) / widget.velocity;

    _animationController.duration = Duration(milliseconds: (duration * 1000).toInt());
    _animationController.repeat();

    _animationController.addListener(() {
      double offset = _animationController.value * maxScrollExtent;
      _scrollController.jumpTo(offset);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: widget.scrollAxis,
      controller: _scrollController,
      child: Row(
        crossAxisAlignment: widget.crossAxisAlignment,
        children: [
          SizedBox(width: widget.startPadding),
          Text(widget.text, style: widget.style),
          SizedBox(width: widget.blankSpace),
          Text(widget.text, style: widget.style),
        ],
      ),
    );
  }
}
