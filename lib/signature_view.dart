import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/parser.dart';
import 'package:hand_signature/signature_control.dart';
import 'package:hand_signature/signature_painter.dart';

import 'path_math.dart';

class HandSignaturePainterView extends StatelessWidget {
  final Color color;
  final double width;
  final Widget placeholder;
  final HandSignatureControl control;

  HandSignaturePainterView({
    Key key,
    @required this.control,
    this.color: Colors.black,
    this.width: 1.0,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          _SinglePanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_SinglePanGestureRecognizer>(
            () => _SinglePanGestureRecognizer(debugOwner: this),
            (PanGestureRecognizer instance) {
              instance.onStart = (args) => control.startPath(args.localPosition);
              instance.onUpdate = (args) => control.alterPath(args.localPosition);
              instance.onEnd = (args) => control.closePath();
            },
          ),
        },
        child: HandSignaturePaint(
          control: control,
          color: color,
          width: width,
          onSize: control.notifyDimension,
        ),
      ),
    );
  }
}

class HandSignatureView extends StatelessWidget {
  final List<Path> data;
  final Color color;
  final double width;
  final EdgeInsets padding;
  final Widget placeholder;

  const HandSignatureView({
    Key key,
    @required this.data,
    this.color,
    this.width,
    this.padding,
    this.placeholder,
  }) : super(key: key);

  static _HandSignatureViewSvg svg({
    Key key,
    @required String data,
    Color color,
    double width,
    EdgeInsets padding,
    Widget placeholder,
  }) =>
      _HandSignatureViewSvg(
        key: key,
        data: data,
        color: color,
        width: width,
        padding: padding,
        placeholder: placeholder,
      );

  @override
  Widget build(BuildContext context) {
    if (data == null || data.isEmpty) {
      return placeholder ??
          Container(
            color: Theme.of(context).backgroundColor,
          );
    }

    return Padding(
      padding: padding ?? EdgeInsets.all(16.0),
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: SizedBox.fromSize(
          size: OffsetMath.pathBoundsOf(data).size,
          child: CustomPaint(
            painter: HandSignaturePainter(
              paths: data,
              color: color ?? Colors.black,
              width: width ?? 2.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _HandSignatureViewSvg extends StatefulWidget {
  final String data;
  final Color color;
  final double width;
  final EdgeInsets padding;
  final Widget placeholder;

  const _HandSignatureViewSvg({
    Key key,
    @required this.data,
    this.color,
    this.width,
    this.padding,
    this.placeholder,
  }) : super(key: key);

  @override
  _HandSignatureViewSvgState createState() => _HandSignatureViewSvgState();
}

class _HandSignatureViewSvgState extends State<_HandSignatureViewSvg> {
  List<Path> paths;

  @override
  void initState() {
    super.initState();

    _parseData(widget.data);
  }

  void _parseData(String data) async {
    if (data == null) {
      paths = null;
    } else {
      final parser = SvgParser();
      final root = await parser.parse(data);

      if (root == null) {
        paths = null;
        return;
      }

      paths = OffsetMath.parseDrawable(root);
    }

    setState(() {});
  }

  @override
  void didUpdateWidget(_HandSignatureViewSvg oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data != widget.data) {
      if (paths != null) {
        setState(() {
          paths = null;
        });
      }

      _parseData(widget.data);
    }
  }

  @override
  Widget build(BuildContext context) => HandSignatureView(
        data: paths,
        color: widget.color,
        width: widget.width,
        padding: widget.padding,
        placeholder: widget.placeholder,
      );
}

class _SinglePanGestureRecognizer extends PanGestureRecognizer {
  _SinglePanGestureRecognizer({Object debugOwner}) : super(debugOwner: debugOwner);

  bool isDown = false;

  @override
  void addAllowedPointer(PointerEvent event) {
    if (isDown) {
      return;
    }

    isDown = true;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);

    if (!event.down) {
      isDown = false;
    }
  }
}
