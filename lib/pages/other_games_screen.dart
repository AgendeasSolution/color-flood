import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Screen displaying other mobile games from FGTP Labs.
class OtherGamesScreen extends StatelessWidget {
  const OtherGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.otherGamesTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videogame_asset_rounded,
                size: 72,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.otherGamesDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Stay tuned! We\'re curating our favorite mobile titles for you.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

