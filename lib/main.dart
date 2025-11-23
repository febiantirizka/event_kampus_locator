import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

import 'event_data.dart';
import 'maps_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Event Kampus Locator",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.8,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? pos;
  String? alamat;
  String status = "";
  bool tracking = false;
  StreamSubscription<Position>? listener;

  Future<bool> cekIzin() async {
    bool service = await Geolocator.isLocationServiceEnabled();
    if (!service) {
      status = "GPS mati";
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }

    if (izin == LocationPermission.deniedForever ||
        izin == LocationPermission.denied) {
      status = "Izin ditolak";
      return false;
    }
    return true;
  }

  Future<void> getSekali() async {
    if (!await cekIzin()) return;

    pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> data =
        await placemarkFromCoordinates(pos!.latitude, pos!.longitude);

    setState(() {
      alamat =
          "${data.first.street}, ${data.first.subLocality}, ${data.first.locality}";
      status = "Lokasi diambil";
    });
  }

  Future<void> mulaiTracking() async {
    if (tracking) {
      await listener?.cancel();
      setState(() {
        tracking = false;
        status = "Tracking berhenti";
      });
      return;
    }

    if (!await cekIzin()) return;

    listener = Geolocator.getPositionStream().listen((Position newPos) async {
      pos = newPos;

      List<Placemark> data =
          await placemarkFromCoordinates(pos!.latitude, pos!.longitude);

      setState(() {
        alamat =
            "${data.first.street}, ${data.first.subLocality}, ${data.first.locality}";
        tracking = true;
        status = "Tracking...";
      });
    });
  }

  void bukaMapsEksternal() async {
    if (pos == null) return;

    final Uri url = Uri.parse(
        "https://www.google.com/maps?q=${pos!.latitude},${pos!.longitude}");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  double hitungJarak(double lat2, double lng2) {
    if (pos == null) return 0;

    return Geolocator.distanceBetween(
      pos!.latitude,
      pos!.longitude,
      lat2,
      lng2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Event Kampus Locator",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // STATUS CARD
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "Status: $status",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // LOKASI CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: pos == null
                  ? const Text("Belum ada lokasi",
                      style: TextStyle(fontSize: 15, color: Colors.black54))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Lat: ${pos!.latitude}",
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black87)),
                        Text("Lng: ${pos!.longitude}",
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black87)),
                        const SizedBox(height: 5),
                        const Text("Alamat:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black)),
                        Text(alamat ?? "",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54)),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: getSekali,
                  child: const Text("Get Current"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: mulaiTracking,
                  child: Text(tracking ? "Stop" : "Track"),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Colors.deepPurple, width: 1.4),
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: bukaMapsEksternal,
                  child: const Text("Maps"),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Event Kampus (jarak dari lokasi kamu)",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87),
              ),
            ),

            const SizedBox(height: 10),

            // EVENT LIST
            Expanded(
              child: ListView(
                children: eventList.map((e) {
                  double jarak = hitungJarak(e.lat, e.lng) / 1000;

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      title: Text(
                        e.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87),
                      ),
                      subtitle: pos == null
                          ? const Text("Jarak: -",
                              style: TextStyle(color: Colors.black54))
                          : Text(
                              "Jarak: ${jarak.toStringAsFixed(2)} km",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                      trailing: IconButton(
                        icon: const Icon(Icons.map, color: Colors.deepPurple),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapsPage(event: e, user: pos),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
