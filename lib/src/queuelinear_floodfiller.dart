//Original algorithm by J. Dunlap queuelinearfloodfill.aspx
//Java port by Owen Kaluza
//Android port by Darrin Smith (Standard Android)
//Flutter port by Garlen Javier

import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:image/image.dart' as img;

class QueueLinearFloodFiller {
  img.Image? image;
  int _width = 0;
  int _height = 0;
  int _cachedWidth = -1;
  int _cachedHeight = -1;
  img.ColorInt8 _fillColor = img.ColorInt8.rgba(0, 0, 0, 0);
  int _tolerance = 8;
  img.ColorInt8 _startColor = img.ColorInt8.rgba(0, 0, 0, 0);
  List<bool>? _pixelsChecked;
  Queue<_FloodFillRange>? _ranges;

  QueueLinearFloodFiller(img.Image imgVal, Color newColor) {
    image = imgVal;
    _width = image!.width;
    _height = image!.height;
    setFillColor(newColor);
  }

  void resize(Size size) {
    if (_cachedWidth != size.width.toInt() ||
        _cachedHeight != size.height.toInt()) {
      //image = img.copyResize(image!, width: size.width.toInt(), height: size.height.toInt());
      _width = image!.width;
      _height = image!.height;
      _cachedWidth = _width;
      _cachedHeight = _height;
    }
  }

  void setTargetColor(Color targetColor) {
    _startColor = img.ColorInt8.rgba(
      targetColor.red,
      targetColor.green,
      targetColor.blue,
      targetColor.alpha,
    );
  }

  void setTolerance(int value) {
    _tolerance = value.clamp(0, 100);
  }

  Color getFillColor() {
    return Color.fromARGB(
      _fillColor.a.toInt(),
      _fillColor.r.toInt(),
      _fillColor.g.toInt(),
      _fillColor.b.toInt(),
    );
  }

  void setFillColor(Color value) {
    _fillColor = img.ColorInt8.rgba(
      value.red, value.green, value.blue, value.alpha,
    );
  }

  void _prepare() {
    // Called before starting flood-fill
    _pixelsChecked = List<bool>.filled(_width * _height, false);
    _ranges = Queue<_FloodFillRange>();
  }

  // Fills the specified point on the bitmap with the currently selected fill
  // color.
  // int x, int y: The starting coords for the fill
  Future<void> floodFill(int x, int y) async {
    // Setup
    _prepare();

    if (_startColor == Color(0)) {
      // ***Get starting color.
      img.Pixel startPixel = image!.getPixelSafe(x, y);

      _startColor = img.ColorInt8.rgba(
        startPixel.getChannel(img.Channel.red).toInt(),
        startPixel.getChannel(img.Channel.green).toInt(),
        startPixel.getChannel(img.Channel.blue).toInt(),
        startPixel.getChannel(img.Channel.alpha).toInt(),
      );
    }

    // ***Do first call to floodfill.
    _linearFill(x, y);

    // ***Call floodfill routine while floodfill _ranges still exist on the
    // queue
    _FloodFillRange range;

    while (_ranges!.length > 0) {
      // **Get Next Range Off the Queue
      range = _ranges!.removeFirst();

      // **Check Above and Below Each Pixel in the Floodfill Range
      int downPxIdx = (_width * (range.y + 1)) + range.startX;
      int upPxIdx = (_width * (range.y - 1)) + range.startX;
      int upY = range.y - 1; // so we can pass the y coord by ref
      int downY = range.y + 1;

      for (int i = range.startX; i <= range.endX; i++) {
        // *Start Fill Upwards
        // if we're not above the top of the bitmap and the pixel above
        // this one is within the color tolerance

        if (range.y > 0 && (!_pixelsChecked![upPxIdx]) && _checkPixel(i, upY)) {
          _linearFill(i, upY);
        }

        // *Start Fill Downwards
        // if we're not below the bottom of the bitmap and the pixel
        // below this one is within the color tolerance
        if (range.y < (_height - 1) &&
            (!_pixelsChecked![downPxIdx]) &&
            _checkPixel(i, downY)) {
          _linearFill(i, downY);
        }

        downPxIdx++;
        upPxIdx++;
      }
    }
  }

  // Finds the furthermost left and right boundaries of the fill area
  // on a given y coordinate, starting from a given x coordinate, filling as
  // it goes.
  // Adds the resulting horizontal range to the queue of floodfill _ranges,
  // to be processed in the main loop.
  //
  // int x, int y: The starting coords
  void _linearFill(int x, int y) {
    // ***Find Left Edge of Color Area
    int lFillLoc = x; // the location to check/fill on the left
    int pxIdx = (_width * y) + x;
    while (true) {
      // **fill with the color
      //pixels[pxIdx] = _fillColor;
      image?.setPixel(lFillLoc, y, _fillColor);

      // **indicate that this pixel has already been checked and filled
      _pixelsChecked![pxIdx] = true;

      // **de-increment
      lFillLoc--; // de-increment counter
      pxIdx--; // de-increment pixel index

      // **exit loop if we're at edge of bitmap or color area
      if (lFillLoc < 0 ||
          (_pixelsChecked![pxIdx]) ||
          !_checkPixel(lFillLoc, y)) {
        break;
      }
    }

    lFillLoc++;

    // ***Find Right Edge of Color Area
    int rFillLoc = x; // the location to check/fill on the left
    pxIdx = (_width * y) + x;

    while (true) {
      // **fill with the color
      image?.setPixel(rFillLoc, y, _fillColor);

      // **indicate that this pixel has already been checked and filled
      _pixelsChecked![pxIdx] = true;

      // **increment
      rFillLoc++; // increment counter
      pxIdx++; // increment pixel index

      // **exit loop if we're at edge of bitmap or color area
      if (rFillLoc >= _width ||
          _pixelsChecked![pxIdx] ||
          !_checkPixel(rFillLoc, y)) {
        break;
      }
    }

    rFillLoc--;
    // add range to queue
    _FloodFillRange r = new _FloodFillRange(lFillLoc, rFillLoc, y);
    _ranges?.add(r);
  }

  // Sees if a pixel is within the color tolerance range.
  bool _checkPixel(int x, int y) {
    img.Pixel pixelColor = image!.getPixelSafe(x, y);
    int red = pixelColor.getChannel(img.Channel.red).toInt();
    int green = pixelColor.getChannel(img.Channel.green).toInt();
    int blue = pixelColor.getChannel(img.Channel.blue).toInt();
    int alpha = pixelColor.getChannel(img.Channel.alpha).toInt();

    return (red >= (_startColor[0] - _tolerance) &&
        red <= (_startColor[0] + _tolerance) &&
        green >= (_startColor[1] - _tolerance) &&
        green <= (_startColor[1] + _tolerance) &&
        blue >= (_startColor[2] - _tolerance) &&
        blue <= (_startColor[2] + _tolerance) &&
        alpha >= (_startColor[3] - _tolerance) &&
        alpha <= (_startColor[3] + _tolerance));
  }
}

// Represents a linear range to be filled and branched from.
class _FloodFillRange {
  int startX = -1;
  int endX = -1;
  int y = -1;

  _FloodFillRange(int startX, int endX, int yPos) {
    this.startX = startX;
    this.endX = endX;
    this.y = yPos;
  }
}
