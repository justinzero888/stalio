import 'package:flutter/material.dart';

enum CardLayout { heroImage, centered, leftAligned, twoColumn }

extension CardLayoutExtension on CardLayout {
  String get value {
    switch (this) {
      case CardLayout.heroImage:
        return 'hero_image';
      case CardLayout.centered:
        return 'centered';
      case CardLayout.leftAligned:
        return 'left_aligned';
      case CardLayout.twoColumn:
        return 'two_column';
    }
  }

  static CardLayout fromString(String s) {
    switch (s) {
      case 'centered':
        return CardLayout.centered;
      case 'left_aligned':
        return CardLayout.leftAligned;
      case 'two_column':
        return CardLayout.twoColumn;
      default:
        return CardLayout.heroImage;
    }
  }
}

enum CardCornerStyle { rounded, sharp, pill }

extension CardCornerStyleExtension on CardCornerStyle {
  String get value => name;

  static CardCornerStyle fromString(String s) {
    switch (s) {
      case 'sharp':
        return CardCornerStyle.sharp;
      case 'pill':
        return CardCornerStyle.pill;
      default:
        return CardCornerStyle.rounded;
    }
  }
}

enum TextAlignMode { left, center, right, justify }

extension TextAlignModeExtension on TextAlignMode {
  String get value => name;

  static TextAlignMode fromString(String s) {
    switch (s) {
      case 'left':
        return TextAlignMode.left;
      case 'center':
        return TextAlignMode.center;
      case 'right':
        return TextAlignMode.right;
      case 'justify':
        return TextAlignMode.justify;
      default:
        return TextAlignMode.center;
    }
  }

  TextAlign toFlutter() {
    switch (this) {
      case TextAlignMode.left:
        return TextAlign.left;
      case TextAlignMode.center:
        return TextAlign.center;
      case TextAlignMode.right:
        return TextAlign.right;
      case TextAlignMode.justify:
        return TextAlign.justify;
    }
  }
}
