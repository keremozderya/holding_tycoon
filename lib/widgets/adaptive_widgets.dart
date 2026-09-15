// lib/widgets/adaptive_widgets.dart
//
// Compatibility widgets used by the existing UI while the project migrates to
// fully keyed localization. They keep current screen code compact, translate
// legacy text through JSON, preserve black text on bright surfaces in dark mode,
// and force UI icons to white while dark mode is active.

import 'package:flutter/material.dart' as material;

import '../services/translation_service.dart';
import '../theme/app_theme.dart';

bool _sameColor(material.Color? a, material.Color b) =>
    a != null && a.value == b.value;

bool _isBlackFamily(material.Color? color) {
  if (color == null) return false;
  return (color.value & 0x00FFFFFF) == 0x000000;
}

class _SurfaceTone extends material.InheritedWidget {
  const _SurfaceTone({required this.isDarkSurface, required super.child});

  final bool isDarkSurface;

  static bool of(material.BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_SurfaceTone>();
    if (inherited != null) return inherited.isDarkSurface;
    return material.Theme.of(context).brightness == material.Brightness.dark;
  }

  @override
  bool updateShouldNotify(_SurfaceTone oldWidget) =>
      oldWidget.isDarkSurface != isDarkSurface;
}

material.Color? _darkNeutralFor(material.Color? color) {
  if (color == null) return null;

  if (_sameColor(color, material.Colors.white) ||
      _sameColor(color, AppColors.surface)) {
    return AppColors.darkSurface;
  }
  if (_sameColor(color, AppColors.surfaceElevated) ||
      _sameColor(color, const material.Color(0xFFF8FAFC))) {
    return AppColors.darkSurfaceElevated;
  }
  if (_sameColor(color, AppColors.surfaceSoft) ||
      _sameColor(color, const material.Color(0xFFF1F5F9))) {
    return AppColors.darkSurfaceSoft;
  }
  if (_sameColor(color, AppColors.surfaceMuted) ||
      _sameColor(color, const material.Color(0xFFE2E8F0))) {
    return AppColors.darkSurfaceMuted;
  }
  return null;
}

material.Decoration? _adaptDecoration(
  material.BuildContext context,
  material.Decoration? decoration,
) {
  if (material.Theme.of(context).brightness != material.Brightness.dark) {
    return decoration;
  }
  if (decoration is! material.BoxDecoration) return decoration;

  final replacement = _darkNeutralFor(decoration.color);
  if (replacement == null) return decoration;
  return decoration.copyWith(color: replacement);
}

bool? _toneForColor(material.Color? color) {
  if (color == null || color.alpha < 24) return null;
  return color.computeLuminance() < 0.34;
}

material.Color? _resolvedSurfaceColor(
  material.Color? color,
  material.Decoration? decoration,
) {
  if (decoration is material.BoxDecoration && decoration.color != null) {
    return decoration.color;
  }
  return color;
}

material.Color? _adaptTextColor(
  material.BuildContext context,
  material.Color? color,
) {
  final dark =
      material.Theme.of(context).brightness == material.Brightness.dark;
  if (!dark || color == null) return color;

  // In dark mode, only text that actually sits on a dark surface is recolored.
  // Black copy on gold/white/green/light surfaces therefore stays black.
  if (!_SurfaceTone.of(context)) return color;

  if (_isBlackFamily(color) || _sameColor(color, AppColors.textPrimary)) {
    return material.Colors.white.withAlpha(color.alpha);
  }
  if (_sameColor(color, AppColors.textSecondary)) {
    return AppColors.darkTextSecondary.withAlpha(color.alpha);
  }
  if (_sameColor(color, AppColors.textMuted)) {
    return AppColors.darkTextMuted.withAlpha(color.alpha);
  }
  return color;
}

material.TextStyle? _adaptTextStyle(
  material.BuildContext context,
  material.TextStyle? style,
) {
  final dark =
      material.Theme.of(context).brightness == material.Brightness.dark;
  if (style == null) {
    // Theme text is white in dark mode. On an explicitly bright surface the
    // default must become black instead.
    if (dark && !_SurfaceTone.of(context)) {
      return const material.TextStyle(color: material.Colors.black);
    }
    return null;
  }
  final color = _adaptTextColor(context, style.color);
  return color == style.color ? style : style.copyWith(color: color);
}

/// Resolves icon colors using the surface under the icon, not only the global
/// theme. This keeps icons white on dark cartoon-blue surfaces while preserving
/// the original/component foreground color on white, gold and other bright
/// controls. For example, a white FloatingActionButton with a black
/// foreground stays black even when the app itself is in dark mode.
material.Color? adaptiveIconColor(
  material.BuildContext context,
  material.Color? original,
) {
  final theme = material.Theme.of(context);
  if (theme.brightness != material.Brightness.dark) return original;

  final inheritedIconColor = material.IconTheme.of(context).color;
  final defaultIconColor = theme.iconTheme.color;

  // Containers/animated containers in this compatibility layer publish their
  // actual surface tone to descendants. Bright surfaces must never be forced
  // to white.
  if (!_SurfaceTone.of(context)) {
    return original ?? inheritedIconColor;
  }

  // Material controls such as FloatingActionButton establish a local IconTheme
  // from foregroundColor. They do not pass through our Container wrapper, so a
  // local foreground override is the reliable signal that the control itself
  // has chosen the correct contrast color for its background.
  final hasLocalIconThemeOverride = inheritedIconColor != null &&
      (defaultIconColor == null ||
          inheritedIconColor.value != defaultIconColor.value);
  final localForegroundIsDark = inheritedIconColor != null &&
      inheritedIconColor.computeLuminance() < 0.25;
  if (hasLocalIconThemeOverride && localForegroundIsDark) {
    return original ?? inheritedIconColor;
  }

  // No bright surface or component override exists: the icon is on a dark
  // surface, therefore it must be white for contrast.
  return material.Colors.white;
}

material.InlineSpan _translateInlineSpan(
  material.BuildContext context,
  material.InlineSpan span,
) {
  if (span is material.TextSpan) {
    return material.TextSpan(
      text: span.text == null
          ? null
          : TranslationService.instance.translateLiteral(span.text!),
      children: span.children
          ?.map<material.InlineSpan>(
            (child) => _translateInlineSpan(context, child),
          )
          .toList(growable: false),
      style: _adaptTextStyle(context, span.style),
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
  return span;
}

/// API-compatible project wrapper for Material Text.
class Text extends material.StatelessWidget {
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    material.InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final material.InlineSpan? textSpan;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final material.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;

  @override
  material.Widget build(material.BuildContext context) {
    return material.AnimatedBuilder(
      animation: TranslationService.instance,
      builder: (context, _) {
        final resolvedStyle = _adaptTextStyle(context, style);

        if (textSpan != null) {
          return material.Text.rich(
            _translateInlineSpan(context, textSpan!),
            style: resolvedStyle,
            strutStyle: strutStyle,
            textAlign: textAlign,
            textDirection: textDirection,
            locale: locale,
            softWrap: softWrap,
            overflow: overflow,
            textScaler: textScaler,
            maxLines: maxLines,
            semanticsLabel: semanticsLabel,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
            selectionColor: selectionColor,
          );
        }

        return material.Text(
          TranslationService.instance.translateLiteral(data ?? ''),
          style: resolvedStyle,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor,
        );
      },
    );
  }
}

/// Material Icon wrapper. Explicit icon colors are preserved in light mode and
/// overridden to white in dark mode.
class Icon extends material.StatelessWidget {
  const Icon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
    this.shadows,
  });

  final material.IconData? icon;
  final double? size;
  final material.Color? color;
  final String? semanticLabel;
  final material.TextDirection? textDirection;
  final List<material.Shadow>? shadows;

  @override
  material.Widget build(material.BuildContext context) {
    return material.Icon(
      icon,
      size: size,
      color: adaptiveIconColor(context, color),
      semanticLabel: semanticLabel,
      textDirection: textDirection,
      shadows: shadows,
    );
  }
}

material.Widget _wrapSurfaceTone({
  required material.BuildContext context,
  required material.Widget child,
  required material.Color? surfaceColor,
}) {
  final dark =
      material.Theme.of(context).brightness == material.Brightness.dark;
  if (!dark) return child;

  final inheritedTone = _SurfaceTone.of(context);
  final explicitTone = _toneForColor(surfaceColor);
  return _SurfaceTone(
    isDarkSurface: explicitTone ?? inheritedTone,
    child: child,
  );
}

/// Neutral light surfaces are automatically mapped to the dark cartoon-blue
/// palette. Bright/accent surfaces keep their color and tell descendant text to
/// retain its original dark text color.
class Container extends material.StatelessWidget {
  const Container({
    super.key,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.child,
    this.clipBehavior = material.Clip.none,
  });

  final material.AlignmentGeometry? alignment;
  final material.EdgeInsetsGeometry? padding;
  final material.Color? color;
  final material.Decoration? decoration;
  final material.Decoration? foregroundDecoration;
  final double? width;
  final double? height;
  final material.BoxConstraints? constraints;
  final material.EdgeInsetsGeometry? margin;
  final material.Matrix4? transform;
  final material.AlignmentGeometry? transformAlignment;
  final material.Widget? child;
  final material.Clip clipBehavior;

  @override
  material.Widget build(material.BuildContext context) {
    final dark =
        material.Theme.of(context).brightness == material.Brightness.dark;

    final resolvedDecoration = _adaptDecoration(context, decoration);
    final resolvedColor = dark && resolvedDecoration == null
        ? (_darkNeutralFor(color) ?? color)
        : color;
    final resolvedSurfaceColor =
        _resolvedSurfaceColor(resolvedColor, resolvedDecoration);

    final wrappedChild = child == null
        ? null
        : _wrapSurfaceTone(
            context: context,
            child: child!,
            surfaceColor: resolvedSurfaceColor,
          );

    return material.Container(
      alignment: alignment,
      padding: padding,
      color: resolvedDecoration == null ? resolvedColor : null,
      decoration: resolvedDecoration,
      foregroundDecoration: foregroundDecoration,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      child: wrappedChild,
    );
  }
}

/// AnimatedContainer counterpart with the same surface-tone behavior as the
/// project Container wrapper.
class AnimatedContainer extends material.StatelessWidget {
  const AnimatedContainer({
    super.key,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.child,
    this.clipBehavior = material.Clip.none,
    this.curve = material.Curves.linear,
    required this.duration,
    this.onEnd,
  });

  final material.AlignmentGeometry? alignment;
  final material.EdgeInsetsGeometry? padding;
  final material.Color? color;
  final material.Decoration? decoration;
  final material.Decoration? foregroundDecoration;
  final double? width;
  final double? height;
  final material.BoxConstraints? constraints;
  final material.EdgeInsetsGeometry? margin;
  final material.Matrix4? transform;
  final material.AlignmentGeometry? transformAlignment;
  final material.Widget? child;
  final material.Clip clipBehavior;
  final material.Curve curve;
  final Duration duration;
  final material.VoidCallback? onEnd;

  @override
  material.Widget build(material.BuildContext context) {
    final dark =
        material.Theme.of(context).brightness == material.Brightness.dark;
    final resolvedDecoration = _adaptDecoration(context, decoration);
    final resolvedColor = dark && resolvedDecoration == null
        ? (_darkNeutralFor(color) ?? color)
        : color;
    final resolvedSurfaceColor =
        _resolvedSurfaceColor(resolvedColor, resolvedDecoration);

    final wrappedChild = child == null
        ? null
        : _wrapSurfaceTone(
            context: context,
            child: child!,
            surfaceColor: resolvedSurfaceColor,
          );

    return material.AnimatedContainer(
      alignment: alignment,
      padding: padding,
      color: resolvedDecoration == null ? resolvedColor : null,
      decoration: resolvedDecoration,
      foregroundDecoration: foregroundDecoration,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      curve: curve,
      duration: duration,
      onEnd: onEnd,
      child: wrappedChild,
    );
  }
}
