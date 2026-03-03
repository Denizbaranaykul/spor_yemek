import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'food_screen.dart';
import 'workout_screen.dart';
import 'analysis_screen.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  TutorialCoachMark? tutorialCoachMark;
  
  GlobalKey foodKey = GlobalKey();
  GlobalKey sportKey = GlobalKey();
  GlobalKey analysisKey = GlobalKey();
  GlobalKey profileKey = GlobalKey();
  GlobalKey notesKey = GlobalKey();

  final List<Widget> _screens = [
    const FoodScreen(),
    const WorkoutScreen(),
    const AnalysisScreen(),
    const NotesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    
    if (isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showTutorial();
        }
      });
    }
  }

  void _showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.black,
      textSkip: "Geç",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {},
      onClickTarget: (target) {},
      onClickOverlay: (target) {},
      onSkip: () => true,
    )..show(context: context);
  }

  List<TargetFocus> _createTargets() {
    return [
      TargetFocus(
        identify: "foodTarget",
        keyTarget: foodKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Yemek Ekranı", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Buradan yediklerinizi otomatik (Yapay Zeka) veya manuel olarak kaydedebilir, su tüketiminizi takip edebilirsiniz.", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "sportTarget",
        keyTarget: sportKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Spor Ekranı", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Antrenmanlarınızı, kardiyo, adım ve calisthenics hareketlerinizi bu ekrandan girin.", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "analysisTarget",
        keyTarget: analysisKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Analiz Ekranı", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Kayıtlarınıza ve makro alımınıza dair detaylı istatistikleri ve yapay zeka analizini buradan görebilirsiniz.", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "profileTarget",
        keyTarget: profileKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Profil Ekranı", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Kişisel bilgilerinizi, hedeflerinizi yönetmek ve çıkış yapmak için burayı kullanın.", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "notesTarget",
        keyTarget: notesKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Notlar Ekranı", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Buradan kendinize hatırlatıcı notlar bırakabilirsiniz.", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              );
            },
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: _currentIndex == 0
            ? Colors.amber
            : _currentIndex == 1
                ? Colors.cyan // Turquoise
                : _currentIndex == 2
                    ? Colors.red
                    : _currentIndex == 3
                        ? Colors.deepPurpleAccent
                        : Colors.green,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu, key: foodKey),
            label: 'Yemek',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center, key: sportKey),
            label: 'Spor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics, key: analysisKey),
            label: 'Analiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note, key: notesKey),
            label: 'Notlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, key: profileKey),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

