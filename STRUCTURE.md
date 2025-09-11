# Color Flood - Project Structure

This document outlines the standardized Flutter project structure for the Color Flood game.

## 📁 Directory Structure

```
lib/
├── assets/                    # Static assets and styles
│   └── styles/
│       └── app_theme.dart    # Application theme configuration
├── components/               # Reusable UI components
│   ├── color_button.dart     # Color selection button
│   ├── color_palette.dart    # Color palette container
│   ├── game_board.dart       # Game grid display
│   ├── glass_button.dart     # Glass morphism button
│   ├── hud_card.dart         # HUD information card
│   └── components.dart       # Barrel file for components
├── constants/                # Application constants
│   ├── app_constants.dart    # App-wide constants
│   ├── game_constants.dart   # Game-specific constants
│   └── constants.dart        # Barrel file for constants
├── pages/                    # Application screens/pages
│   ├── game_page.dart        # Main game screen
│   ├── home_page.dart        # Home/welcome screen
│   └── pages.dart            # Barrel file for pages
├── services/                 # Business logic services
│   └── game_service.dart     # Game logic and algorithms
├── types/                    # Type definitions
│   └── game_types.dart       # Game-related data models
└── main.dart                 # Application entry point
```

## 🎯 Key Features

### Home Page

- **No more popup**: The game now starts with a proper home page
- **Animated title**: Beautiful letter-by-letter animation
- **Clear instructions**: Goal and description displayed prominently
- **Start button**: Clean call-to-action to begin the game

### Standardized Structure

- **Separation of concerns**: Logic, UI, and data are properly separated
- **Reusable components**: All UI elements are modular and reusable
- **Constants management**: All magic numbers and strings are centralized
- **Type safety**: Strong typing with custom data models
- **Service layer**: Game logic is encapsulated in dedicated services

### Code Quality

- **Clean architecture**: Following Flutter best practices
- **Consistent naming**: PascalCase for classes, camelCase for variables
- **Documentation**: Comprehensive comments and documentation
- **Error handling**: Proper error handling throughout
- **Performance**: Optimized animations and state management

## 🚀 Getting Started

1. **Run the app**: `flutter run`
2. **Home page**: You'll see the animated home page instead of a popup
3. **Start playing**: Tap "Start Playing 🚀" to begin the game
4. **Navigation**: Clean navigation between home and game screens

## 📱 Components

### Reusable Components

- `ColorButton`: Animated color selection buttons
- `ColorPalette`: Container for color selection
- `GameBoard`: Displays the game grid
- `GlassButton`: Glass morphism styled buttons
- `HudCard`: Information display cards

### Services

- `GameService`: Handles all game logic including:
  - Grid generation
  - Flood fill algorithm
  - Move validation
  - Win condition checking
  - Optimal solution calculation

## 🎨 Theming

The app supports both light and dark themes with:

- Consistent color scheme
- Material 3 design system
- Responsive design
- Smooth animations

## 🔧 Constants

All configuration is centralized in:

- `GameConstants`: Game-specific values (colors, durations, sizes)
- `AppConstants`: Application-wide constants (text, routes, labels)

This structure ensures maintainability, scalability, and follows Flutter development best practices.
