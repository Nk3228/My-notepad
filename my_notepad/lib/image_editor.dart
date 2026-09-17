import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ImageEditor extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageEditor({
    super.key,
    required this.imageBytes,
  });

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _DrawingPoint {
  final Offset point;
  final Paint paint;

  _DrawingPoint(this.point, this.paint);
}

class _ImageEditorState extends State<ImageEditor> {
  final GlobalKey _boundaryKey = GlobalKey();

  final List<List<_DrawingPoint>> _strokes = [];
  final List<List<_DrawingPoint>> _redo = [];

  Color _color = Colors.red;
  double _width = 4;

  void _startStroke(Offset point) {
    _redo.clear();

    final paint = Paint()
      ..color = _color
      ..strokeWidth = _width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    setState(() {
      _strokes.add([
        _DrawingPoint(point, paint),
      ]);
    });
  }

  void _updateStroke(Offset point) {
    if (_strokes.isEmpty) return;

    setState(() {
      _strokes.last.add(
        _DrawingPoint(point, _strokes.last.first.paint),
      );
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;

    setState(() {
      _redo.add(_strokes.removeLast());
    });
  }

  void _redoStroke() {
    if (_redo.isEmpty) return;

    setState(() {
      _strokes.add(_redo.removeLast());
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _redo.clear();
    });
  }

  Future<void> _done() async {
    try {
      final boundary = _boundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return;

      if (!mounted) return;

      Navigator.pop(
        context,
        byteData.buffer.asUint8List(),
      );
    } catch (e) {
      debugPrint('Image save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _strokes.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _redo.isEmpty ? null : _redoStroke,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: _strokes.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _boundaryKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanStart: (details) {
                        _startStroke(details.localPosition);
                      },
                      onPanUpdate: (details) {
                        _updateStroke(details.localPosition);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.contain,
                          ),
                          CustomPaint(
                            painter: _DrawingPainter(
                              strokes: _strokes,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Text('Pen:'),
                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: () {
                      setState(() => _color = Colors.red);
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.red,
                      child: _color == Colors.red
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: () {
                      setState(() => _color = Colors.blue);
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: _color == Colors.blue
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: () {
                      setState(() => _color = Colors.black);
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black,
                      child: _color == Colors.black
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),

                  const Spacer(),

                  FilledButton.icon(
                    onPressed: _done,
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<_DrawingPoint>> strokes;

  _DrawingPainter({
    required this.strokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;

      final path = Path();

      path.moveTo(
        stroke.first.point.dx,
        stroke.first.point.dy,
      );

      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(
          stroke[i].point.dx,
          stroke[i].point.dy,
        );
      }

      canvas.drawPath(
        path,
        stroke.first.paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return true;
  }
}
