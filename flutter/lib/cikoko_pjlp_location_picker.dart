import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class CikokoPjlpLocationPicker extends StatefulWidget {
  const CikokoPjlpLocationPicker({
    super.key,
    required this.currentLocation,
    this.savedLocation,
  });

  final Future<LatLng> Function() currentLocation;
  final LatLng? savedLocation;

  @override
  State<CikokoPjlpLocationPicker> createState() => _CikokoPjlpLocationPickerState();
}

class _CikokoPjlpLocationPickerState extends State<CikokoPjlpLocationPicker> {
  final controller = MapController();
  late LatLng center = widget.savedLocation ?? const LatLng(-6.24, 106.84);
  late bool pointSelected = widget.savedLocation != null;
  bool locating = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> useGps() async {
    setState(() => locating = true);
    try {
      final position = await widget.currentLocation();
      if (!mounted) return;
      controller.move(position, 18);
      setState(() {
        center = position;
        pointSelected = true;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih lokasi di peta')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: controller,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: widget.savedLocation == null ? 15 : 18,
                    minZoom: 4,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged: (camera, hasGesture) {
                      center = camera.center;
                      if (hasGesture && !pointSelected) {
                        setState(() => pointSelected = true);
                      }
                    },
                    onTap: (_, point) {
                      controller.move(point, controller.camera.zoom);
                      if (!pointSelected) setState(() => pointSelected = true);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      maxNativeZoom: 19,
                      userAgentPackageName: 'com.KelurahanCikoko.malik',
                    ),
                  ],
                ),
                Center(child: IgnorePointer(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Icon(Icons.location_on, color: colors.primary, size: 42),
                  ),
                )),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: colors.surface,
                    child: InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Geser peta atau ketuk titik agar pin berada tepat di lokasi.'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: locating ? null : useGps,
                  icon: const Icon(Icons.my_location),
                  label: Text(locating ? 'Mencari lokasi…' : 'Gunakan GPS HP'),
                ),
                FilledButton.icon(
                  onPressed: pointSelected && !locating
                      ? () => Navigator.pop(context, center) : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Gunakan titik ini'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
