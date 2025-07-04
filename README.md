# Chat App - Flutter Mobile Client

This is the Flutter mobile client for the real-time chat application with Supabase integration.

## Features

- Real-time messaging with WebSockets
- User authentication (login/register)
- Send text messages, images, files, and audio recordings
- Light and dark theme support
- Responsive UI design
- File and audio attachments

## Setup Instructions

1. Make sure Flutter is installed on your system. If not, follow the [official Flutter installation guide](https://docs.flutter.dev/get-started/install).

2. Create a .env file in the root of the flutter_chat_app directory with the following content:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app in debug mode:
   ```bash
   flutter run
   ```

## Architecture

- **screens/** - Contains the main screens of the app (login, chat, splash)
- **services/** - Contains the service classes that handle authentication, chat functionality, and themes
- **widgets/** - Contains reusable UI components
- **utils/** - Contains utility functions and helper methods
- **models/** - Contains data model classes

## Environment Setup

The app requires Supabase credentials to function properly. These should be placed in the `.env` file as mentioned above. The credentials should match those used in the web version of the chat app to ensure compatibility.

## Notes

- This app is designed to work with the existing Supabase backend used by the web client
- The UI is designed to be familiar to users of the web version while optimizing for mobile
- The app supports both light and dark themes, with automatic switching based on device settings

## Requirements

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- Android SDK 21+ or iOS 12+#   c h a t _ a p p - w i t h - s u p a b a s e - 2  
 