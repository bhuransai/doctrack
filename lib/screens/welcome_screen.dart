import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/doc_store.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';

/// The app's opening screen: brief DocTrack branding plus an optional name,
/// then straight into the Documents tab. DocTrack has no accounts, so this
/// is a splash/welcome screen rather than a login — there's nothing to
/// authenticate against. Shown once; [DocStore.completeOnboarding] marks it
/// done so later launches skip straight to [AppShell].
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _enter(BuildContext context) {
    context.read<DocStore>().completeOnboarding(_nameController.text);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkStrong,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.shield_moon_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 24),
              Text(
                'DocTrack',
                style: AppText.sans(size: 32, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4),
              ),
              const SizedBox(height: 10),
              Text(
                'Track every passport, licence and policy\nin one place — and never miss a renewal.',
                textAlign: TextAlign.center,
                style: AppText.sans(size: 14, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.64), height: 1.5),
              ),
              const Spacer(flex: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'YOUR NAME · OPTIONAL',
                  style: AppText.mono(size: 10, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.4),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: AppText.sans(size: 14.5, weight: FontWeight.w600, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Aarav',
                  hintStyle: AppText.sans(size: 14.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Used to personalise your expiry reminders.',
                  style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => _enter(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Text('Get started', style: AppText.sans(size: 14.5, weight: FontWeight.w700, color: AppColors.onLight)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No account needed — everything stays on this device.',
                textAlign: TextAlign.center,
                style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
