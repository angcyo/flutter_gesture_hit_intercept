library flutter_gesture_hit_intercept;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

///
/// @author <a href="mailto:angcyo@126.com">angcyo</a>
/// @since 2024/01/31
///

/// 手势命中拦截小部件
class GestureHitInterceptScope extends SingleChildRenderObjectWidget {
  /// 获取一个上层的[GestureHitInterceptBox]
  static GestureHitInterceptBox? of(BuildContext context) {
    return context.findAncestorRenderObjectOfType<GestureHitInterceptBox>();
  }

  const GestureHitInterceptScope({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      GestureHitInterceptBox();
}

class GestureHitInterceptBox extends RenderProxyBox {
  /// 是否忽略其他盒子的命中, 前提是设置了[interceptHitBox]
  bool? ignoreOtherBoxHit;

  /// 需要拦截命中的盒子
  RenderBox? interceptHitBox;

  /// [GestureBinding.hitTestInView] -> [RenderView.hitTest] -> [RenderView.hitTestChildren]
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return super.hitTest(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return super.hitTestSelf(position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var hitBox = interceptHitBox;
    if (hitBox != null) {
      final local = hitBox.localToGlobal(Offset.zero, ancestor: this);
      result.addWithPaintOffset(
          offset: local,
          position: position,
          hitTest: (result, transformed) {
            return hitBox.hitTest(result, position: transformed);
          });
      if (ignoreOtherBoxHit ?? true) {
        return true;
      }
    }
    return super.hitTestChildren(result, position: position);
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    //debugger();
    //super.handleEvent(event, entry);
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      reset();
    }
  }

  /// 重置
  void reset() {
    interceptHitBox = null;
    ignoreOtherBoxHit = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<bool>('ignoreOtherBoxHit', ignoreOtherBoxHit));
    properties.add(
        DiagnosticsProperty<RenderBox>('interceptHitBox', interceptHitBox));
  }
}
