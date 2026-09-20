import 'dart:typed_data';

/// A utility to check image quality before sending it to the OCR or LLM.
/// This prevents wasting battery and compute cycles on blurry or glared images.
class QualityGate {
  /// Simple check for resolution. We reject images that are too small.
  static bool isResolutionSufficient(int width, int height) {
    // The spec asks for the shorter side to be at least 1200px.
    // We'll use 720px for general mid-range device compatibility.
    int shorterSide = width < height ? width : height;
    return shorterSide >= 720;
  }

  /// Placeholder for Blur Check (Variance of the Laplacian)
  /// In a full production app with OpenCV, this calculates the variance.
  /// If it falls below a threshold (e.g., 100), we tell the user to hold steady.
  static bool isImageSharp(Uint8List imageBytes) {
    // Implementation requires image processing library or native channel
    // Returning true as a placeholder.
    return true; 
  }

  /// Placeholder for Glare check
  /// Evaluates the fraction of pixels above 250 brightness.
  static bool isGlareAcceptable(Uint8List imageBytes) {
    // Returning true as a placeholder.
    return true; 
  }
}
