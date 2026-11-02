import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reserves the space and look of a standard mobile banner ad on the
/// Documents home screen. DocTrack is fully offline and ad-supported rather
/// than paid — this is the slot a real ad SDK (e.g. Google Mobile Ads)
/// would render into; wire `google_mobile_ads`'s `BannerAd` widget in here
/// when a publisher account/ad unit id is available.
class AdBannerPlaceholder extends StatelessWidget {
  // Deliberately not a const constructor: build() reads the live theme via
  // AppColors, and a `const AdBannerPlaceholder()` instance would let
  // Flutter's identical-widget fast path skip rebuilding it entirely when
  // the user switches Light/Dark in Settings.
  // ignore: prefer_const_constructors_in_immutables
  AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.borderDashed),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 16, color: AppColors.textDisabled),
          const SizedBox(width: 8),
          Text(
            'Ad space',
            style: AppText.mono(size: 10.5, weight: FontWeight.w600, color: AppColors.textDisabled, letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}
