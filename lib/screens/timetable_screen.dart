import 'package:flutter/material.dart';
import 'bus_timetable_screen.dart';
import 'bike_route_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? selectedTransport;

  @override
  Widget build(BuildContext context) {
    final transports = [
      {'name': 'Rower', 'icon': Icons.pedal_bike, 'color': Colors.green},
      {'name': 'Autobus', 'icon': Icons.directions_bus, 'color': Colors.blue},
    ];

    void _goTo(String name) {
      if (name == 'Autobus') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BusTimetableScreen()),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BikeRouteScreen()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozkłady jazdy'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wybierz środek transportu:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: transports.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final item = transports[index];
                  final isSelected = selectedTransport == item['name'];

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(
                          () => selectedTransport = item['name'] as String);
                      _goTo(item['name'] as String);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (item['color'] as Color).withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? item['color'] as Color
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 60,
                            color: isSelected
                                ? item['color'] as Color
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['name'] as String,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? item['color'] as Color
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Brak przycisku "Dalej" — nawigacja dzieje się po tapnięciu w kafelek.
          ],
        ),
      ),
    );
  }
}
