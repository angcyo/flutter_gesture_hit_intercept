import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gesture_hit_intercept/flutter_gesture_hit_intercept.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Widget buildItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint('点击了');
      },
      child: Container(
        height: 100,
        color: Colors.transparent,
        child: Stack(
          children: [
            const Text('在此区域的手势不会阻止`ListView`的滚动'),
            Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: FilledButton(
                    onPressed: () {
                      debugPrint('点击了');
                    },
                    child: const Text("按钮"),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GestureHitInterceptScope(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              const GestureTestWidget(),
              buildItem(context),
              for (var i = 0; i < 100; i++)
                if (i % 3 == 0)
                  const GestureTestWidget()
                else
                  buildItem(context),
            ],
          ),
        ),
      ),
    );
  }
}

class GestureTestWidget extends LeafRenderObjectWidget {
  const GestureTestWidget({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GestureTestBox(context);
  }
}

Color randomColor({int min = 120, int max = 200}) => Color.fromARGB(
      255,
      nextInt(max, min: min),
      nextInt(max, min: min),
      nextInt(max, min: min),
    );

int nextInt(int max, {int min = 0}) => min + Random().nextInt(max);

class GestureTestBox extends RenderBox {
  /// 用来保存所有的手指事件
  final pointerMap = <int, PointerEvent>{};

  /// 用来保存所有的手指颜色
  final pointerColorMap = <int, Color>{};

  BuildContext context;

  GestureTestBox(this.context);

  Color getPointerColor(int pointer) {
    return pointerColorMap.putIfAbsent(pointer, () => randomColor());
  }

  @override
  void performLayout() {
    size = Size(constraints.maxWidth, constraints.maxWidth / 2);
  }

  /// 如果为true, 会影响[PointerEvent.localPosition]位置信息
  @override
  bool get isRepaintBoundary => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    //context.canvas.drawColor(Colors.redAccent, BlendMode.src);
    final canvas = context.canvas;

    canvas.drawRect(
      Rect.fromLTWH(
        paintBounds.left + offset.dx,
        paintBounds.top + offset.dy,
        paintBounds.width,
        paintBounds.height,
      ),
      Paint()..color = Colors.grey,
    );

    TextPainter(
      text: TextSpan(
          text: "在此区域的手势会阻止`ListView`的滚动\n${pointerMap.length}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          )),
      textDirection: TextDirection.ltr,
    )
      ..layout(maxWidth: paintBounds.width)
      ..paint(canvas, offset);

    //绘制map
    const radius = 30.0;
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    //debugger();
    pointerMap.forEach((key, pointer) {
      paint.color = getPointerColor(key);
      canvas.drawLine(Offset(offset.dx, pointer.localPosition.dy),
          Offset(offset.dx + size.width, pointer.localPosition.dy), paint);
      canvas.drawLine(Offset(pointer.localPosition.dx, offset.dy),
          Offset(pointer.localPosition.dx, offset.dy + size.height), paint);
      canvas.drawCircle(pointer.localPosition, radius, paint);
    });
  }

  @override
  bool hitTestSelf(Offset position) {
    return true;
  }

  /// 只有命中通过之后, 才会回调事件
  /// [GestureBinding.handlePointerEvent] -> [GestureBinding._handlePointerEventImmediately] -> [HitTestResult.addWithPaintTransform]
  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    //debugger();

    final hitInterceptBox = GestureHitInterceptScope.of(context);
    hitInterceptBox?.interceptHitBox = this;
    if (!event.synthesized) {
      pointerMap[event.pointer] = event;
    }

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      pointerMap.remove(event.pointer);
    }
    markNeedsPaint();
    super.handleEvent(event, entry);
  }
}
