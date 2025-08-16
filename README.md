# TaskFlow Flutter

A comprehensive task management system built with Flutter, recreated from the original JavaScript web application.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## 🎯 Overview

TaskFlow Flutter is a mobile/desktop recreation of the original TaskFlow web application. It provides a comprehensive task management solution with a modern, intuitive interface built using Flutter.

## ✨ Features

### 🔐 Authentication
- **Login/Register**: Secure user authentication with form validation
- **Password Requirements**: Real-time password strength validation
- **Secure Storage**: Token-based authentication with secure local storage

### 📊 Dashboard
- **Statistics Overview**: Real-time task statistics and metrics
- **Quick Actions**: Easy access to common operations
- **Animated Cards**: Beautiful material design with animations
- **Pull-to-Refresh**: Keep data up-to-date with intuitive gestures

### ✅ Task Management
- **Task Creation**: Create tasks with priority, category, and due dates
- **Task Filtering**: Filter by status, priority, and search functionality
- **Task Views**: Toggle between "Assigned to Me" and "Pending Tasks"
- **Priority Levels**: Critical, High, Medium, Low, and Lowest priorities
- **Categories**: Organize tasks by Development, Design, Marketing, etc.

### 👥 Team Management
- **Team Overview**: View all team members and their roles
- **User Profiles**: Display user information and avatars
- **Member Statistics**: Track team performance and activity

### 📈 Reports & Analytics
- **Performance Metrics**: Comprehensive analytics dashboard
- **Export Functionality**: Export reports in CSV, PDF, and Excel formats
- **Date Filtering**: Custom date range selection for reports
- **Visual Charts**: Beautiful charts and graphs (coming soon)

## 🏗️ Architecture

The app follows a clean architecture pattern with:

### 📁 Project Structure
```
lib/
├── constants/          # App-wide constants (colors, themes)
├── models/            # Data models (User, Task, etc.)
├── providers/         # Riverpod state management
├── screens/           # UI screens and pages
├── services/          # API services and external integrations
├── utils/             # Utility functions and helpers
└── widgets/           # Reusable UI components
```

### 🛠️ Tech Stack
- **Flutter**: Cross-platform UI framework
- **Riverpod**: State management solution
- **Dio**: HTTP client for API calls
- **Go Router**: Navigation and routing
- **Google Fonts**: Typography
- **Secure Storage**: Token and sensitive data storage
- **Charts**: Analytics and data visualization

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator / Android Emulator (for testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd taskflow_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure the API endpoint**
   Update the API base URL in `lib/services/api_service.dart`:
   ```dart
   static const String _baseUrl = 'YOUR_API_ENDPOINT';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### 📱 Supported Platforms
- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ macOS (coming soon)
- ✅ Windows (coming soon)
- ✅ Linux (coming soon)

## 📚 API Integration

The app integrates with the TaskFlow backend API providing:

### Endpoints
- **Authentication**: `/api/auth/login`, `/api/auth/register`
- **Tasks**: `/api/tasks` (CRUD operations)
- **Users**: `/api/users` (team management)
- **Dashboard**: `/api/dashboard/stats`
- **Reports**: `/api/reports/*`

### Authentication Flow
1. User credentials are validated against the API
2. JWT tokens are received and stored securely
3. All subsequent requests include the token in headers
4. Automatic token refresh and logout handling

## 🎨 Design System

### Color Palette
- **Primary**: #4F46E5 (Indigo)
- **Secondary**: #7C3AED (Purple)
- **Success**: #10B981 (Green)
- **Warning**: #F59E0B (Amber)
- **Error**: #EF4444 (Red)

### Typography
- **Font Family**: Inter (Google Fonts)
- **Headings**: 800-700 weight
- **Body**: 400-500 weight
- **Captions**: 400 weight

### Components
- **Gradient Backgrounds**: Beautiful gradient overlays
- **Glass Morphism**: Modern frosted glass effects
- **Animated Cards**: Smooth hover and tap animations
- **Custom Buttons**: Consistent button styles and states

## 🔧 Development

### State Management
The app uses **Riverpod** for state management with providers for:
- Authentication state
- Dashboard statistics
- Task management
- User data

### Navigation
**Go Router** handles navigation with:
- Route guards for authentication
- Nested routing for main app tabs
- Custom transitions and animations

### Error Handling
Comprehensive error handling with:
- Network error recovery
- User-friendly error messages
- Offline state management
- Retry mechanisms

## 📋 TODO / Roadmap

- [ ] Real-time notifications and WebSocket integration
- [ ] Task time tracking functionality
- [ ] Advanced filtering and sorting
- [ ] Offline mode support
- [ ] Push notifications
- [ ] Dark mode theme
- [ ] Task attachments and file management
- [ ] Advanced analytics charts
- [ ] Team collaboration features

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines for more details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Code Style
- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent formatting

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Original TaskFlow web application design and functionality
- Flutter team for the amazing framework
- Riverpod team for excellent state management
- Material Design for design principles

---

**Built with ❤️ using Flutter**