Comprehensive multi-platform Flutter app for zero-touch automotive diagnostics using OBD-II, phone sensors, GPS tracking, and AI-powered analysis via Google Gemini 2.5 Pro.

Features
Core Features
Multi-transport OBD-II Connection: Bluetooth Classic, USB Serial, and Simulation mode
Comprehensive PID Support: All generic OBD-II Mode 01 PIDs (50+ sensors)
Real-time Dashboard: Live monitoring of RPM, speed, coolant, throttle, fuel level, and more
AI-Powered Diagnostics: Google Gemini 2.5 Pro integration for automated vehicle diagnosis
GPS Tracking: Real-time map display with route tracking
Trip Logging: Automatic recording of trips with sensor fusion data
Route Analysis: AI-based route recommendations based on vehicle wear and damage scores
Phone Sensors: Accelerometer and gyroscope integration for harsh driving detection
Persistent Storage: Trip history saved to device with JSON format
Advanced Features
Keep-Alive Connection: Bluetooth timeout prevention with automatic heartbeat
Damage Scoring: Calculate vehicle wear based on driving patterns, OBD data, and phone sensors
Route Comparison: Analyze historical trips to recommend best routes
Configurable Settings: In-app Gemini API key management with free tier support
Prerequisites
Flutter SDK (3.10.4+)
Android device with:
Bluetooth Classic or USB-OTG support
GPS/Location services
Accelerometer and gyroscope
Google Gemini API key (free tier available at Google AI Studio)
Google Maps API key (for map display)
Setup
1. Install Dependencies
flutter clean
flutter pub get
2. Configure API Keys
+#### Gemini API Key (Required for AI Diagnostics) +1. Visit Google AI Studio +2. Sign in with your Google account +3. Create a new API key +4. Open the app → Settings → Enter your API key +5. Select model: Gemini 2.5 Pro (Free Tier, Recommended)

+Free Tier Limits: +- 1,500 requests per day +- Gemini 2.5 Pro free tier recommended

Google Maps API Key (Required for Map Display)
Visit Google Cloud Console
Enable Maps SDK for Android
Create an API key
Add key to android/app/src/main/AndroidManifest.xml:
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
3. Run the App
# Development mode (simulation)
flutter run

# With Gemini API key via command line (optional)
flutter run \
  --dart-define=GEMINI_API_KEY=YOUR_API_KEY \
  --dart-define=GEMINI_MODEL=gemini-2.5-pro
4. Connect to Vehicle
Pair your ELM327 adapter via Bluetooth settings (or connect USB)
Open the app
Select transport: Bluetooth, USB, or Simulation
Tap "Connect"
Start trip recording for route analysis
Tap "Diagnose" for AI-powered diagnostics
Architecture
OBD-II Layer
ObdConnection (abstract): Transport interface
BluetoothObdConnection: Bluetooth Classic RFCOMM
UsbObdConnection: USB Serial communication
SimulationObdConnection: Mock data for development
Elm327Protocol: ELM327 initialization and PID queries
ObdPidRegistry: All 50+ generic OBD-II PIDs with parsers
Services
DiagnosticsService: High-level OBD sampling
GeminiClient: AI diagnostics via Google Gemini
TripLoggingService: Trip recording with sensor fusion
RouteAnalyzerService: Historical route analysis and recommendations
SettingsService: Persistent configuration storage
Sensors
GPS: Real-time location tracking via geolocator
Accelerometer: Harsh braking/acceleration detection
Gyroscope: Sharp turn detection
OBD-II: Engine parameters (RPM, load, temperature, etc.)
Supported OBD-II PIDs
The app supports all generic Mode 01 PIDs including:

Engine: RPM, load, timing advance, oil temperature
Fuel: Pressure, trim (bank 1/2), level, consumption rate
Temperature: Coolant, intake air, ambient
Airflow: MAF, intake manifold pressure
Throttle: Position, commanded actuator
System: OBD standards, fuel type, distance traveled
Diagnostics: Monitor status, freeze frame, DTCs
See lib/services/obd_pid_registry.dart for complete list.

Trip Logging & Route Analysis
Damage Scoring Algorithm
The app calculates a real-time damage score based on:

Accelerometer: Harsh acceleration/braking (>15 m/s²)
Gyroscope: Sharp turns and sudden maneuvers
OBD Data:
High RPM (>4000 rpm)
Engine load (>80%)
Overheating (>100°C coolant)
Route Recommendations
Based on historical trip data:

Groups trips by similar start/end points
Calculates average damage score per route
Factors in time and distance
Recommends best route with lowest wear
Notes on Accuracy
AI diagnostics accuracy depends on:

Completeness of OBD data available from vehicle
Quality of sensor readings
Gemini model's training data
Prompt engineering and structured output format
The app uses strict JSON schema responses from Gemini to ensure consistent, parseable diagnostics