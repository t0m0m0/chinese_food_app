import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum ApiAttributionType {
  hotpepper,
  googleMaps,
  openStreetMap;

  String get displayText {
    switch (this) {
      case ApiAttributionType.hotpepper:
        return 'Powered by HotPepper グルメサーチAPI';
      case ApiAttributionType.googleMaps:
        return 'Map data ©2024 Google';
      case ApiAttributionType.openStreetMap:
        return '© OpenStreetMap contributors';
    }
  }

  String get url {
    switch (this) {
      case ApiAttributionType.hotpepper:
        return 'https://webservice.recruit.co.jp/hotpepper/';
      case ApiAttributionType.googleMaps:
        return 'https://developers.google.com/maps';
      case ApiAttributionType.openStreetMap:
        return 'https://www.openstreetmap.org/';
    }
  }
}

class ApiAttributionWidget extends StatelessWidget {
  final ApiAttributionType apiType;
  final VoidCallback? onLinkTap;
  final Color? textColor;
  final double? fontSize;

  const ApiAttributionWidget({
    super.key,
    required this.apiType,
    this.onLinkTap,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: TextButton(
        onPressed: onLinkTap ?? () => _launchUrl(apiType.url),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontSize: fontSize ?? 11,
            color: textColor ?? Colors.grey.shade600,
          ),
        ),
        child: Text(
          apiType.displayText,
          style: TextStyle(
            fontSize: fontSize ?? 11,
            color: textColor ?? Colors.grey.shade600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}