import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'chat/chat_screen.dart';
import 'campaigns/campaigns_screen.dart';
import 'contacts/contacts_screen.dart';
import 'more/more_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    CampaignsScreen(),
    ChatScreen(),
    ContactsScreen(),
    MoreScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.15),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined, size: 24),
              label: 'Campaigns',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined, size: 22),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 24),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz, size: 24),
              label: 'More',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF136166),
          unselectedItemColor: const Color(0xFF98A2B3),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Geist',
            height: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Geist',
            height: 1.5,
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
