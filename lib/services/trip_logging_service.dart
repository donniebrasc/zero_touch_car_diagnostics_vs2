import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

class TripLogEntry {
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? altitude;
  final Map<String, String> obdData;
  final AccelerometerData? accelerometer;
  final GyroscopeData? gyroscope;
  final double damageScore;

  TripLogEntry({
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.speed,
    this.altitude,
    required this.obdData,
    this.accelerometer,
    this.gyroscope,
    required this.damageScore,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'altitude': altitude,
        'obdData': obdData,
        'accelerometer': accelerometer?.toJson(),
        'gyroscope': gyroscope?.toJson(),
        'damageScore': damageScore,
      };

  factory TripLogEntry.fromJson(Map<String, dynamic> json) => TripLogEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        latitude: json['latitude'] as double?,
        longitude: json['longitude'] as double?,
        speed: json['speed'] as double?,
        altitude: json['altitude'] as double?,
        obdData: Map<String, String>.from(json['obdData'] as Map),
        accelerometer: json['accelerometer'] != null ? AccelerometerData.fromJson(json['accelerometer'] as Map<String, dynamic>) : null,
        gyroscope: json['gyroscope'] != null ? GyroscopeData.fromJson(json['gyroscope'] as Map<String, dynamic>) : null,
        damageScore: (json['damageScore'] as num).toDouble(),
      );
}

class AccelerometerData {
  final double x;
  final double y;
  final double z;
  final double magnitude;

  AccelerometerData(this.x, this.y, this.z) : magnitude = _calculateMagnitude(x, y, z);

  static double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z, 'magnitude': magnitude};

  factory AccelerometerData.fromJson(Map<String, dynamic> json) =>
      AccelerometerData(json['x'] as double, json['y'] as double, json['z'] as double);
}

class GyroscopeData {
  final double x;
  final double y;
  final double z;

  GyroscopeData(this.x, this.y, this.z);

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};

  factory GyroscopeData.fromJson(Map<String, dynamic> json) =>
      GyroscopeData(json['x'] as double, json['y'] as double, json['z'] as double);
}

class TripLog {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<TripLogEntry> entries;
  double totalDistance;
  double totalDamage;

  TripLog({
    required this.id,
    required this.startTime,
    this.endTime,
    List<TripLogEntry>? entries,
    this.totalDistance = 0,
    this.totalDamage = 0,
  }) : entries = entries ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'totalDistance': totalDistance,
        'totalDamage': totalDamage,
      };

  factory TripLog.fromJson(Map<String, dynamic> json) => TripLog(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
        entries: (json['entries'] as List).map((e) => TripLogEntry.fromJson(e as Map<String, dynamic>)).toList(),
        totalDistance: (json['totalDistance'] as num).toDouble(),
        totalDamage: (json['totalDamage'] as num).toDouble(),
      );
}

class TripLoggingService {
  TripLog? _currentTrip;
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<Position>? _positionSubscription;

  AccelerometerData? _lastAccel;
  GyroscopeData? _lastGyro;
  Position? _lastPosition;
  Position? _previousPosition;

  bool get isRecording => _currentTrip != null && _currentTrip!.endTime == null;

  TripLog? get currentTrip => _currentTrip;

  Future<void> startTrip() async {
    if (isRecording) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _currentTrip = TripLog(id: id, startTime: DateTime.now());

    // Start sensor monitoring
    _accelSubscription = userAccelerometerEventStream().listen((event) {
      _lastAccel = AccelerometerData(event.x, event.y, event.z);
    });

    _gyroSubscription = gyroscopeEventStream().listen((event) {
      _lastGyro = GyroscopeData(event.x, event.y, event.z);
    });

    // Start GPS tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((position) {
      _previousPosition = _lastPosition;
      _lastPosition = position;
    });
  }

  Future<void> logEntry(Map<String, String> obdData) async {
    if (!isRecording || _currentTrip == null) return;

    final damageScore = _calculateDamageScore(_lastAccel, _lastGyro, obdData);

    final entry = TripLogEntry(
      timestamp: DateTime.now(),
      latitude: _lastPosition?.latitude,
      longitude: _lastPosition?.longitude,
      speed: _lastPosition?.speed,
      altitude: _lastPosition?.altitude,
      obdData: obdData,
      accelerometer: _lastAccel,
      gyroscope: _lastGyro,
      damageScore: damageScore,
    );

    _currentTrip!.entries.add(entry);
    _currentTrip!.totalDamage += damageScore;

    // Calculate distance if we have two positions
    if (_previousPosition != null && _lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        _lastPosition!.latitude,
        _lastPosition!.longitude,
      );
      _currentTrip!.totalDistance += distance;
    }
  }

  double _calculateDamageScore(AccelerometerData? accel, GyroscopeData? gyro, Map<String, String> obdData) {
    double score = 0.0;

    // Accelerometer-based damage (harsh acceleration/braking/cornering)
    if (accel != null) {
      final accelMagnitude = accel.magnitude;
      // Normal driving: ~9.8 m/s² (gravity)
      // Harsh events: >15 m/s²
      if (accelMagnitude > 15) {
        score += (accelMagnitude - 15) * 2;
      }
    }

    // Gyroscope-based damage (sharp turns)
    if (gyro != null) {
      final gyroMagnitude = (gyro.x.abs() + gyro.y.abs() + gyro.z.abs());
      if (gyroMagnitude > 2.0) {
        score += (gyroMagnitude - 2.0) * 3;
      }
    }

    // OBD-based damage factors
    try {
      // High RPM
      if (obdData.containsKey('0C')) {
        final rpm = int.tryParse(obdData['0C'] ?? '0') ?? 0;
        if (rpm > 4000) {
          score += (rpm - 4000) / 500;
        }
      }

      // Engine load
      if (obdData.containsKey('04')) {
        final load = double.tryParse(obdData['04'] ?? '0') ?? 0;
        if (load > 80) {
          score += (load - 80) / 10;
        }
      }

      // High coolant temperature
      if (obdData.containsKey('05')) {
        final temp = int.tryParse(obdData['05'] ?? '0') ?? 0;
        if (temp > 100) {
          score += (temp - 100) / 5;
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return score;
  }

  Future<void> stopTrip() async {
    if (!isRecording || _currentTrip == null) return;

    _currentTrip!.endTime = DateTime.now();

    // Save trip to file
    await _saveTripToFile(_currentTrip!);

    // Stop sensor monitoring
    await _accelSubscription?.cancel();
    await _gyroSubscription?.cancel();
    await _positionSubscription?.cancel();

    _accelSubscription = null;
    _gyroSubscription = null;
    _positionSubscription = null;
    _lastAccel = null;
    _lastGyro = null;
    _lastPosition = null;
    _previousPosition = null;
  }

  Future<void> _saveTripToFile(TripLog trip) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final tripsDir = Directory('${directory.path}/trips');
      if (!await tripsDir.exists()) {
        await tripsDir.create(recursive: true);
      }

      final file = File('${tripsDir.path}/${trip.id}.json');
      await file.writeAsString(json.encode(trip.toJson()));
    } catch (e) {
      print('Error saving trip: $e');
    }
  }

  Future<List<TripLog>> loadAllTrips() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final tripsDir = Directory('${directory.path}/trips');
      if (!await tripsDir.exists()) {
        return [];
      }

      final files = await tripsDir.list().where((f) => f.path.endsWith('.json')).toList();
      final trips = <TripLog>[];

      for (final file in files) {
        if (file is File) {
          try {
            final content = await file.readAsString();
            final tripJson = json.decode(content) as Map<String, dynamic>;
            trips.add(TripLog.fromJson(tripJson));
          } catch (e) {
            print('Error loading trip ${file.path}: $e');
          }
        }
      }

      trips.sort((a, b) => b.startTime.compareTo(a.startTime));
      return trips;
    } catch (e) {
      print('Error loading trips: $e');
      return [];
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/trips/$tripId.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting trip: $e');
    }
  }
}
