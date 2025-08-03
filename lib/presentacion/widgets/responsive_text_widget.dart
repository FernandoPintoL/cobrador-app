import 'package:flutter/material.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const ResponsiveText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style?.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ) ??
          TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }
}

class ResponsiveCardText extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isCompact;

  const ResponsiveCardText({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: isCompact ? 16 : 20,
              ),
              SizedBox(width: isCompact ? 8 : 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    text: title,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    maxLines: 1,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: isCompact ? 2 : 4),
                    ResponsiveText(
                      text: subtitle!,
                      fontSize: isCompact ? 11 : 12,
                      color: Colors.grey[600],
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: isCompact ? 12 : 14,
            ),
          ],
        ),
      ),
    );
  }
} 