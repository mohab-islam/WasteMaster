import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isProcessing = false;
  MobileScannerController controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; 

    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue == null) continue;

      setState(() => _isProcessing = true);
      
      final String code = barcode.rawValue!;
      debugPrint('Barcode found: $code');

      try {
        // Call API to Claim Points
        final response = await ApiService.claimPoints(code);
        
        if (mounted) {
           _showSuccessDialog(response['message'], response['newTotalPoints']);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll("Exception:", "")}'),
              backgroundColor: Colors.red,
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _isProcessing = false);
        }
      }
      break; 
    }
  }

  void _showSuccessDialog(String message, int newPoints) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppTheme.secondaryGreen, size: 60),
            SizedBox(height: 10),
            Text('Success!', style: TextStyle(color: AppTheme.textLight)),
          ],
        ),
        content: Text(
          '$message\n\nTotal Points: $newPoints', 
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textDim),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _isProcessing = false);
              },
              child: const Text('Scan Another'),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code'), centerTitle: true),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Simple visual guide (non-restrictive)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryGold.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0, 
            right: 0,
            child: const Text(
               'Point camera at QR Code',
               textAlign: TextAlign.center,
               style: TextStyle(
                 color: Colors.white, 
                 fontSize: 18, 
                 fontWeight: FontWeight.bold,
                 shadows: [Shadow(color: Colors.black, blurRadius: 4)]
               ),
            ),
          )
        ],
      ),
    );
  }
}

// Removed QrScannerOverlayShape class as it is no longer needed
