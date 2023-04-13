import 'package:flutter/material.dart';
import 'package:vts_component/common/extension/pain_ext.dart';
import 'package:vts_component/components/line_chart_style_1/utils.dart';

import '../base_chart/base_chart_data.dart';
import '../base_chart/base_chart_painter.dart';
import '../canvas_wrapper.dart';
import 'axis_chart_helper.dart';
import 'axit_chart_data.dart';


abstract class AxisChartPainter<D extends AxisChartData>
    extends BaseChartPainter<D> {
  AxisChartPainter() : super() {
    _gridPaint = Paint()..style = PaintingStyle.stroke;

    _backgroundPaint = Paint()..style = PaintingStyle.fill;

    _rangeAnnotationPaint = Paint()..style = PaintingStyle.fill;

    _extraLinesPaint = Paint()..style = PaintingStyle.stroke;

    _imagePaint = Paint();
  }
  late Paint _gridPaint;
  late Paint _backgroundPaint;
  late Paint _extraLinesPaint;
  late Paint _imagePaint;

  late Paint _rangeAnnotationPaint;


  @override
  void paint(
      BuildContext context,
      CanvasWrapper canvasWrapper,
      PaintHolder<D> holder,
      ) {
    super.paint(context, canvasWrapper, holder);
    drawBackground(canvasWrapper, holder);
    drawGrid(canvasWrapper, holder);
  }

  @visibleForTesting
  void drawGrid(CanvasWrapper canvasWrapper, PaintHolder<D> holder) {
    final data = holder.data;
    if (!data.gridData.show) {
      return;
    }
    final viewSize = canvasWrapper.size;
    // Show Vertical Grid
    if (data.gridData.drawVerticalLine) {
      final verticalInterval = Utils().getEfficientInterval(
            viewSize.width,
            data.horizontalDiff,
          );
      final axisValues = AxisChartHelper().iterateThroughAxis(
        min: data.minX,
        minIncluded: false,
        max: data.maxX,
        maxIncluded: false,
        baseLine: data.baselineX,
        interval: verticalInterval,
      );
      for (final axisValue in axisValues) {
        final flLineStyle = data.gridData.getDrawingVerticalLine(axisValue);
        _gridPaint
          ..color = flLineStyle.color
          ..strokeWidth = flLineStyle.strokeWidth
          ..transparentIfWidthIsZero();

        final bothX = getPixelX(axisValue, viewSize, holder);
        final x1 = bothX;
        const y1 = 0.0;
        final x2 = bothX;
        final y2 = viewSize.height;
        canvasWrapper.drawDashedLine(
          Offset(x1, y1),
          Offset(x2, y2),
          _gridPaint,
          flLineStyle.dashArray,
        );
      }
    }

    // Show Horizontal Grid
    if (data.gridData.drawHorizontalLine) {
      final horizontalInterval = data.gridData.horizontalInterval ??
          Utils().getEfficientInterval(viewSize.height, data.verticalDiff);

      final axisValues = AxisChartHelper().iterateThroughAxis(
        min: data.minY,
        minIncluded: false,
        max: data.maxY,
        maxIncluded: false,
        baseLine: data.baselineY,
        interval: horizontalInterval,
      );
      for (final axisValue in axisValues) {
        final flLine = data.gridData.getDrawingHorizontalLine(axisValue);
        _gridPaint
          ..color = flLine.color
          ..strokeWidth = flLine.strokeWidth
          ..transparentIfWidthIsZero();

        final bothY = getPixelY(axisValue, viewSize, holder);
        const x1 = 0.0;
        final y1 = bothY;
        final x2 = viewSize.width;
        final y2 = bothY;
        canvasWrapper.drawDashedLine(
          Offset(x1, y1),
          Offset(x2, y2),
          _gridPaint,
          flLine.dashArray,
        );
      }
    }
  }

  @visibleForTesting
  void drawBackground(CanvasWrapper canvasWrapper, PaintHolder<D> holder) {
    final data = holder.data;
    if (data.backgroundColor.opacity == 0.0) {
      return;
    }

    final viewSize = canvasWrapper.size;
    _backgroundPaint.color = data.backgroundColor;
    canvasWrapper.drawRect(
      Rect.fromLTWH(0, 0, viewSize.width, viewSize.height),
      _backgroundPaint,
    );
  }


  void drawExtraLines(
      BuildContext context,
      CanvasWrapper canvasWrapper,
      PaintHolder<D> holder,
      ) {
    super.paint(context, canvasWrapper, holder);
    final data = holder.data;
    final viewSize = canvasWrapper.size;

    if (data.extraLinesData.horizontalLines.isNotEmpty) {
      drawHorizontalLines(context, canvasWrapper, holder, viewSize);
    }

    if (data.extraLinesData.verticalLines.isNotEmpty) {
      drawVerticalLines(context, canvasWrapper, holder, viewSize);
    }
  }

  void drawHorizontalLines(
      BuildContext context,
      CanvasWrapper canvasWrapper,
      PaintHolder<D> holder,
      Size viewSize,
      ) {
    for (final line in holder.data.extraLinesData.horizontalLines) {
      final from = Offset(0, getPixelY(line.y, viewSize, holder));
      final to = Offset(viewSize.width, getPixelY(line.y, viewSize, holder));

      final isLineOutsideOfChart = from.dy < 0 ||
          to.dy < 0 ||
          from.dy > viewSize.height ||
          to.dy > viewSize.height;

      if (!isLineOutsideOfChart) {
        _extraLinesPaint
          ..color = line.color
          ..strokeWidth = line.strokeWidth
          ..transparentIfWidthIsZero();

        canvasWrapper.drawDashedLine(
          from,
          to,
          _extraLinesPaint,
          line.dashArray,
        );

        if (line.sizedPicture != null) {
          final centerX = line.sizedPicture!.width / 2;
          final centerY = line.sizedPicture!.height / 2;
          final xPosition = centerX;
          final yPosition = to.dy - centerY;

          canvasWrapper
            ..save()
            ..translate(xPosition, yPosition)
            ..drawPicture(line.sizedPicture!.picture)
            ..restore();
        }

        if (line.image != null) {
          final centerX = line.image!.width / 2;
          final centerY = line.image!.height / 2;
          final centeredImageOffset = Offset(centerX, to.dy - centerY);
          canvasWrapper.drawImage(
            line.image!,
            centeredImageOffset,
            _imagePaint,
          );
        }

        if (line.label.show) {
          final label = line.label;
          final style =
          TextStyle(fontSize: 11, color: line.color).merge(label.style);
          final padding = label.padding as EdgeInsets;

          final span = TextSpan(
            text: label.labelResolver(line),
            style: Utils().getThemeAwareTextStyle(context, style),
          );

          final tp = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
          );
          tp.layout();

          canvasWrapper.drawText(
            tp,
            label.alignment.withinRect(
              Rect.fromLTRB(
                from.dx + padding.left,
                from.dy - padding.bottom - tp.height,
                to.dx - padding.right - tp.width,
                to.dy + padding.top,
              ),
            ),
          );
        }
      }
    }
  }

  void drawVerticalLines(
      BuildContext context,
      CanvasWrapper canvasWrapper,
      PaintHolder<D> holder,
      Size viewSize,
      ) {
    for (final line in holder.data.extraLinesData.verticalLines) {
      final from = Offset(getPixelX(line.x, viewSize, holder), 0);
      final to = Offset(getPixelX(line.x, viewSize, holder), viewSize.height);

      final isLineOutsideOfChart = from.dx < 0 ||
          to.dx < 0 ||
          from.dx > viewSize.width ||
          to.dx > viewSize.width;

      if (!isLineOutsideOfChart) {
        _extraLinesPaint
          ..color = line.color
          ..strokeWidth = line.strokeWidth
          ..transparentIfWidthIsZero();

        canvasWrapper.drawDashedLine(
          from,
          to,
          _extraLinesPaint,
          line.dashArray,
        );

        if (line.sizedPicture != null) {
          final centerX = line.sizedPicture!.width / 2;
          final centerY = line.sizedPicture!.height / 2;
          final xPosition = to.dx - centerX;
          final yPosition = viewSize.height - centerY;

          canvasWrapper
            ..save()
            ..translate(xPosition, yPosition)
            ..drawPicture(line.sizedPicture!.picture)
            ..restore();
        }

        if (line.image != null) {
          final centerX = line.image!.width / 2;
          final centerY = line.image!.height + 2;
          final centeredImageOffset =
          Offset(to.dx - centerX, viewSize.height - centerY);
          canvasWrapper.drawImage(
            line.image!,
            centeredImageOffset,
            _imagePaint,
          );
        }

        if (line.label.show) {
          final label = line.label;
          final style =
          TextStyle(fontSize: 11, color: line.color).merge(label.style);
          final padding = label.padding as EdgeInsets;

          final span = TextSpan(
            text: label.labelResolver(line),
            style: Utils().getThemeAwareTextStyle(context, style),
          );

          final tp = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
          );
          tp.layout();

          canvasWrapper.drawText(
            tp,
            label.alignment.withinRect(
              Rect.fromLTRB(
                to.dx - padding.right - tp.width,
                from.dy + padding.top,
                from.dx + padding.left,
                to.dy - padding.bottom,
              ),
            ),
          );
        }
      }
    }
  }

  double getPixelX(double spotX, Size viewSize, PaintHolder<D> holder) {
    final data = holder.data;
    final deltaX = data.maxX - data.minX;
    if (deltaX == 0.0) {
      return 0;
    }
    return ((spotX - data.minX) / deltaX) * viewSize.width;
  }


  double getPixelY(double spotY, Size viewSize, PaintHolder<D> holder) {
    final data = holder.data;
    final deltaY = data.maxY - data.minY;
    if (deltaY == 0.0) {
      return viewSize.height;
    }
    return viewSize.height - (((spotY - data.minY) / deltaY) * viewSize.height);
  }

  double getTooltipLeft(
      double dx,
      double tooltipWidth,
      VTSHorizontalAlignment tooltipHorizontalAlignment,
      ) {
    switch (tooltipHorizontalAlignment) {
      case VTSHorizontalAlignment.center:
        return dx - (tooltipWidth / 2) ;
      case VTSHorizontalAlignment.right:
        return dx ;
      case VTSHorizontalAlignment.left:
        return dx - tooltipWidth ;
    }
  }
}




