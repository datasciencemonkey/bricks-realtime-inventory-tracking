# Supply Chain Tracker - Flutter Cross-Platform App

A cross-platform Flutter application with FastAPI backend for real-time supply chain tracking and inventory monitoring.

## Project Structure

```
real-time-inventory-mobile/
├── backend/                    # FastAPI backend
│   ├── main.py                # API endpoints
│   ├── requirements.txt       # Python dependencies
│   └── .env.example          # Environment variables template
└── supply_chain_tracker/      # Flutter app
    ├── lib/
    │   ├── models/            # Data models
    │   ├── services/          # API service layer
    │   ├── screens/           # UI screens
    │   └── main.dart          # App entry point
    └── pubspec.yaml           # Flutter dependencies
```

## Features

- **Real-time Inventory Map**: Interactive map showing inventory locations with status-based color coding
- **Status Summary**: Dashboard with key metrics (In Transit, At DC, At Dock, Total Units)
- **Cross-Platform**: Runs on iOS, Android, Web, Windows, macOS, and Linux
- **RESTful API**: FastAPI backend with Databricks integration
- **Modern UI**: Built with Material Design 3 and DM Sans font

## Backend Setup

### Prerequisites
- Python 3.11+
- Databricks account with access credentials

### Installation

1. Navigate to backend directory:
```bash
cd backend
```

2. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Configure environment:
```bash
cp .env.example .env
# Edit .env with your Databricks credentials
```

5. Run the server:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

### API Endpoints

- `GET /api/inventory` - Get all inventory items (with optional filters)
- `GET /api/inventory/summary` - Get status summary statistics
- `GET /api/products` - Get list of unique products
- `GET /api/statuses` - Get list of unique statuses
- `GET /api/batch/{batch_id}` - Get batch tracking events
- `GET /api/batches` - Get list of all batches

## Flutter App Setup

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. Navigate to Flutter app directory:
```bash
cd supply_chain_tracker
```

2. Get dependencies:
```bash
flutter pub get
```

3. Update API URL:
Edit `lib/services/api_service.dart` and update `baseUrl` to your backend URL:
```dart
static const String baseUrl = 'http://YOUR_BACKEND_IP:8000';
```

### Running the App

**Desktop (macOS, Windows, Linux):**
```bash
flutter run -d macos    # macOS
flutter run -d windows  # Windows
flutter run -d linux    # Linux
```

**Mobile:**
```bash
flutter run -d ios      # iOS Simulator
flutter run -d android  # Android Emulator
```

**Web:**
```bash
flutter run -d chrome
```

**Build for Production:**
```bash
flutter build apk       # Android APK
flutter build ios       # iOS
flutter build web       # Web
flutter build macos     # macOS
flutter build windows   # Windows
flutter build linux     # Linux
```

## Configuration

### Backend Environment Variables

Create `.env` file in `backend/` directory:

```env
DATABRICKS_HOST=https://your-workspace.cloud.databricks.com
DATABRICKS_TOKEN=your_access_token
DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/your_warehouse_id
DATABRICKS_CATALOG=your_catalog
DATABRICKS_SCHEMA=your_schema
```

### Flutter Configuration

Update `lib/services/api_service.dart`:
- For local testing: `http://localhost:8000`
- For mobile device: `http://YOUR_LOCAL_IP:8000`
- For production: `https://your-api-domain.com`

## Status Color Coding

- **Red** (#e74c3c): In Transit
- **Green** (#2ecc71): At DC
- **Blue** (#3498db): At Dock
- **Dark Green** (#27ae60): Delivered
- **Orange** (#e67e22): In Transit from Supplier
- **Dark Red** (#c0392b): In Transit to Customer
- **Purple** (#9b59b6): In Transit to DC
- **Teal** (#1abc9c): At the Dock

## Tech Stack

### Backend
- **FastAPI**: Modern Python web framework
- **Databricks SQL Connector**: Data source integration
- **Pandas**: Data manipulation
- **Uvicorn**: ASGI server

### Frontend
- **Flutter**: Cross-platform UI framework
- **flutter_map**: Interactive map component
- **http**: API communication
- **google_fonts**: DM Sans typography
- **provider**: State management (optional)

## Development

### Backend Development
```bash
cd backend
uvicorn main:app --reload
```

### Flutter Hot Reload
When running the app, press `r` in terminal for hot reload, or `R` for hot restart.

## Troubleshooting

### CORS Issues
If you encounter CORS errors, ensure the FastAPI backend has proper CORS middleware configured (already included in `main.py`).

### Map Not Loading
- Check internet connection for map tiles
- Verify OpenStreetMap is accessible
- Ensure coordinates are valid

### API Connection Failed
- Verify backend is running
- Check firewall settings
- Update API URL in Flutter app
- For mobile testing, use local IP address instead of localhost

## License

Proprietary - Internal use only

## Support

For issues or questions, contact the development team.
