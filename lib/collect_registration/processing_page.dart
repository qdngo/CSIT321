import 'package:flutter/material.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key});

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Repeat and reverse animation
  }

  @override
  void dispose() {
    // Properly dispose of the AnimationController
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Dimensions of the big rectangle
    final double bigRectangleTop = 100; // Top margin of the big rectangle
    final double bigRectangleHeight = size.width; // Height of the big rectangle
    final double smallRectangleHeight = 200; // Height of the small rectangle

    // Calculate animation range dynamically
    final double animationStart = bigRectangleTop; // Top boundary
    final double animationEnd =
        bigRectangleTop + bigRectangleHeight - smallRectangleHeight; // Bottom boundary

    // Update animation range
    _animation = Tween<double>(
      begin: animationStart,
      end: animationEnd-90,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(15),
          width: size.width,
          height: size.height,
          child: Column(
            children: [
              Stack(
                children: [
                  // Big rectangle (card_id.png)
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Container(
                      margin: EdgeInsets.only(top: bigRectangleTop),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/card_id.png'),
                        ),
                      ),
                    ),
                  ),
                  // Animated small rectangle (process.png)
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: _animation.value-65, // Dynamic animation value
                        left: (size.width - (size.width - 30)) / 2, // Center horizontally
                        child: child!,
                      );
                    },
                    child: Container(
                      width: size.width-60,
                      height: smallRectangleHeight,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/process.png'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Processing...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
