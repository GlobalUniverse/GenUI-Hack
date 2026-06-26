import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/chat_provider.dart';

class UserPickerScreen extends StatefulWidget {
  const UserPickerScreen({super.key});

  @override
  State<UserPickerScreen> createState() => _UserPickerScreenState();
}

class _UserPickerScreenState extends State<UserPickerScreen> {
  String? _loading;

  static const _profiles = [
    _Profile(
      id: 'alex',
      name: 'Alex Chen',
      tagline: 'Living paycheck to paycheck',
      avatarColor: Color(0xFFEF4444),
      initials: 'AC',
      detail: 'Dining +45% · Rideshare +62% · Rent due tomorrow',
      health: 0.15,
      healthLabel: 'Tight',
      healthColor: Color(0xFFEF4444),
    ),
    _Profile(
      id: 'jordan',
      name: 'Jordan Kim',
      tagline: 'Saving for a house',
      avatarColor: Color(0xFF16A34A),
      initials: 'JK',
      detail: '3 active goals · Net +\$4,310/mo · Emergency fund complete',
      health: 0.88,
      healthLabel: 'Healthy',
      healthColor: Color(0xFF16A34A),
    ),
    _Profile(
      id: 'sam',
      name: 'Sam Rivera',
      tagline: 'Trying to get back on track',
      avatarColor: Color(0xFFF59E0B),
      initials: 'SR',
      detail: 'Spending > income · Rent overdue · No savings',
      health: 0.05,
      healthLabel: 'Critical',
      healthColor: Color(0xFFEF4444),
    ),
  ];

  Future<void> _select(BuildContext ctx, String profileId) async {
    setState(() => _loading = profileId);
    await ctx.read<ChatProvider>().loadProfile(profileId);
    if (ctx.mounted) {
      Navigator.of(ctx).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 52),
              const Text(
                'FinPilot',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a user to see their personalized experience.',
                style: TextStyle(color: AppColors.inkMid, fontSize: 14),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.separated(
                  itemCount: _profiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _ProfileCard(
                    profile: _profiles[i],
                    isLoading: _loading == _profiles[i].id,
                    onTap: _loading != null ? null : () => _select(ctx, _profiles[i].id),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Profile {
  final String id;
  final String name;
  final String tagline;
  final Color avatarColor;
  final String initials;
  final String detail;
  final double health;
  final String healthLabel;
  final Color healthColor;

  const _Profile({
    required this.id,
    required this.name,
    required this.tagline,
    required this.avatarColor,
    required this.initials,
    required this.detail,
    required this.health,
    required this.healthLabel,
    required this.healthColor,
  });
}

class _ProfileCard extends StatelessWidget {
  final _Profile profile;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ProfileCard({required this.profile, required this.isLoading, this.onTap}); // ignore: unused_element

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: (onTap == null && !isLoading) ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: profile.avatarColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      profile.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.tagline,
                          style: const TextStyle(color: AppColors.inkMid, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                    )
                  else
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.inkLight),
                ],
              ),
              const SizedBox(height: 16),
              // Health bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: profile.health,
                        minHeight: 5,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(profile.healthColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    profile.healthLabel,
                    style: TextStyle(
                      color: profile.healthColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                profile.detail,
                style: const TextStyle(color: AppColors.inkLight, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
