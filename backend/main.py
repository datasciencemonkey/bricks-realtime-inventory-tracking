from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List, Optional, Dict
import os
from pathlib import Path
from dotenv import load_dotenv
from databricks import sql
import pandas as pd
from datetime import datetime, timedelta
from functools import lru_cache

# Load environment variables
load_dotenv()

app = FastAPI(title="Supply Chain Tracking API")

# Get the path to Flutter web build
FLUTTER_BUILD_PATH = Path(__file__).parent.parent / "supply_chain_tracker" / "build" / "web"

# In-memory cache with TTL
class CacheItem:
    def __init__(self, data, ttl_seconds=300):
        self.data = data
        self.expires_at = datetime.now() + timedelta(seconds=ttl_seconds)

    def is_expired(self):
        return datetime.now() > self.expires_at

# Cache storage
_cache: Dict[str, CacheItem] = {}

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class InventoryItem(BaseModel):
    record_id: int
    reference_number: str
    product_id: str
    product_name: str
    status: str
    qty: int
    unit_price: float
    current_location: str
    latitude: float
    longitude: float
    destination: str
    time_remaining_to_destination_hours: Optional[float] = None
    last_updated_cst: str
    expected_arrival_time: Optional[str] = None
    batch_id: str

class BatchEvent(BaseModel):
    record_id: int
    batch_id: str
    product_id: str
    product_name: str
    event: str
    event_time_cst: str
    entity_involved: str
    entity_name: str
    entity_location: str
    entity_latitude: float
    entity_longitude: float
    event_time_cst_readable: str

class RouteResponse(BaseModel):
    coordinates: List[List[float]]

class StatusSummary(BaseModel):
    in_transit: int
    at_dc: int
    at_dock: int
    delivered: int
    total_units: int

# Cache helper functions
def get_from_cache(key: str):
    """Get data from cache if not expired"""
    if key in _cache:
        item = _cache[key]
        if not item.is_expired():
            return item.data
        else:
            del _cache[key]
    return None

def set_cache(key: str, data, ttl_seconds=300):
    """Set data in cache with TTL"""
    _cache[key] = CacheItem(data, ttl_seconds)

def clear_cache():
    """Clear all cache entries"""
    _cache.clear()

# Database connection helper
def get_databricks_data(query: str, cache_key: Optional[str] = None, ttl_seconds=300):
    """Fetch data from Databricks with optional caching"""
    # Check cache first
    if cache_key:
        cached_data = get_from_cache(cache_key)
        if cached_data is not None:
            return cached_data

    databricks_host = os.getenv("DATABRICKS_HOST")
    databricks_token = os.getenv("DATABRICKS_TOKEN")
    databricks_http_path = os.getenv("DATABRICKS_HTTP_PATH")

    if not all([databricks_host, databricks_token, databricks_http_path]):
        raise HTTPException(status_code=500, detail="Databricks credentials not configured")

    try:
        with sql.connect(
            server_hostname=databricks_host.replace("https://", ""),
            http_path=databricks_http_path,
            access_token=databricks_token
        ) as connection:
            with connection.cursor() as cursor:
                cursor.execute(query)
                df = cursor.fetchall_arrow().to_pandas()

                # Cache the result if cache_key provided
                if cache_key:
                    set_cache(cache_key, df, ttl_seconds)

                return df
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

def get_status_category(status: str) -> str:
    """Map detailed status to broad category"""
    status_lower = status.lower()
    if 'in transit' in status_lower or 'transit' in status_lower:
        return 'In Transit'
    elif 'at dc' in status_lower or 'dc' in status_lower:
        return 'At DC'
    elif 'dock' in status_lower:
        return 'At Dock'
    elif 'delivered' in status_lower:
        return 'Delivered'
    else:
        return status

# Routes
@app.get("/api/inventory")
def get_inventory(
    product: Optional[str] = None,
    status: Optional[str] = None
):
    """Get inventory data with optional filters"""
    catalog = os.getenv("DATABRICKS_CATALOG", "")
    schema = os.getenv("DATABRICKS_SCHEMA", "")

    table_name = "inventory_realtime_v1"
    if catalog and schema:
        table_name = f"{catalog}.{schema}.{table_name}"

    query = f"SELECT * FROM {table_name}"
    df = get_databricks_data(query)

    # Add status category for filtering
    df['status_category'] = df['status'].apply(get_status_category)

    # Apply filters
    if product:
        df = df[df['product_name'] == product]
    if status:
        df = df[df['status_category'] == status]

    # Replace NaN values with None for JSON serialization
    df = df.fillna('')
    # Convert to JSON-safe records
    records = df.to_dict('records')

    # Replace empty strings back to None for optional fields
    for record in records:
        if record.get('expected_arrival_time') == '':
            record['expected_arrival_time'] = None
        if record.get('time_remaining_to_destination_hours') == '':
            record['time_remaining_to_destination_hours'] = None

    return records

@app.get("/api/inventory/summary", response_model=StatusSummary)
def get_inventory_summary():
    """Get inventory status summary"""
    catalog = os.getenv("DATABRICKS_CATALOG", "")
    schema = os.getenv("DATABRICKS_SCHEMA", "")

    table_name = "inventory_realtime_v1"
    if catalog and schema:
        table_name = f"{catalog}.{schema}.{table_name}"

    query = f"SELECT * FROM {table_name}"
    df = get_databricks_data(query)

    # Add status category
    df['status_category'] = df['status'].apply(get_status_category)

    return {
        "in_transit": len(df[df['status_category'] == 'In Transit']),
        "at_dc": len(df[df['status_category'] == 'At DC']),
        "at_dock": len(df[df['status_category'] == 'At Dock']),
        "delivered": len(df[df['status_category'] == 'Delivered']),
        "total_units": int(df['qty'].sum())
    }

@app.get("/api/products")
def get_products():
    """Get list of unique products (cached for 5 minutes)"""
    catalog = os.getenv("DATABRICKS_CATALOG", "")
    schema = os.getenv("DATABRICKS_SCHEMA", "")

    table_name = "inventory_realtime_v1"
    if catalog and schema:
        table_name = f"{catalog}.{schema}.{table_name}"

    query = f"SELECT DISTINCT product_name FROM {table_name}"
    df = get_databricks_data(query, cache_key="products_list", ttl_seconds=300)

    products = sorted(df['product_name'].tolist())
    return {"products": products}

@app.get("/api/statuses")
def get_statuses():
    """Get list of status categories"""
    # Return predefined status categories instead of querying database
    return {
        "statuses": ["In Transit", "At DC", "At Dock", "Delivered"]
    }

@app.get("/api/batch/{batch_id}")
def get_batch_events(batch_id: str):
    """Get batch tracking events for a specific batch (cached)"""
    catalog = os.getenv("DATABRICKS_CATALOG", "")
    schema = os.getenv("DATABRICKS_SCHEMA", "")

    table_name = "batch_events_v1"
    if catalog and schema:
        table_name = f"{catalog}.{schema}.{table_name}"

    query = f"SELECT * FROM {table_name} WHERE batch_id = '{batch_id}' ORDER BY event_time_cst"

    # Use cache with batch_id as key, 5-minute TTL
    df = get_databricks_data(query, cache_key=f"batch_{batch_id}", ttl_seconds=300)

    if df.empty:
        raise HTTPException(status_code=404, detail="Batch not found")

    # Replace NaN values
    df = df.fillna('')

    return df.to_dict('records')

@app.get("/api/batches")
def get_batches():
    """Get list of unique batch IDs with product names (cached)"""
    catalog = os.getenv("DATABRICKS_CATALOG", "")
    schema = os.getenv("DATABRICKS_SCHEMA", "")

    table_name = "batch_events_v1"
    if catalog and schema:
        table_name = f"{catalog}.{schema}.{table_name}"

    query = f"SELECT DISTINCT batch_id, product_name FROM {table_name}"

    # Use cache with 5-minute TTL
    df = get_databricks_data(query, cache_key="batches_list", ttl_seconds=300)

    return {"batches": df.to_dict('records')}

@app.get("/api/route")
def get_route(lat1: float, lon1: float, lat2: float, lon2: float):
    """Get OSRM driving route between two points (cached)"""
    import requests as req

    # Create cache key for this specific route
    cache_key = f"route_{lat1}_{lon1}_{lat2}_{lon2}"
    cached_route = get_from_cache(cache_key)
    if cached_route is not None:
        return cached_route

    try:
        url = f"http://router.project-osrm.org/route/v1/driving/{lon1},{lat1};{lon2},{lat2}?overview=full&geometries=geojson"
        response = req.get(url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            if data['code'] == 'Ok' and 'routes' in data:
                # Return coordinates as [lat, lon] pairs
                coords = data['routes'][0]['geometry']['coordinates']
                result = {"coordinates": [[c[1], c[0]] for c in coords]}  # Convert [lon, lat] to [lat, lon]

                # Cache route for 10 minutes (routes don't change)
                set_cache(cache_key, result, ttl_seconds=600)

                return result
    except:
        pass

    # Fallback to straight line
    fallback = {"coordinates": [[lat1, lon1], [lat2, lon2]]}
    set_cache(cache_key, fallback, ttl_seconds=600)
    return fallback

@app.post("/api/cache/clear")
def clear_cache_endpoint():
    """Clear all cache entries"""
    clear_cache()
    return {"message": "Cache cleared successfully"}

# Mount static files and serve Flutter web app
if FLUTTER_BUILD_PATH.exists():
    # Mount static assets
    app.mount("/assets", StaticFiles(directory=str(FLUTTER_BUILD_PATH / "assets")), name="assets")
    app.mount("/canvaskit", StaticFiles(directory=str(FLUTTER_BUILD_PATH / "canvaskit")), name="canvaskit")
    app.mount("/icons", StaticFiles(directory=str(FLUTTER_BUILD_PATH / "icons")), name="icons")

    # Serve Flutter files at root
    @app.get("/favicon.png")
    async def favicon():
        return FileResponse(FLUTTER_BUILD_PATH / "favicon.png")

    @app.get("/flutter.js")
    async def flutter_js():
        return FileResponse(FLUTTER_BUILD_PATH / "flutter.js")

    @app.get("/flutter_bootstrap.js")
    async def flutter_bootstrap():
        return FileResponse(FLUTTER_BUILD_PATH / "flutter_bootstrap.js")

    @app.get("/main.dart.js")
    async def main_dart_js():
        return FileResponse(FLUTTER_BUILD_PATH / "main.dart.js")

    @app.get("/manifest.json")
    async def manifest():
        return FileResponse(FLUTTER_BUILD_PATH / "manifest.json")

    @app.get("/version.json")
    async def version():
        return FileResponse(FLUTTER_BUILD_PATH / "version.json")

    @app.get("/flutter_service_worker.js")
    async def service_worker():
        return FileResponse(FLUTTER_BUILD_PATH / "flutter_service_worker.js")

    # Serve index.html for root and any other path (SPA routing)
    @app.get("/")
    async def serve_app():
        return FileResponse(FLUTTER_BUILD_PATH / "index.html")

    @app.get("/{full_path:path}")
    async def serve_spa(full_path: str):
        # If the path doesn't start with /api, serve the Flutter app
        if not full_path.startswith("api/"):
            return FileResponse(FLUTTER_BUILD_PATH / "index.html")
        # Otherwise let FastAPI handle 404
        raise HTTPException(status_code=404, detail="Not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
