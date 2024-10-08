# PRAKRITI

## Getting Started

To get started with this Flutter project, follow these steps:

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Zadracker/Prakriti.git
   cd Prakriti
   ```

2. **Install Dependencies**
   Run the following command to install the project dependencies:
   ```bash
   flutter pub get
   ```

3. **Run the Project**

   - **For Web:**
     ```bash
     flutter run -d chrome
     ```
     This will build and run the project in your default web browser.

   - **For Android:**
     - Ensure you have an Android Virtual Device (AVD) running or an Android device connected with USB debugging enabled.
     - Then run:
       ```bash
       flutter run
       ```
     This will build and run the project on the connected Android device or emulator.

4. **Configuration**
   - **API Keys:** Make sure to replace the placeholders in the `.env` file with your own `NEWS_API` and `API_KEY` (gemini) keys.

## For judges
- For judges I have implemented a method for them to automatically change user roles and test all roles - the codes are stored in.env file - refer them. Use the codes in the bank page. Make sure to re-login after changing roles to make sure the changes takes place

## Additional notes
- Ensure you have Flutter installed on your machine. If not, follow the [Flutter installation guide](https://flutter.dev/docs/get-started/install).
- If you encounter any issues, check the [Flutter documentation](https://flutter.dev/docs) or refer to the project’s issue tracker for troubleshooting.
