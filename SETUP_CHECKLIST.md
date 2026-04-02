# FuelProof Flutter Setup Checklist

## ✅ Completed

### Project Structure
- [x] Created core constants system (colors, text styles, spacing)
- [x] Created app theme with FuelProof design system
- [x] Created asset directories (`assets/images/`)
- [x] Created feature folders (splash, home)
- [x] Created shared widgets (dashboard_widgets)
- [x] Updated pubspec.yaml with asset and font configuration
- [x] Updated main.dart with theme and routing

### Design System
- [x] AppColors - All colors per system.md spec
- [x] AppTextStyles - All typography styles
- [x] AppSpacing - 4px base unit spacing system
- [x] AppBorderRadius, AppDimensions, AppDurations
- [x] AppTheme - Complete Material 3 theme

### Screens Implemented
- [x] **Splash Screen** - Logo centered, white bg, fade-in, 1.8s duration
- [x] **Home Screen (Dashboard)** - Complete with all elements:
  - Top bar with "FuelProof" and notification bell
  - Greeting section
  - Quick action "Scan to Start" card (teal gradient)
  - Recent Transactions list
  - Nearby Stations horizontal scroll
  - Bottom navigation (Home, Scan, History, Profile)

### Reusable Widgets
- [x] ScanToStartCard - Gradient teal CTA card
- [x] TransactionCard - Transaction list item
- [x] NearbyStationCard - Station card with distance badge
- [x] EmptyState - Consistent empty state component

---

## 📋 TODO - Before Running the App

### 1. **Move Logo File**
```bash
# Move logo.webp to assets folder
mv logo.webp assets/images/logo.webp
```

### 2. **Install Inter Font**
You need to download and add Inter font files. Create:
```
assets/fonts/
├── Inter-Regular.ttf    (weight: 400)
├── Inter-Medium.ttf     (weight: 500)
├── Inter-SemiBold.ttf   (weight: 600)
└── Inter-Bold.ttf       (weight: 700)
```

Download from: [Google Fonts - Inter](https://fonts.google.com/specimen/Inter)

### 3. **Install Dependencies** (if using state management)
Current implementation is minimal. To add the planned tech stack:
```yaml
dependencies:
  riverpod: ^2.4.0
  riverpod_annotation: ^2.1.0
  go_router: ^11.0.0
  dio: ^5.3.0  
  mobile_scanner: ^3.5.0
  flutter_secure_storage: ^9.0.0
  socket_io_client: ^2.0.0
  firebase_core: ^24.0.0
  firebase_auth: ^4.10.0
  cloud_firestore: ^4.13.0

dev_dependencies:
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.6
```

### 4. **Run Flutter Pub Get**
```bash
flutter pub get
```

### 5. **Test the App**
```bash
flutter run
```

---

## 🎨 Design System Reference

**Colors:**
- Primary Background: #F4F6FA
- White: #FFFFFF
- Brand Navy: #1A2744
- Accent Teal: #00B4A6
- Success: #1e7e34
- Alert: #C0392B

**Spacing (4px base):**
- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px

**Typography:**
- Display Hero: 32px, Weight 700
- Section Heading: 20px, Weight 600
- Card Title: 16px, Weight 600
- Body: 14px, Weight 400

---

## 📁 Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── text_styles.dart
│   │   ├── spacing.dart
│   │   └── app_constants.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── splash/
│   │   └── splash_screen.dart
│   └── home/
│       └── home_screen.dart
├── shared/
│   └── widgets/
│       └── dashboard_widgets.dart
└── main.dart

assets/
├── images/
│   └── logo.webp
└── fonts/
    ├── Inter-Regular.ttf
    ├── Inter-Medium.ttf
    ├── Inter-SemiBold.ttf
    └── Inter-Bold.ttf
```

---

## 🚀 Next Steps

1. Move logo.webp and add fonts
2. Run `flutter pub get`
3. Run the app with `flutter run`
4. Test splash screen → home screen transition
5. Implement routing for Scan, History, Profile screens
6. Add state management (Riverpod)
7. Connect to backend services (Firebase, Socket.io)

---

## 📝 Notes

- All components follow system.md design guidelines strictly
- Using Material 3 + custom theming
- No hardcoded strings (ready for localization)
- Responsive design with proper touch targets (48x48px minimum)
- Empty states defined for all list screens
- Ready for integration with state management and APIs
