# How to Run and Use Certus

This guide provides step-by-step instructions on how to take the codebase provided in this folder, load it into Android Studio, compile the APK, install it on your Android phone, and use it.

## Part 1: Android Studio Setup

1. **Install Prerequisites**:
   - Download and install [Android Studio](https://developer.android.com/studio).
   - Download and install the [Flutter SDK](https://docs.flutter.dev/get-started/install/windows). Make sure lutter is added to your Windows PATH environment variable.

2. **Open the Project**:
   - Open Android Studio.
   - Click **Open** and navigate to D:\Ai governence & Consumer field ai\certus. Select the certus folder and click **OK**.
   
3. **Install Flutter Plugins**:
   - Android Studio will detect it's a Flutter project. If prompted, click **"Enable Flutter support"** or **"Pub get"**.
   - Alternatively, open the terminal in Android Studio (bottom left) and run:
     ``bash
     flutter pub get
     ``
   - This downloads all the required packages (like Camera, ML Kit, PDF, Speech-to-Text).

## Part 2: Preparing Your Mobile Phone

1. **Enable Developer Options**:
   - Go to your Android phone's **Settings** > **About Phone**.
   - Tap **Build Number** 7 times rapidly until it says "You are now a developer!".
   
2. **Enable USB Debugging**:
   - Go back to **Settings** > **System** > **Developer Options**.
   - Scroll down and enable **USB Debugging**.

3. **Connect to PC**:
   - Plug your phone into your computer using a USB cable. 
   - If a prompt appears on the phone asking "Allow USB debugging?", check "Always allow from this computer" and tap **Allow**.

## Part 3: Install the Local AI Model (Office Kit)

Because this is a completely offline hackathon project, the Gemma 4 E2B model must be loaded directly onto the phone.
1. Locate the dummy model we created at certus\models\gemma-4-E2B-it.litertlm (or download the real one from HuggingFace).
2. Connect your phone via USB or use Vivo's **Office Kit**.
3. Transfer the .litertlm file into the following directory on your phone:
   Internal Storage / Android / data / com.example.certus / files / models /
   *(Note: You will need to launch the app once for this folder to be created automatically).*

## Part 4: Building and Installing the APK

1. In Android Studio, look at the top toolbar. You should see your connected Android device listed in the dropdown next to the green "Play" button.
2. Ensure you have main.dart selected.
3. Click the **Run** button (the green Play triangle) or press Shift + F10.
4. Gradle will compile the app into an APK and push it to your phone. This may take 2-5 minutes the first time.
   *(Alternatively, run lutter run --release in the terminal for a faster, optimized version of the app).*

## Part 5: Using the App

1. **Launch**: Open **Certus** on your phone.
2. **Permissions**: You will be prompted for Camera and Microphone permissions. Accept them, as the app needs them to scan items and hear your voice.
3. **Scan an Item**:
   - Tap **Scan Product** or **Scan Bill**.
   - The camera will open with a targeting frame. Center the product's barcode and MRP, or the Bill's GSTIN, inside the frame.
   - Our QualityGate ensures the image is sharp enough before capturing.
4. **Get the Verdict**:
   - The OCR runs offline and the Rule Engine evaluates the text.
   - You will see either "No problems found" or "Check these points". 
5. **Ask a Question**:
   - On the result screen, tap the Microphone icon.
   - Ask: *"What is the issue with this bill?"* 
   - Certus will synthesize an answer using text-to-speech without using the internet!
6. **Generate Report**:
   - Tap the Share icon in the top right to generate a masked, privacy-safe PDF.

---
*Developed for the iQOO Hackathon.*
