"""
System prompts for AI chat endpoints.
Each function builds a context-aware system prompt with relevant data.
"""

from pathlib import Path
from typing import List, Dict, Any
import yaml


def build_executive_dashboard_system_prompt() -> str:
    """Build a system prompt with executive dashboard data from metrics.yaml"""
    metrics_path = Path(__file__).parent / "metrics.yaml"

    try:
        with open(metrics_path, 'r') as f:
            metrics = yaml.safe_load(f)

        dashboard = metrics.get('executive_dashboard', {})

        prompt_parts = [
            "You are a helpful Supply Chain Executive Assistant with access to real-time dashboard data.",
            "Answer questions based on the following executive dashboard metrics.",
            "Be specific, cite numbers, and provide actionable insights when appropriate.",
            "Only respond with data you have access to. Do not make up data.",
            "",
            "=== EXECUTIVE DASHBOARD DATA ===",
        ]

        # KPI Cards
        if 'kpi_cards' in dashboard:
            prompt_parts.append("\n## Key Performance Indicators:")
            for kpi in dashboard['kpi_cards']:
                label = kpi.get('label', 'Unknown')
                value = kpi.get('value', 'N/A')
                unit = kpi.get('unit', '')
                prefix = kpi.get('prefix', '')
                change = kpi.get('change', 0)
                change_unit = kpi.get('change_unit', '%')
                change_str = f"+{change}" if change > 0 else str(change)
                prompt_parts.append(f"- {label}: {prefix}{value}{unit} (Change: {change_str}{change_unit})")

        # Supplier Risk
        if 'supplier_risk' in dashboard:
            risk = dashboard['supplier_risk']
            prompt_parts.append(f"\n## Supplier Risk Score: {risk.get('value', 'N/A')}")

        # Demand Forecasting
        if 'demand_forecasting' in dashboard:
            df = dashboard['demand_forecasting']
            prompt_parts.append(f"\n## Demand Forecasting:")
            prompt_parts.append(f"- Accuracy: {df.get('accuracy_value', 'N/A')}{df.get('unit', '%')}")
            prompt_parts.append(f"- Period: {df.get('period', 'N/A')}")
            if 'chart_data' in df:
                prompt_parts.append("- Monthly Trend:")
                for item in df['chart_data']:
                    prompt_parts.append(f"  - {item.get('month', '?')}: {item.get('value', '?')}")

        # Inventory Levels
        if 'inventory_levels' in dashboard:
            inv = dashboard['inventory_levels']
            prompt_parts.append(f"\n## Inventory Levels:")
            prompt_parts.append(f"- Total Value: {inv.get('prefix', '$')}{inv.get('total_value', 'N/A')}{inv.get('unit', 'M')}")
            if 'locations' in inv:
                prompt_parts.append("- By Location:")
                for loc in inv['locations']:
                    prompt_parts.append(f"  - {loc.get('name', '?')}: ${loc.get('value', '?')}M")

        # Supplier Performance
        if 'supplier_performance' in dashboard:
            sp = dashboard['supplier_performance']
            prompt_parts.append(f"\n## Supplier Performance:")
            if 'suppliers' in sp:
                for supplier in sp['suppliers']:
                    prompt_parts.append(f"- {supplier.get('name', '?')}:")
                    prompt_parts.append(f"  - On-Time Delivery: {supplier.get('on_time_delivery', '?')}%")
                    prompt_parts.append(f"  - Quality Score: {supplier.get('quality_score', '?')}%")
                    prompt_parts.append(f"  - Lead Time: {supplier.get('lead_time', '?')}")
                    prompt_parts.append(f"  - Risk Score: {supplier.get('risk_score', '?')}")

        # Predictive Risk Analysis
        if 'predictive_risk_analysis' in dashboard:
            pra = dashboard['predictive_risk_analysis']
            prompt_parts.append(f"\n## Predictive Risk Analysis:")
            prompt_parts.append(f"- Disruption Level: {pra.get('disruption_level', 'N/A')}")
            prompt_parts.append(f"- Forecast Period: {pra.get('period', 'N/A')}")
            if 'contributing_factors' in pra:
                prompt_parts.append("- Contributing Factors:")
                for factor in pra['contributing_factors']:
                    prompt_parts.append(f"  - {factor.get('name', '?')}: {factor.get('value', '?')}%")
            if 'disruption_types' in pra:
                prompt_parts.append("- Potential Disruptions:")
                for dt in pra['disruption_types']:
                    prompt_parts.append(f"  - {dt.get('type', '?')}: {dt.get('probability', '?')}% probability")

        # Logistics & Transportation
        if 'logistics_transportation' in dashboard:
            lt = dashboard['logistics_transportation']
            prompt_parts.append(f"\n## Logistics & Transportation:")
            if 'expedited_delayed' in lt:
                ed = lt['expedited_delayed']
                prompt_parts.append(f"- Shipments Expedited/Delayed: {ed.get('value', '?')}{ed.get('unit', '%')}")
                if 'chart_data' in ed:
                    prompt_parts.append("  - Monthly Trend:")
                    for item in ed['chart_data']:
                        prompt_parts.append(f"    - {item.get('month', '?')}: {item.get('value', '?')}%")
            if 'otif_over_time' in lt:
                otif = lt['otif_over_time']
                prompt_parts.append(f"- OTIF (On-Time in Full) Average: {otif.get('value', '?')}{otif.get('unit', '%')}")
                if 'chart_data' in otif:
                    prompt_parts.append("  - Monthly Trend:")
                    for item in otif['chart_data']:
                        prompt_parts.append(f"    - {item.get('month', '?')}: {item.get('value', '?')}%")

        prompt_parts.append("\n=== END DASHBOARD DATA ===")
        prompt_parts.append("")
        prompt_parts.append("When answering questions:")
        prompt_parts.append("- Reference specific metrics and numbers from the data above")
        prompt_parts.append("- Identify trends when discussing time-series data")
        prompt_parts.append("- Highlight risks and areas of concern")
        prompt_parts.append("- Provide actionable recommendations when appropriate")

        return "\n".join(prompt_parts)

    except Exception as e:
        return f"You are a Supply Chain Assistant. Note: Dashboard data could not be loaded ({str(e)}). Please answer general supply chain questions."


def build_realtime_snapshot_system_prompt(inventory_data: List[Dict[str, Any]]) -> str:
    """
    Build a system prompt with real-time inventory snapshot data.

    Args:
        inventory_data: List of inventory records from the database

    Returns:
        System prompt string with inventory context
    """
    if not inventory_data:
        return (
            "You are a Supply Chain Inventory Assistant. "
            "Note: No inventory data is currently available. "
            "Please answer general inventory and supply chain questions."
        )

    prompt_parts = [
        "You are a helpful Supply Chain Inventory Assistant with access to real-time inventory data.",
        "Answer questions based on the following inventory snapshot.",
        "Be specific, cite numbers, locations, and product details when appropriate.",
        "For example, when asked about delays of any shipment, ask about if the user wants to have you look up the reason why something is delayed or disrupted.",
        "IF the user says yes or explicitly asks for the reason why something is delayed or disrupted, then you should use information in your context to make an extremely plausible reason.",
        "you are being used as a part of a demo. Don't reveal that you are a demo.",
        "Indicate that the user can consult the planning agent incase any mitigation or if any action is needed and say this is intentional since you are meant to only provide information but not act like a planner.",
        "",
        "=== REAL-TIME INVENTORY SNAPSHOT ===",
    ]

    # Calculate summary statistics
    total_records = len(inventory_data)
    total_units = sum(item.get('qty', 0) for item in inventory_data)
    total_value = sum(item.get('qty', 0) * item.get('unit_price', 0) for item in inventory_data)

    # Count by status category
    status_counts = {}
    for item in inventory_data:
        status = item.get('status_category', item.get('status', 'Unknown'))
        status_counts[status] = status_counts.get(status, 0) + 1

    # Count delayed shipments
    delayed_count = sum(
        1 for item in inventory_data
        if 'delay' in str(item.get('transit_status', '')).lower()
    )

    # Get unique products
    products = set(item.get('product_name', '') for item in inventory_data if item.get('product_name'))

    # Get unique locations
    locations = set(item.get('current_location', '') for item in inventory_data if item.get('current_location'))

    # Get unique destinations
    destinations = set(item.get('destination', '') for item in inventory_data if item.get('destination'))

    # Summary section
    prompt_parts.append("\n## Summary Statistics:")
    prompt_parts.append(f"- Total Shipments: {total_records}")
    prompt_parts.append(f"- Total Units: {total_units:,}")
    prompt_parts.append(f"- Total Value: ${total_value:,.2f}")
    prompt_parts.append(f"- Delayed Shipments: {delayed_count}")
    prompt_parts.append(f"- Unique Products: {len(products)}")
    prompt_parts.append(f"- Unique Locations: {len(locations)}")

    # Status breakdown
    prompt_parts.append("\n## Status Breakdown:")
    for status, count in sorted(status_counts.items(), key=lambda x: -x[1]):
        prompt_parts.append(f"- {status}: {count} shipments")

    # Product inventory summary
    prompt_parts.append("\n## Inventory by Product:")
    product_summary = {}
    for item in inventory_data:
        product = item.get('product_name', 'Unknown')
        if product not in product_summary:
            product_summary[product] = {'qty': 0, 'value': 0, 'count': 0}
        product_summary[product]['qty'] += item.get('qty', 0)
        product_summary[product]['value'] += item.get('qty', 0) * item.get('unit_price', 0)
        product_summary[product]['count'] += 1

    for product, data in sorted(product_summary.items(), key=lambda x: -x[1]['qty']):
        prompt_parts.append(
            f"- {product}: {data['qty']:,} units, ${data['value']:,.2f} value, {data['count']} shipments"
        )

    # Location summary
    prompt_parts.append("\n## Inventory by Current Location:")
    location_summary = {}
    for item in inventory_data:
        location = item.get('current_location', 'Unknown')
        if location not in location_summary:
            location_summary[location] = {'qty': 0, 'count': 0}
        location_summary[location]['qty'] += item.get('qty', 0)
        location_summary[location]['count'] += 1

    for location, data in sorted(location_summary.items(), key=lambda x: -x[1]['qty'])[:15]:
        prompt_parts.append(f"- {location}: {data['qty']:,} units, {data['count']} shipments")

    if len(location_summary) > 15:
        prompt_parts.append(f"  ... and {len(location_summary) - 15} more locations")

    # Delayed shipments detail (if any)
    if delayed_count > 0:
        prompt_parts.append("\n## Delayed Shipments:")
        delayed_items = [
            item for item in inventory_data
            if 'delay' in str(item.get('transit_status', '')).lower()
        ]
        for item in delayed_items[:10]:  # Limit to first 10
            prompt_parts.append(
                f"- {item.get('product_name', 'Unknown')} (Ref: {item.get('reference_number', 'N/A')}): "
                f"{item.get('qty', 0)} units at {item.get('current_location', 'Unknown')} "
                f"→ {item.get('destination', 'Unknown')}"
            )
        if len(delayed_items) > 10:
            prompt_parts.append(f"  ... and {len(delayed_items) - 10} more delayed shipments")

    # Sample of detailed records (for specific queries)
    prompt_parts.append("\n## Sample Shipment Details (first 20 records):")
    for item in inventory_data[:20]:
        eta_info = ""
        if item.get('expected_arrival_time'):
            eta_info = f", ETA: {item.get('expected_arrival_time')}"
        if item.get('time_remaining_to_destination_hours'):
            hours = item.get('time_remaining_to_destination_hours')
            eta_info += f" ({hours:.1f}h remaining)"

        transit_status = item.get('transit_status', 'On Time')
        delay_marker = " [DELAYED]" if 'delay' in transit_status.lower() else ""

        prompt_parts.append(
            f"- Ref {item.get('reference_number', 'N/A')}: {item.get('product_name', 'Unknown')} | "
            f"{item.get('qty', 0)} units @ ${item.get('unit_price', 0):.2f} | "
            f"{item.get('current_location', '?')} → {item.get('destination', '?')} | "
            f"Status: {item.get('status', '?')}{delay_marker}{eta_info}"
        )

    if len(inventory_data) > 20:
        prompt_parts.append(f"\n... and {len(inventory_data) - 20} more shipments in the system")

    prompt_parts.append("\n=== END INVENTORY DATA ===")
    prompt_parts.append("")
    prompt_parts.append("When answering questions:")
    prompt_parts.append("- Reference specific shipments by reference number when relevant")
    prompt_parts.append("- Provide counts and totals from the summary data")
    prompt_parts.append("- Highlight delayed shipments and potential issues")
    prompt_parts.append("- Suggest actions for inventory optimization when appropriate")
    prompt_parts.append("- If asked about a specific product or location, use the detailed data above")

    return "\n".join(prompt_parts)


def build_shipment_tracking_system_prompt(
    batches_data: List[Dict[str, Any]],
    selected_batch_id: str = None,
    batch_events: List[Dict[str, Any]] = None
) -> str:
    """
    Build a system prompt with shipment tracking data for batch-level tracking.

    Args:
        batches_data: List of all batches with batch_id, product_name, transit_status
        selected_batch_id: Optional - the currently selected batch for detailed context
        batch_events: Optional - event timeline for the selected batch

    Returns:
        System prompt string with shipment tracking context
    """
    if not batches_data:
        return (
            "You are a Supply Chain Shipment Tracking Assistant. "
            "Note: No shipment data is currently available. "
            "Please answer general shipment tracking and logistics questions."
        )

    prompt_parts = [
        "You are a helpful Supply Chain Shipment Tracking Assistant with access to real-time batch tracking data.",
        "Answer questions based on the following shipment tracking information.",
        "Be specific about batch IDs, products, locations, and timelines when appropriate.",
        "When asked about delays, provide plausible reasons based on the journey data (e.g., port congestion, customs clearance, weather).",
        "You are being used as part of a demo. Don't reveal that you are a demo.",
        "If the user needs mitigation actions or planning, direct them to the Planning tab.",
        "",
        "=== SHIPMENT TRACKING DATA ===",
    ]

    # Calculate summary statistics
    total_batches = len(batches_data)
    delayed_batches = [b for b in batches_data if 'delay' in str(b.get('transit_status', '')).lower()]
    on_time_batches = total_batches - len(delayed_batches)

    # Group by product
    products_summary = {}
    for batch in batches_data:
        product = batch.get('product_name', 'Unknown')
        if product not in products_summary:
            products_summary[product] = {'total': 0, 'delayed': 0}
        products_summary[product]['total'] += 1
        if 'delay' in str(batch.get('transit_status', '')).lower():
            products_summary[product]['delayed'] += 1

    # Summary section
    prompt_parts.append("\n## Summary Statistics:")
    prompt_parts.append(f"- Total Batches Being Tracked: {total_batches}")
    prompt_parts.append(f"- On-Time Batches: {on_time_batches} ({100 * on_time_batches / total_batches:.1f}%)" if total_batches > 0 else "- On-Time Batches: 0")
    prompt_parts.append(f"- Delayed Batches: {len(delayed_batches)} ({100 * len(delayed_batches) / total_batches:.1f}%)" if total_batches > 0 else "- Delayed Batches: 0")
    prompt_parts.append(f"- Unique Products: {len(products_summary)}")

    # Products breakdown
    prompt_parts.append("\n## Batches by Product:")
    for product, data in sorted(products_summary.items(), key=lambda x: -x[1]['total']):
        delay_info = f" ({data['delayed']} delayed)" if data['delayed'] > 0 else ""
        prompt_parts.append(f"- {product}: {data['total']} batches{delay_info}")

    # Delayed batches detail
    if delayed_batches:
        prompt_parts.append("\n## Delayed Batches (ATTENTION REQUIRED):")
        for batch in delayed_batches:
            prompt_parts.append(
                f"- Batch {batch.get('batch_id', 'Unknown')}: {batch.get('product_name', 'Unknown')} "
                f"[{batch.get('transit_status', 'Delayed')}]"
            )

    # All batches list
    prompt_parts.append("\n## All Batches:")
    for batch in batches_data[:50]:  # Limit to first 50
        status_marker = " [DELAYED]" if 'delay' in str(batch.get('transit_status', '')).lower() else ""
        prompt_parts.append(
            f"- {batch.get('batch_id', 'Unknown')}: {batch.get('product_name', 'Unknown')}{status_marker}"
        )
    if len(batches_data) > 50:
        prompt_parts.append(f"  ... and {len(batches_data) - 50} more batches")

    # Selected batch details (if provided)
    if selected_batch_id and batch_events:
        prompt_parts.append(f"\n## SELECTED BATCH DETAILS: {selected_batch_id}")

        # Find batch info
        selected_batch = next((b for b in batches_data if b.get('batch_id') == selected_batch_id), None)
        if selected_batch:
            prompt_parts.append(f"- Product: {selected_batch.get('product_name', 'Unknown')}")
            prompt_parts.append(f"- Transit Status: {selected_batch.get('transit_status', 'On Time')}")

        prompt_parts.append("\n### Event Timeline (chronological):")
        for event in batch_events:
            prompt_parts.append(
                f"  {event.get('event_time_cst_readable', 'Unknown time')}: "
                f"{event.get('event', 'Unknown event')} at {event.get('entity_name', 'Unknown')} "
                f"({event.get('entity_involved', '')})"
            )
            prompt_parts.append(f"    Location: {event.get('entity_location', 'Unknown')}")

        # Journey summary
        if batch_events:
            first_event = batch_events[0]
            last_event = batch_events[-1]
            prompt_parts.append("\n### Journey Summary:")
            prompt_parts.append(f"- Origin: {first_event.get('entity_name', 'Unknown')} ({first_event.get('entity_location', '')})")
            prompt_parts.append(f"- Current/Last Location: {last_event.get('entity_name', 'Unknown')} ({last_event.get('entity_location', '')})")
            prompt_parts.append(f"- Total Events: {len(batch_events)}")

            # Entity types encountered
            entities = set(e.get('entity_involved', '') for e in batch_events if e.get('entity_involved'))
            prompt_parts.append(f"- Entities Involved: {', '.join(sorted(entities))}")

    prompt_parts.append("\n=== END SHIPMENT TRACKING DATA ===")
    prompt_parts.append("")
    prompt_parts.append("When answering questions:")
    prompt_parts.append("- Reference specific batch IDs when discussing shipments")
    prompt_parts.append("- Highlight delayed batches and provide context on potential causes")
    prompt_parts.append("- Use the event timeline to explain shipment journey and identify bottlenecks")
    prompt_parts.append("- If a batch is delayed, suggest checking with the relevant entity (supplier, dock, DC)")
    prompt_parts.append("- For mitigation or planning actions, direct users to the Planning tab")

    return "\n".join(prompt_parts)
