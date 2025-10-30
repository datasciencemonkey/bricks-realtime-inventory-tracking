# Real-Time Supply Chain Tracker

A real-time supply chain visibility application that provides interactive mapping and batch tracking for inventory monitoring across your distribution network. Built with Databricks as the data backbone and designed for deployment as a Databricks App.

## What This Application Does

This application provides **real-time visibility** into your supply chain operations with two primary capabilities:

### 1. Live Inventory Dashboard
- **Interactive map visualization** showing all inventory items with their current locations
- **Color-coded status indicators** for quick identification of inventory state (In Transit, At DC, At Dock, etc.)
- **Summary metrics** displaying total units and counts by status
- **Drill-down capability** to view detailed information for each inventory item
- **Filtering options** by product type and status

### 2. Batch Tracking Timeline
- **End-to-end tracking** of individual batches through the supply chain
- **Event timeline** showing the complete journey from origin to destination
- **Location history** with timestamps for every checkpoint
- **Status updates** with notes for each stage of the journey
- **Map visualization** of batch movement across geographic locations

## Business Use Cases

- **Supply chain managers** monitoring inventory flow across multiple distribution centers
- **Logistics teams** tracking shipments in real-time
- **Operations teams** identifying bottlenecks and delays
- **Customer service** providing accurate delivery status updates
- **Analytics teams** analyzing supply chain performance metrics

## Architecture

```
real-time-inventory-mobile/
├── backend/                    # FastAPI Python backend
│   ├── main.py                # REST API endpoints
│   ├── requirements.txt       # Python dependencies
│   └── .env.example           # Configuration template
├── supply_chain_tracker/      # Web frontend application
│   ├── lib/
│   │   ├── models/            # Data models
│   │   ├── services/          # API integration
│   │   ├── screens/           # User interface screens
│   │   └── providers/         # State management
│   └── build/web/             # Production web assets
└── deployment.sh              # Deployment automation script
```

**Technology Stack:**
- **Backend**: FastAPI (Python) with Databricks SQL Connector
- **Frontend**: Cross-platform web application
- **Data Source**: Databricks Unity Catalog (SQL Warehouse)
- **Deployment**: Databricks Apps
- **Maps**: OpenStreetMap integration

## Key Features

### Real-Time Data Integration
- Direct connection to Databricks SQL Warehouse
- Live queries against Unity Catalog tables
- Sub-second data refresh for inventory status
- RESTful API design for scalability

### Visual Analytics
- Geographic map view with inventory markers
- Status-based color coding (8 distinct states)
- Interactive tooltips with detailed information
- Responsive design for desktop and mobile

### Batch Tracking
- Complete shipment history and audit trail
- Multi-step journey visualization
- Location-based tracking with coordinates
- Notes and status updates at each checkpoint

### Cross-Platform Access
- Web-based interface accessible from any device
- No installation required
- Responsive design adapts to screen size
- Works on desktop, tablet, and mobile browsers

## Getting Started

### Prerequisites

This application requires access to a Databricks workspace and basic knowledge of Python for backend setup. The frontend is built with web technologies and requires no specialized development environment beyond standard development tools (Python, Node.js/npm for building web assets).

## Application Screens and Functionality

### Dashboard View
The main dashboard provides an at-a-glance view of your entire supply chain:
- **Summary cards** at the top show total units and counts by status
- **Interactive map** displays all inventory locations as colored markers
- **Filter panel** allows you to narrow down by product or status
- **Real-time updates** as data changes in Databricks

### Inventory Screen
The inventory screen shows detailed geographic distribution:
- **Map markers** represent individual inventory items or aggregated locations
- **Color coding** indicates status (red for in-transit, green for at DC, blue for at dock, etc.)
- **Click on markers** to see detailed information including product, quantity, and last update
- **Pan and zoom** to explore different geographic regions

### Batch Tracking Screen
The batch tracking screen provides shipment-level detail:
- **Batch selector** to choose which shipment to track
- **Timeline view** showing chronological events from pickup to delivery
- **Event cards** display location, status, timestamp, and notes for each checkpoint
- **Map visualization** showing the path of the batch across locations

### Status Color Coding

The application uses color-coded markers to indicate inventory status at a glance:

- **Red** (#e74c3c): In Transit
- **Orange** (#e67e22): In Transit from Supplier
- **Dark Red** (#c0392b): In Transit to Customer
- **Purple** (#9b59b6): In Transit to DC
- **Green** (#2ecc71): At DC (Distribution Center)
- **Blue** (#3498db): At Dock
- **Teal** (#1abc9c): At the Dock
- **Dark Green** (#27ae60): Delivered

These colors help operations teams quickly identify where inventory is in the supply chain and spot potential issues (e.g., too many items stuck in transit).

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User's Browser                           │
│                    (Web Interface - Any Device)                  │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      Databricks Apps                             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Frontend (Web Application)                   │   │
│  │  • Interactive map visualization                          │   │
│  │  • Dashboard with status cards                            │   │
│  │  • Batch tracking timeline                                │   │
│  │  • Built with Flutter web                                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                             │                                    │
│                             │ REST API (/api/*)                  │
│                             │                                    │
│  ┌──────────────────────────▼──────────────────────────────┐   │
│  │              Backend (FastAPI)                            │   │
│  │  • GET /api/inventory (list all inventory)               │   │
│  │  • GET /api/inventory/summary (status counts)            │   │
│  │  • GET /api/batch/{id} (batch tracking events)           │   │
│  │  • GET /api/batches (list all batches)                   │   │
│  │  • Python REST API with CORS enabled                      │   │
│  └──────────────────────────┬──────────────────────────────┘   │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │ SQL Connector
                               │
┌──────────────────────────────▼───────────────────────────────────┐
│                    Databricks Workspace                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                Unity Catalog                               │  │
│  │  Catalog: supplychain                                      │  │
│  │  Schema: supplychain_visibility                            │  │
│  │                                                             │  │
│  │  Tables:                                                    │  │
│  │  ┌──────────────────────┐  ┌────────────────────────────┐ │  │
│  │  │   inventory          │  │   batch_tracking           │ │  │
│  │  │ • product_name       │  │ • batch_id                 │ │  │
│  │  │ • status             │  │ • timestamp                │ │  │
│  │  │ • latitude/longitude │  │ • location                 │ │  │
│  │  │ • quantity           │  │ • status                   │ │  │
│  │  │ • location           │  │ • latitude/longitude       │ │  │
│  │  │ • last_updated       │  │ • notes                    │ │  │
│  │  └──────────────────────┘  └────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              ▲                                   │
│  ┌───────────────────────────┴───────────────────────────────┐  │
│  │            SQL Warehouse (Compute)                         │  │
│  │  • Executes queries from backend                           │  │
│  │  • Serverless or provisioned compute                       │  │
│  └────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘

External Services:
┌────────────────────────┐
│   OpenStreetMap        │  → Map tiles for visualization
└────────────────────────┘
┌────────────────────────┐
│   OSRM                 │  → Route calculation for batch tracking
└────────────────────────┘
```

**Data Flow:**
1. User opens the application in their browser
2. Frontend loads and makes API calls to backend
3. Backend queries Databricks SQL Warehouse via SQL Connector
4. SQL Warehouse retrieves data from Unity Catalog tables
5. Data is returned through the stack back to the browser
6. Frontend renders map markers and visualizations
7. Map tiles are loaded from OpenStreetMap for geographic context
8. For batch tracking, routes between checkpoints are calculated using OSRM (via backend proxy with caching)

**Security:**
- Databricks authentication for all API calls
- Environment variables for sensitive credentials
- CORS enabled for web access
- All data stays within Databricks workspace

## Tech Stack

### Backend
- **FastAPI**: Modern Python web framework for building REST APIs
- **Databricks SQL Connector**: Direct connection to Databricks SQL Warehouse
- **Pandas**: Data manipulation and transformation
- **Uvicorn**: ASGI server for running FastAPI
- **Python-dotenv**: Environment variable management

### Frontend
- **Web application**: Cross-platform interface accessible from any browser
- **Interactive maps**: OpenStreetMap integration with custom markers
- **Route visualization**: OSRM (Open Source Routing Machine) for calculating driving routes between batch checkpoints
- **RESTful API client**: HTTP-based communication with backend
- **Responsive design**: Works on desktop, tablet, and mobile devices

### Infrastructure
- **Databricks Apps**: Serverless deployment platform integrated with Databricks
- **Databricks Unity Catalog**: Data warehouse with governance and access control
- **SQL Warehouse**: Compute engine for executing queries
- **OpenStreetMap**: Map tile provider for geographic visualization
- **OSRM**: Routing engine for calculating realistic road-based routes in batch tracking

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
