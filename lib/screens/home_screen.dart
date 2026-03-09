import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/vehicle.dart';
import 'add_vehicle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      await context.read<AuthService>().signOut();
    }
  }

  void _navigateToAddVehicle() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddVehicleScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userEmail = authService.currentUser?.email ?? 'User';
    final userId = authService.currentUser?.uid;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildAppBar(userEmail),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildHeader(),
                ),
                const SizedBox(height: 24),
                // Vehicle List
                Expanded(
                  child: userId != null
                      ? _buildVehicleList(userId)
                      : _buildEmptyState(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar(String userEmail) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // User Info
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF6C63FF), const Color(0xFF8B7DFF)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 180,
                  child: Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Sign Out Button
        GestureDetector(
          onTap: _signOut,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.2),
                const Color(0xFF00D9FF).withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.garage_rounded,
            color: const Color(0xFF6C63FF),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Garage',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Your digital vehicle collection',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .orderBy('year', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: const Color(0xFF6C63FF)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: const Color(0xFFFF6B6B),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        final vehicles = docs.map((doc) => Vehicle.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            return _buildVehicleCard(vehicles[index], index);
          },
        );
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle, int index) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D9FF),
      const Color(0xFF4ADE80),
      const Color(0xFFFFB86C),
      const Color(0xFFFF6B9D),
    ];
    final accentColor = colors[index % colors.length];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to vehicle details
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.directions_car_rounded,
                      color: accentColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Year Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vehicle.year.toString(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${vehicle.make} ${vehicle.model}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.speed_rounded,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              vehicle.formattedMileage,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    const Color(0xFF00D9FF).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.garage_rounded,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 80,
                  ),
                  Positioned(
                    bottom: 25,
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: const Color(0xFF6C63FF),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Garage is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first vehicle to start\ntracking and managing your rides',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _navigateToAddVehicle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6C63FF), const Color(0xFF8B7DFF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Add Your First Vehicle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF6C63FF), const Color(0xFF8B7DFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToAddVehicle,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Add Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
