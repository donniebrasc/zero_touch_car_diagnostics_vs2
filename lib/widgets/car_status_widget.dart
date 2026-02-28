import 'package:flutter/material.dart';

/// Displays real-time vehicle status with car graphics and health indicators
class CarStatusWidget extends StatefulWidget {
  final Map<String, String> obdData;
  final bool isConnected;
  final bool isRecording;

  const CarStatusWidget({
    required this.obdData,
    required this.isConnected,
    this.isRecording = false,
  });

  @override
  State<CarStatusWidget> createState() => _CarStatusWidgetState();
}

class _CarStatusWidgetState extends State<CarStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String key) {
    final value = _parseValue(key);
    if (value == null) return Colors.grey;

    switch (key.toLowerCase()) {
      case 'rpm':
        return value > 4000 ? Colors.red : (value > 2000 ? Colors.orange : Colors.green);
      case 'speed':
        return value > 100 ? Colors.orange : Colors.green;
      case 'coolant':
        return value > 100 ? Colors.red : (value > 90 ? Colors.orange : Colors.green);
      case 'load':
        return value > 80 ? Colors.red : (value > 50 ? Colors.orange : Colors.green);
      case 'fuel':
        return value < 20 ? Colors.red : (value < 50 ? Colors.orange : Colors.green);
      default:
        return Colors.blue;
    }
  }

  double? _parseValue(String key) {
    final value = widget.obdData[key];
    if (value == null) return null;
    try {
      return double.parse(value.split(' ')[0]);
    } catch (e) {
      return null;
    }
  }

  String _getHealthStatus() {
    final coolant = _parseValue('coolant');
    final load = _parseValue('load');
    final rpm = _parseValue('rpm');

    if (coolant != null && coolant > 105) return '⚠️ High Temp';
    if (load != null && load > 85) return '⚠️ High Load';
    if (rpm != null && rpm > 5000) return '⚠️ High RPM';

    return '✅ Healthy';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isConnected ? Colors.blue : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with connection status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.2).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: Text(
                  '🚗',
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.isConnected ? Icons.check_circle : Icons.cancel,
                        color: widget.isConnected ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          color: widget.isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isRecording) ...[
                    const SizedBox(height: 4),
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.1).animate(
                        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.radio_button_checked,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Recording',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Health Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getHealthStatus(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Key Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildMetricCard('RPM', 'rpm'),
              _buildMetricCard('Speed', 'speed'),
              _buildMetricCard('Coolant', 'coolant'),
              _buildMetricCard('Load', 'load'),
              _buildMetricCard('Fuel', 'fuel'),
              _buildMetricCard('Throttle', 'throttle'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String obdKey) {
    final value = widget.obdData[obdKey] ?? 'N/A';
    final color = _getStatusColor(obdKey);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
