# WakeWay

WakeWay is a Flutter UI prototype for a commute alarm app. Its tagline is “Sleep through the ride. Wake at the right time.” The screens use Material 3, a light neutral canvas, navy branding, blue actions, green GPS status, and red alarm states.

## Screens and flows

- Animated splash and home dashboard with a one-tap start for a saved commute
- Map planning with a tappable alarm marker, route preview, and zoom controls
- Destination selection and alarm setup, including trigger mode, radius, warning distance, sound, vibration, repeat, and snooze controls
- Active trip monitoring and a high-contrast alarm screen with stop and snooze actions
- Offline map management, saved destinations, trip history, settings, and GPS permission status
- Bottom navigation for Home, Map, Trips, and More

The shared app mark is in `assets/wakeway_icon.png` and is also used for the Android launcher icon.

## Design system

| Token | Color | Use |
| --- | --- | --- |
| Navy | `#102A43` | Brand and trip summary panels |
| Blue | `#246FCB` | Main actions and map navigation |
| Green | `#1F795C` | GPS and arrival status |
| Red | `#C8434E` | Alarm and warning actions |
| Canvas | `#F4F7FA` | Light screen background |
| Muted | `#5E6F81` | Supporting text |

Typography follows the Material system font with a 30 px main headline, 24 px screen headings, and 11–15 px supporting labels and body text. Rounded white cards, 14–25 px corner radii, and repeated 4–20 px spacing keep the screens legible and touch friendly.

## Prototype scope

The screens demonstrate the intended product flow with local sample data. The map is a custom illustration so it renders without map tiles; GPS updates, background tracking, alarm audio, real permission checks, and map downloads are not connected to device services yet.

## Run

```sh
flutter pub get
flutter run
```
