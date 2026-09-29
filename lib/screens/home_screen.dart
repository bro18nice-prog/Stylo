import 'package:flutter/material.dart';

import 'add_clothing_screen.dart';
import 'wardrobe_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Outfit"), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CircleAvatar(radius: 55, child: Icon(Icons.person, size: 60)),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "Bine ai revenit!",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            const Center(
              child: Text(
                "Construiește-ți outfitul perfect.",
                style: TextStyle(fontSize: 17, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 35),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Icon(Icons.wb_sunny, size: 45, color: Colors.orange),
                    SizedBox(height: 10),
                    Text(
                      "Outfit-ul zilei",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "În curând AI-ul îți va recomanda ținuta ideală.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text(
                  "Adaugă haine",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddClothingScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.checkroom),
                label: const Text(
                  "Garderoba mea",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WardrobeScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 55,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text("Setări", style: TextStyle(fontSize: 18)),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
