import 'package:flutter/material.dart';
import '../../constants.dart';
import 'home_screen.dart';
import 'rezervasyonlarim_screen.dart';

// Misafir paneli ana sarmalayıcı - bottom nav bar ile sekme yönetimi
class GuestMainScreen extends StatefulWidget {
  const GuestMainScreen({super.key});

  @override
  State<GuestMainScreen> createState() => _GuestMainScreenState();
}

class _GuestMainScreenState extends State<GuestMainScreen> {
  int _secilenSekme = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      // IndexedStack: her iki sekme de canlı kalır, tekrar yüklenmez
      body: IndexedStack(
        index: _secilenSekme,
        children: const [
          HomeScreen(),
          ReservasyonlarimScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _secilenSekme,
        onTap: (index) => setState(() => _secilenSekme = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.teal,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border_outlined),
            activeIcon: Icon(Icons.bookmark),
            label: 'Rezervasyonlarım',
          ),
        ],
      ),
    );
  }
}
