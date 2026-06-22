import 'package:flutter/material.dart';

import '../app.dart';
import '../services/models.dart';
import '../services/sip_service.dart';
import '../widgets/glass_widgets.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen({super.key});

  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  final SipService _sipService = SipService.instance;
  final TextEditingController _numberController = TextEditingController();

  final List<String> _digits = const [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '*', '0', '#',
  ];

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _appendDigit(String digit) {
    _numberController.text = '${_numberController.text}$digit';
    _numberController.selection = TextSelection.fromPosition(
      TextPosition(offset: _numberController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Dialpad', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.callLog),
            icon: const Icon(Icons.history),
            tooltip: 'Call Logs',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _sipService,
        builder: (context, _) {
          final canCall =
              _sipService.registrationStatus == SipRegistrationStatus.registered;

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: Column(
              children: [
                GlassTextField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  labelText: 'Phone Number / Extension',
                  suffixIcon: IconButton(
                    onPressed: () {
                      final current = _numberController.text;
                      if (current.isEmpty) {
                        return;
                      }
                      _numberController.text =
                          current.substring(0, current.length - 1);
                    },
                    icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      Icon(
                        canCall ? Icons.check_circle : Icons.error_outline,
                        color: canCall ? Colors.greenAccent : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _sipService.statusMessage,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_sipService.lastError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _sipService.lastError,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final availableHeight = constraints.maxHeight;

                      final spacing = 16.0;
                      final itemWidth = (availableWidth - (2 * spacing)) / 3;
                      final itemHeight = (availableHeight - (3 * spacing)) / 4;

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _digits.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: itemWidth / itemHeight,
                        ),
                        itemBuilder: (context, index) {
                          final digit = _digits[index];
                          final minDim = itemWidth < itemHeight ? itemWidth : itemHeight;
                          return GlassButton(
                            isCircle: false,
                            borderRadius: 24.0,
                            onPressed: () => _appendDigit(digit),
                            child: Text(
                              digit,
                              style: TextStyle(
                                fontSize: minDim * 0.4,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _numberController,
                  builder: (context, value, _) {
                    final destination = value.text.trim();
                    return GlassButton(
                      borderRadius: 32,
                      color: canCall && destination.isNotEmpty
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.1),
                      onPressed: (!canCall || destination.isEmpty)
                          ? null
                          : () async {
                              final ok = await _sipService.makeCall(destination);
                              if (!ok) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_sipService.lastError)),
                                );
                                return;
                              }
                              if (!context.mounted) return;
                              Navigator.pushNamed(
                                context,
                                AppRoutes.call,
                                arguments: destination,
                              );
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call, color: canCall && destination.isNotEmpty ? Colors.white : Colors.white54, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            canCall ? 'Call' : 'Register from Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: canCall && destination.isNotEmpty ? Colors.white : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
