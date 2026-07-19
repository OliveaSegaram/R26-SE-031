import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'welcome_screen.dart'; // For logout routing
import 'assessment_screen.dart';
import 'add_student_screen.dart';
import '../services/auth_service.dart';
class ParentAccountScreen extends StatefulWidget {
  const ParentAccountScreen({super.key});

  @override
  State<ParentAccountScreen> createState() => _ParentAccountScreenState();
}

class _ParentAccountScreenState extends State<ParentAccountScreen> {
  // Dummy State for switches
  bool progressEmails = true;
  bool promotions = false;
  bool newsletters = false;
  bool periodicUpdates = true;

  bool _isLoading = true;
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService().getUserProfile();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (profile != null) {
          _userName = profile['name'] ?? 'Unknown';
          _userEmail = profile['email'] ?? 'Unknown';
        } else {
          _userName = 'Error loading profile';
          _userEmail = '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Parent Account',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Account'),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildAccountCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Manage Students'),
            _buildStudentsCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Manage Subscription'),
            _buildSubscriptionCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Email Settings'),
            _buildEmailSettingsCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Additional Help'),
            _buildHelpCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.mint,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSlateLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.mint.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildAccountCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Owner Name', _userName),
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow('Email', _userEmail),
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow('Password', '********'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _showChangePasswordDialog();
              },
              icon: const Icon(Icons.edit, color: AppColors.orange, size: 18),
              label: Text(
                'EDIT PASSWORD',
                style: GoogleFonts.fredoka(color: AppColors.orange),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStudentsCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Row(
            children: [
              Expanded(flex: 2, child: _buildTableHeader('Student')),
              Expanded(flex: 1, child: _buildTableHeader('Grade')),
              Expanded(flex: 2, child: _buildTableHeader('Time Limit')),
            ],
          ),
          const SizedBox(height: 12),
          // Student 1
          Row(
            children: [
              Expanded(flex: 2, child: _buildTableData('Alex')),
              Expanded(flex: 1, child: _buildTableData('3rd')),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlate,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('No Limit', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight)),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddStudentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: AppColors.mint, size: 18),
              label: Text(
                'ADD STUDENT',
                style: GoogleFonts.fredoka(color: AppColors.mint),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Current Plan', 'Premium Monthly'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showComingSoon('Cancel Subscription');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showComingSoon('Hold Subscription');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold, side: const BorderSide(color: AppColors.gold),
                  ),
                  child: const Text('HOLD'),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 32),
          _buildInfoRow('Payment Method', 'Visa ending in 4242'),
          const SizedBox(height: 8),
          _buildInfoRow('Next Payment', 'Aug 15, 2026 (\$9.99)'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _showComingSoon('Update Payment Method');
              },
              icon: const Icon(Icons.credit_card, color: AppColors.mint, size: 18),
              label: Text(
                'UPDATE PAYMENT',
                style: GoogleFonts.fredoka(color: AppColors.mint),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmailSettingsCard() {
    return _buildCardContainer(
      child: Column(
        children: [
          _buildSwitchRow('Progress Emails', progressEmails, (val) {
            setState(() => progressEmails = val);
          }),
          const Divider(color: Colors.white12),
          _buildSwitchRow('Promotions', promotions, (val) {
            setState(() => promotions = val);
          }),
          const Divider(color: Colors.white12),
          _buildSwitchRow('Newsletters', newsletters, (val) {
            setState(() => newsletters = val);
          }),
          const Divider(color: Colors.white12),
          _buildSwitchRow('Periodic Updates', periodicUpdates, (val) {
            setState(() => periodicUpdates = val);
          }),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Email Support', 'support@adaptedmind.com'),
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow('Phone Support', '1-800-123-4567'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('LOGOUT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkSlate,
                foregroundColor: Colors.white,
                side: BorderSide(color: AppColors.mint.withValues(alpha: 0.5)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: [
            Text(
              value ? 'ON' : 'OFF',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: value ? AppColors.mint : AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.mint,
              activeTrackColor: AppColors.mint.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.darkSlate,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.mint,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTableData(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon!')),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.darkSlate,
              title: Text('Change Password', style: TextStyle(color: AppColors.mint)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.mint)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.mint)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          final error = await AuthService().changePassword(
                            oldPasswordController.text,
                            newPasswordController.text,
                          );

                          setState(() {
                            isLoading = false;
                          });

                          if (error != null) {
                            setState(() {
                              errorMessage = error;
                            });
                          } else {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
                  child: isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(color: AppColors.darkSlate)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
