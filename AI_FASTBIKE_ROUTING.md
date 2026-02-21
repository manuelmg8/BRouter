# AI Agent Guide: Fastbike Routing via BRouter API

## Purpose
Use this API to generate bicycle routes with the `fastbike` profile.

Base URL:
- `https://brouter.onrender.com`

Route endpoint:
- `GET /brouter`

## Required Query Parameters
- `lonlats`: Pipe-separated waypoints in `lon,lat` format.
- `profile`: Set to `fastbike`.

## Recommended Query Parameters
- `alternativeidx`: `0` (primary route)
- `format`: `geojson` (best for machine parsing) or `gpx`

## Canonical Request Format
`/brouter?lonlats=<lon1,lat1|lon2,lat2|...>&profile=fastbike&alternativeidx=0&format=geojson`

Example:
`https://brouter.onrender.com/brouter?lonlats=-6.2603,53.3498|-6.2595,53.3494&profile=fastbike&alternativeidx=0&format=geojson`

## Geographic Coverage Constraint
This deployment currently preloads only Ireland tiles in `start.sh`:
- `W15_N50.rd5`
- `W10_N50.rd5`
- `W10_N55.rd5`

If waypoints are outside loaded tiles, routing may fail or timeout.

## Response Behavior
- `200 OK` with route payload when successful.
- Root path `/` returns `404` by design; do not use `/` for routing or health checks.
- `400` may occur for invalid parameters, impossible routes, or watchdog timeout.

## Output Formats
### `format=geojson`
Returns `FeatureCollection` with route geometry and metadata in `features[0].properties`.

### `format=gpx`
Returns GPX XML track suitable for GPS tools.

## Agent Implementation Rules
1. Always send at least 2 waypoints in `lonlats`.
2. Use decimal degrees and keep longitude first.
3. URL-encode the full query string.
4. Default to `format=geojson` for downstream AI processing.
5. Set `alternativeidx=0` unless a different alternative is explicitly requested.
6. If response is non-200, retry once with simplified route (fewer via points), then return actionable error.
7. Treat `/` as non-health endpoint; use a lightweight `/brouter` test query for health checks.

## Minimal Health Check URL
Use a short known-valid fastbike query:

`https://brouter.onrender.com/brouter?lonlats=-6.2603,53.3498|-6.2595,53.3494&profile=fastbike&alternativeidx=0&format=geojson`

## cURL Example
```bash
curl -G 'https://brouter.onrender.com/brouter' \
  --data-urlencode 'lonlats=-6.2603,53.3498|-6.2595,53.3494' \
  --data-urlencode 'profile=fastbike' \
  --data-urlencode 'alternativeidx=0' \
  --data-urlencode 'format=geojson'
```

## JavaScript Example (fetch)
```js
const base = 'https://brouter.onrender.com/brouter';
const params = new URLSearchParams({
  lonlats: '-6.2603,53.3498|-6.2595,53.3494',
  profile: 'fastbike',
  alternativeidx: '0',
  format: 'geojson',
});

const res = await fetch(`${base}?${params.toString()}`);
if (!res.ok) {
  const body = await res.text();
  throw new Error(`BRouter error ${res.status}: ${body}`);
}

const data = await res.json();
const feature = data.features?.[0];
const coords = feature?.geometry?.coordinates ?? [];
```

## Python Example (requests)
```python
import requests

url = "https://brouter.onrender.com/brouter"
params = {
    "lonlats": "-6.2603,53.3498|-6.2595,53.3494",
    "profile": "fastbike",
    "alternativeidx": 0,
    "format": "geojson",
}

r = requests.get(url, params=params, timeout=20)
r.raise_for_status()
geojson = r.json()
coords = geojson["features"][0]["geometry"]["coordinates"]
```

## Suggested Agent Error Messages
- `ROUTE_INPUT_INVALID`: Waypoints missing or malformed; expected `lon,lat|lon,lat`.
- `ROUTE_OUTSIDE_COVERAGE`: Coordinates likely outside loaded Ireland segments.
- `ROUTE_TIMEOUT`: BRouter watchdog timeout; retry with shorter distance/fewer waypoints.
- `ROUTE_UPSTREAM_ERROR`: Non-200 from BRouter service.

## Prompt Snippet for an AI Agent
Use this instruction block inside your system prompt:

"When generating bike routes, call `https://brouter.onrender.com/brouter` with `profile=fastbike`, `alternativeidx=0`, and `format=geojson`. Build `lonlats` as `lon,lat|lon,lat|...` (longitude first). Validate at least 2 waypoints. If non-200, retry once with fewer via points, then report a structured error. Assume this deployment is optimized for Ireland coverage only."
