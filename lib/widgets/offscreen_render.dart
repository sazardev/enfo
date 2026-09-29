import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Draws a widget to a PNG without putting it on screen: the widgets for the
/// home screen are pictures, and they must be producible while the app's own
/// UI is hidden or busy with something else.
///
/// It runs a private build/layout/paint pipeline (what `runApp` does, minus
/// the window) around a [RenderRepaintBoundary].
class OffscreenRenderer {
  const OffscreenRenderer._();

  /// Renders [child] into a [size] logical-pixel box at [pixelRatio]. Null if
  /// there is no view to derive metrics from (engine without a window).
  static Future<Uint8List?> png(
    Widget child, {
    required Size size,
    double pixelRatio = 2,
    ThemeData? theme,
  }) async {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return null;

    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: views.first,
      child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size * pixelRatio),
        devicePixelRatio: pixelRatio,
      ),
    );
    final pipeline = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();

    final focus = FocusManager();
    final owner = BuildOwner(focusManager: focus);
    final root = RootWidget(
      child: _Host(
        boundary: boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              devicePixelRatio: pixelRatio,
              disableAnimations: true,
            ),
            child: theme == null
                ? child
                : Theme(
                    data: theme,
                    child: Material(
                      type: MaterialType.transparency,
                      child: child,
                    ),
                  ),
          ),
        ),
      ),
    );
    final element = root.attach(owner);

    try {
      owner.buildScope(element);
      owner.finalizeTree();
      pipeline
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      // Detach the picture from the pipeline first: the framework refuses to
      // unmount a render object that is still attached.
      renderView.child = null;
      const RootWidget().attach(owner, element);
      owner.buildScope(element);
      owner.finalizeTree();
      pipeline.rootNode = null;
      renderView.dispose();
      pipeline.dispose();
      focus.dispose();
    }
  }
}

/// Mounts its child under a render object we already own, so the private
/// pipeline has something to paint (stand-in for the old
/// `RenderObjectToWidgetAdapter`).
class _Host extends RenderObjectWidget {
  const _Host({required this.boundary, required this.child});

  final RenderRepaintBoundary boundary;
  final Widget child;

  @override
  RenderObjectElement createElement() => _HostElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) => boundary;
}

class _HostElement extends RenderTreeRootElement {
  _HostElement(_Host super.widget);

  Element? _child;

  @override
  _Host get widget => super.widget as _Host;

  @override
  RenderRepaintBoundary get renderObject =>
      super.renderObject as RenderRepaintBoundary;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) visitor(_child!);
  }

  @override
  void forgetChild(Element child) {
    _child = null;
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void update(_Host newWidget) {
    super.update(newWidget);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void insertRenderObjectChild(RenderObject child, Object? slot) {
    renderObject.child = child as RenderBox;
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    Object? oldSlot,
    Object? newSlot,
  ) {
    assert(false, 'a single child never moves');
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    renderObject.child = null;
  }
}
