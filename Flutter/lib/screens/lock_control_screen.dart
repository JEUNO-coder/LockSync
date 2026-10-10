import 'package:flutter/material.dart';
import 'auth_screen.dart';

class LockControlScreen extends StatefulWidget {
  const LockControlScreen({super.key});

  @override
  State<LockControlScreen> createState() => _LockControlScreenState();
}

class _LockControlScreenState extends State<LockControlScreen>
    with SingleTickerProviderStateMixin {
  // Lock state
  bool _isLocked = true;
  bool _isProcessing = false;
  String _deviceName = 'LOCKER 01';

  // Navigation tab index:
  // 0: HISTORY (Left)
  // 1: LOCK (Middle - Circular with ring)
  // 2: SETTINGS (Right)
  int _currentNavIndex = 1;

  // Animation controller for tactile lock feedback
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  // Live activity log
  final List<Map<String, dynamic>> _activityLog = [
    {
      'title': 'Locker unlocked',
      'subtitle': 'Biometric access',
      'time': 'Today, 10:42 AM',
      'isUnlock': true,
    },
    {
      'title': 'Locker secured',
      'subtitle': 'Auto-lock timer (30s)',
      'time': 'Today, 08:15 AM',
      'isUnlock': false,
    },
    {
      'title': 'Locker secured',
      'subtitle': 'Manual command via app',
      'time': 'Yesterday, 06:20 PM',
      'isUnlock': false,
    },
    {
      'title': 'Locker unlocked',
      'subtitle': 'NFC Master Key',
      'time': 'Yesterday, 01:12 PM',
      'isUnlock': true,
    },
    {
      'title': 'System online',
      'subtitle': 'Arduino ESP32 handshake',
      'time': 'Yesterday, 08:00 AM',
      'isUnlock': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleLockState({bool isBiometric = false}) {
    if (_isProcessing) return;

    _animController.forward().then((_) {
      _animController.reverse();
    });

    setState(() {
      _isLocked = !_isLocked;
      final newEvent = {
        'title': _isLocked ? 'Locker secured' : 'Locker unlocked',
        'subtitle': isBiometric ? 'Biometric access' : 'LockSync app control',
        'time': 'Just now',
        'isUnlock': !_isLocked,
      };
      _activityLog.insert(0, newEvent);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D141F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF00D4FF), width: 1),
        ),
        content: Row(
          children: [
            Icon(
              _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: const Color(0xFF00D4FF),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              _isLocked
                  ? 'ARDUINO: LOCK ENGAGED'
                  : 'ARDUINO: LOCK RELEASED',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFFF1F5F9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeviceRenameDialog() {
    final controller = TextEditingController(text: _deviceName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D141F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF162232), width: 1),
          ),
          title: const Text(
            'RENAME DEVICE',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFFF1F5F9),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a custom identifier for this Arduino locker unit.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF7A889B),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF080C10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF162232)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13.5,
                    color: Color(0xFFF1F5F9),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: Color(0xFF7A889B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _deviceName = controller.text.trim().toUpperCase();
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: const Color(0xFF080C10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'SAVE',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C10),
      // Persistent Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 74,
        decoration: const BoxDecoration(
          color: Color(0xFF080C10),
          border: Border(
            top: BorderSide(
              color: Color(0xFF14202C),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // 1. HISTORY TAB (ON LEFT SIDE)
              Expanded(
                child: _buildBottomNavItem(
                  index: 0,
                  icon: Icons.history_rounded,
                  label: 'HISTORY',
                  isSelected: _currentNavIndex == 0,
                  onTap: () => setState(() => _currentNavIndex = 0),
                ),
              ),

              // 2. LOCK TAB (IN THE MIDDLE - CIRCULAR WITH A RING AROUND IT)
              Expanded(
                child: _buildCircularMiddleNavItem(
                  isSelected: _currentNavIndex == 1,
                  onTap: () => setState(() => _currentNavIndex = 1),
                ),
              ),

              // 3. SETTINGS TAB (ON RIGHT SIDE)
              Expanded(
                child: _buildBottomNavItem(
                  index: 2,
                  icon: Icons.settings_outlined,
                  label: 'SETTINGS',
                  isSelected: _currentNavIndex == 2,
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              children: [
                _buildFixedTopHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildCurrentTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FIXED TOP HEADER (CENTERED WITH CAMERA CLEARANCE)
  // ==========================================
  Widget _buildFixedTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 26.0, // Pushed down to clear top-center camera cutout / punch hole
        bottom: 12.0,
        left: 20.0,
        right: 20.0,
      ),
      alignment: Alignment.center,
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.8,
          ),
          children: [
            TextSpan(
              text: 'LOCK',
              style: TextStyle(color: Color(0xFFF1F5F9)),
            ),
            TextSpan(
              text: 'SYNC',
              style: TextStyle(color: Color(0xFF00D4FF)),
            ),
          ],
        ),
      ),
    );
  }

  // Choose tab body
  Widget _buildCurrentTabContent() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHistoryTabContent();
      case 2:
        return _buildSettingsTabContent();
      case 1:
      default:
        return _buildLockTabContent();
    }
  }

  // ==========================================
  // TAB 1: MAIN LOCK CONTROL (CENTER FOCUS, NO HISTORY)
  // ==========================================
  Widget _buildLockTabContent() {
    return SingleChildScrollView(
      key: const ValueKey('lock_tab_content'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Locker Identity
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONNECTED DEVICE',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Color(0xFF6B7C93),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    _deviceName,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Color(0xFFF1F5F9),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _showDeviceRenameDialog,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF00D4FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Arduino Smart Lock',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A889B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // 3. Main Interactive Circular Lock with Concentric Ring
          Center(
            child: GestureDetector(
              key: const Key('main_lock_circle_button'),
              onTap: () => _toggleLockState(isBiometric: false),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: 224,
                  height: 224,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF080C10),
                    // Thin outer boundary border
                    border: Border.all(
                      color: const Color(0xFF14202C),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4FF).withOpacity(
                          _isLocked ? 0.16 : 0.32,
                        ),
                        blurRadius: _isLocked ? 38 : 46,
                        spreadRadius: _isLocked ? 2 : 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Concentric Ring 2: Active Outer Track
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        width: 206,
                        height: 206,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isLocked
                                ? const Color(0xFF00D4FF).withOpacity(0.55)
                                : const Color(0xFF00D4FF),
                            width: _isLocked ? 1.5 : 2.0,
                          ),
                        ),
                      ),

                      // Concentric Ring 3: Hairline inner boundary
                      Container(
                        width: 174,
                        height: 174,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF142232),
                            width: 1.0,
                          ),
                        ),
                      ),

                      // Concentric Ring 4: Inner Core Elevated Disk
                      Container(
                        width: 152,
                        height: 152,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0B121A),
                          border: Border.all(
                            color: const Color(0xFF1A2838),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated Padlock Icon
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(
                                scale: anim,
                                child: child,
                              ),
                              child: Icon(
                                _isLocked
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_rounded,
                                key: ValueKey<bool>(_isLocked),
                                size: 44,
                                color: const Color(0xFF00D4FF),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status Heading
                            Text(
                              _isLocked ? 'LOCKED' : 'UNLOCKED',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                                color: _isLocked
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF00D4FF),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Instruction Label
                            Text(
                              _isLocked ? 'TAP TO UNLOCK' : 'TAP TO LOCK',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                                color: _isLocked
                                    ? const Color(0xFF6B7C93)
                                    : const Color(0xFF00D4FF).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // 4. Device Status Panel (3 Columns)
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D141F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF162232),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                // COLUMN 1: SIGNAL
                Expanded(
                  child: _buildStatusColumn(
                    label: 'SIGNAL',
                    icon: Icons.wifi_rounded,
                    value: 'STRONG',
                    valueColor: const Color(0xFFF1F5F9),
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 36,
                  color: const Color(0xFF162232),
                ),

                // COLUMN 2: DEVICE
                Expanded(
                  child: _buildStatusColumn(
                    label: 'DEVICE',
                    icon: Icons.developer_board_rounded,
                    value: 'ONLINE',
                    valueColor: const Color(0xFF00D4FF),
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 36,
                  color: const Color(0xFF162232),
                ),

                // COLUMN 3: STATE
                Expanded(
                  child: _buildStatusColumn(
                    label: 'STATE',
                    icon: _isLocked
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    value: _isLocked ? 'LOCKED' : 'OPEN',
                    valueColor: const Color(0xFF00D4FF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 5. Biometric Primary Button Action
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              key: const Key('primary_biometric_button'),
              onPressed: () => _toggleLockState(isBiometric: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: const Color(0xFF080C10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isLocked
                            ? Icons.fingerprint_rounded
                            : Icons.lock_rounded,
                        size: 19,
                        color: const Color(0xFF080C10),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLocked ? 'UNLOCK WITH BIOMETRICS' : 'LOCK DEVICE',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFF080C10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 0: ACCESS HISTORY SCREEN (ON LEFT SIDE)
  // ==========================================
  Widget _buildHistoryTabContent() {
    return Column(
      key: const ValueKey('history_tab_content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 14.0),
          child: Text(
            'HISTORY LOG',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Color(0xFFF1F5F9),
            ),
          ),
        ),
        const Divider(color: Color(0xFF162232), height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            itemCount: _activityLog.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final event = _activityLog[index];
              final isUnlock = event['isUnlock'] as bool;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF090F17),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF162232),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isUnlock
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                        color: const Color(0xFF00D4FF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] as String,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF1F5F9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event['subtitle'] as String,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: Color(0xFF7A889B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      event['time'] as String,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: Color(0xFF5A6B80),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: SETTINGS SCREEN (ON RIGHT SIDE)
  // ==========================================
  Widget _buildSettingsTabContent() {
    return SingleChildScrollView(
      key: const ValueKey('settings_tab_content'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEVICE SETTINGS',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hardware telemetry and connectivity configurations.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: Color(0xFF7A889B),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D141F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF162232)),
            ),
            child: Column(
              children: [
                _buildSettingRow(
                  icon: Icons.memory_rounded,
                  title: 'Microcontroller',
                  value: 'Arduino Nano ESP32',
                ),
                const Divider(color: Color(0xFF162232)),
                _buildSettingRow(
                  icon: Icons.system_update_alt_rounded,
                  title: 'Firmware Version',
                  value: 'v2.4.1 (Latest)',
                ),
                const Divider(color: Color(0xFF162232)),
                _buildSettingRow(
                  icon: Icons.timer_outlined,
                  title: 'Auto-Lock Timeout',
                  value: '30 Seconds',
                ),
                const Divider(color: Color(0xFF162232)),
                _buildSettingRow(
                  icon: Icons.bluetooth_connected_rounded,
                  title: 'UART Baud Rate',
                  value: '115200 bps',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF5252),
                side: const BorderSide(
                  color: Color(0xFFFF5252),
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'DISCONNECT & SIGN OUT',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatusColumn({
    required String label,
    required IconData icon,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Color(0xFF6B7C93),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: valueColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF00D4FF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFFF1F5F9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              color: Color(0xFF7A889B),
            ),
          ),
        ],
      ),
    );
  }

  // Standard Bottom Nav Item for History (Left) and Settings (Right)
  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF00D4FF);
    final inactiveColor = const Color(0xFF6B7C93);

    return InkWell(
      key: Key('bottom_nav_$label'),
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 1.2,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  // Circular Middle Button with Ring Around It (LOCK in the middle)
  Widget _buildCircularMiddleNavItem({
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: const Key('bottom_nav_LOCK_circular'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular button with a cyan ring around it
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B121A),
              border: Border.all(
                color: const Color(0xFF00D4FF),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(
                    isSelected ? 0.45 : 0.20,
                  ),
                  blurRadius: isSelected ? 14 : 8,
                  spreadRadius: isSelected ? 1.5 : 0.5,
                ),
              ],
            ),
            child: Icon(
              _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 20,
              color: const Color(0xFF00D4FF),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'LOCK',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 1.2,
              color: isSelected
                  ? const Color(0xFF00D4FF)
                  : const Color(0xFF6B7C93),
            ),
          ),
        ],
      ),
    );
  }
}
