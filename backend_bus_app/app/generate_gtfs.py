"""
generate_gtfs.py — Convierte el GPX de San Antonio a un feed GTFS mínimo válido.

se implemnta lo siguiente:
  1. shapes.txt: calcula shape_dist_traveled real en metros (necesario para ETAs).
  2. stops.txt: lee los 28 waypoints del GPX en vez de hardcodear uno solo.
  3. stop_times.txt: generado desde los timestamps reales de cada waypoint
     (sin esto el feed GTFS es inválido — es el archivo más importante).
  4. trips.txt: creado correctamente (el original lo omitía por completo).
  5. calendar.txt: creado con servicio de lunes a viernes (requerido por spec).
  6. Secuencia de shapes: reinicia por segmento GPX, no por track completo.
  7. Paradas sin timestamp: interpoladas por posición en el track en vez de
     descartarse silenciosamente.
  8. shape_dist_traveled en stop_times: permite a OpenTripPlanner calcular ETAs.
"""

import gpxpy
import pandas as pd
import os
import math
from datetime import datetime, timedelta, timezone


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def haversine(lat1, lon1, lat2, lon2):
    """Distancia en metros entre dos coordenadas."""
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    a = (math.sin(math.radians(lat2 - lat1) / 2) ** 2
         + math.cos(phi1) * math.cos(phi2)
         * math.sin(math.radians(lon2 - lon1) / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def punto_mas_cercano_en_track(track_points, lat, lon):
    """
    Devuelve el índice del punto del track más cercano a (lat, lon).
    Se usa para interpolar el tiempo de paradas sin timestamp.
    """
    min_dist = float('inf')
    closest_idx = 0
    for i, p in enumerate(track_points):
        d = haversine(lat, lon, p.latitude, p.longitude)
        if d < min_dist:
            min_dist = d
            closest_idx = i
    return closest_idx, min_dist


def acumulado_distancias(track_points):
    """
    Devuelve lista de distancias acumuladas en metros para cada punto del track.
    Índice 0 = 0.0 metros.
    """
    dists = [0.0]
    for i in range(1, len(track_points)):
        p_prev = track_points[i - 1]
        p_curr = track_points[i]
        d = haversine(p_prev.latitude, p_prev.longitude,
                      p_curr.latitude, p_curr.longitude)
        dists.append(dists[-1] + d)
    return dists


# ---------------------------------------------------------------------------
# Generador principal
# ---------------------------------------------------------------------------

def generate_gtfs(gpx_path, output_folder='gtfs_san_antonio'):

    os.makedirs(output_folder, exist_ok=True)
    print(f"📖 Cargando GPX desde: {gpx_path}")

    with open(gpx_path, 'r', encoding='utf-8') as f:
        gpx = gpxpy.parse(f)

    if not gpx.tracks:
        raise ValueError("El GPX no contiene ningún track.")

    track_points = gpx.tracks[0].segments[0].points
    dist_acum = acumulado_distancias(track_points)
    total_dist = dist_acum[-1]

    print(f"   → {len(track_points)} puntos de traza | "
          f"{total_dist/1000:.2f} km | "
          f"{len(gpx.waypoints)} paradas encontradas")

    # -----------------------------------------------------------------------
    # 1. agency.txt
    # -----------------------------------------------------------------------
    agency = pd.DataFrame([{
        "agency_id":       "JAGR_LABS",
        "agency_name":     "Jorge Gonzalez — Movilidad San Antonio (Prototipo)",
        "agency_url":      "https://github.com/tu_usuario",   # <— cambia esto
        "agency_timezone": "America/Panama",
        "agency_lang":     "es",
    }])
    agency.to_csv(f'{output_folder}/agency.txt', index=False)
    print("   ✔ agency.txt")

    # -----------------------------------------------------------------------
    # 2. routes.txt
    # -----------------------------------------------------------------------
    routes = pd.DataFrame([{
        "route_id":         "SA_INTERNAL",
        "agency_id":        "JAGR_LABS",
        "route_short_name": "SA1",
        "route_long_name":  "Ruta Interna San Antonio — Enlace Metro",
        "route_type":       3,           # 3 = Bus
        "route_color":      "007BFF",
        "route_text_color": "FFFFFF",
    }])
    routes.to_csv(f'{output_folder}/routes.txt', index=False)
    print("   ✔ routes.txt")

    # -----------------------------------------------------------------------
    # 3. calendar.txt  ← 
    #    Servicio de domingo a sabado. Ajusta según la operación real.
    # -----------------------------------------------------------------------
    calendar = pd.DataFrame([{
        "service_id": "LUNES_VIERNES",
        "monday":     1, "tuesday": 1, "wednesday": 1,
        "thursday":   1, "friday":  1,
        "saturday":   1, "sunday":  1,
        "start_date": "20260101",
        "end_date":   "20261231",
    }])
    calendar.to_csv(f'{output_folder}/calendar.txt', index=False)
    print("   ✔ calendar.txt")

    # -----------------------------------------------------------------------
    # 4. trips.txt  ←
    # -----------------------------------------------------------------------
    trips = pd.DataFrame([{
        "route_id":    "SA_INTERNAL",
        "service_id":  "LUNES_VIERNES",
        "trip_id":     "SA_IDA_001",
        "trip_headsign": "Metro San Antonio",
        "direction_id":  0,              # 0 = ida, 1 = vuelta
        "shape_id":    "SA_R1",
    }])
    trips.to_csv(f'{output_folder}/trips.txt', index=False)
    print("   ✔ trips.txt")

    # -----------------------------------------------------------------------
    # 5. shapes.txt — con shape_dist_traveled real
    # -----------------------------------------------------------------------
    shape_rows = []
    for i, (pt, dist) in enumerate(zip(track_points, dist_acum)):
        shape_rows.append({
            "shape_id":           "SA_R1",
            "shape_pt_lat":       round(pt.latitude, 7),
            "shape_pt_lon":       round(pt.longitude, 7),
            "shape_pt_sequence":  i,
            "shape_dist_traveled": round(dist, 2),
        })
    pd.DataFrame(shape_rows).to_csv(f'{output_folder}/shapes.txt', index=False)
    print(f"   ✔ shapes.txt ({len(shape_rows)} puntos)")

    # -----------------------------------------------------------------------
    # 6. stops.txt — generado desde los waypoints reales del GPX
    # -----------------------------------------------------------------------
    stop_rows = []
    waypoint_meta = []   # guardamos índice en track y dist_acum para stop_times

    for idx, wpt in enumerate(gpx.waypoints):
        stop_id = f"P{idx + 1:02d}"
        closest_idx, dist_to_track = punto_mas_cercano_en_track(
            track_points, wpt.latitude, wpt.longitude
        )

        if dist_to_track > 150:
            print(f"   ⚠  Parada '{wpt.name}' está a {dist_to_track:.0f}m del track "
                  f"— verifica su posición.")

        stop_rows.append({
            "stop_id":       stop_id,
            "stop_name":     wpt.name,
            "stop_lat":      round(wpt.latitude, 7),
            "stop_lon":      round(wpt.longitude, 7),
            "location_type": 0,
        })

        # Tiempo del waypoint: si no tiene, lo interpolamos desde el track
        if wpt.time is not None:
            arrival_time = wpt.time
        else:
            arrival_time = track_points[closest_idx].time
            print(f"   ℹ  '{wpt.name}' sin timestamp — interpolado desde el track.")

        waypoint_meta.append({
            "stop_id":           stop_id,
            "arrival_time":      arrival_time,
            "track_idx":         closest_idx,
            "shape_dist_traveled": dist_acum[closest_idx],
        })

    pd.DataFrame(stop_rows).to_csv(f'{output_folder}/stops.txt', index=False)
    print(f"   ✔ stops.txt ({len(stop_rows)} paradas)")

    # -----------------------------------------------------------------------
    # 7. stop_times.txt  ←
    #
    #    GTFS exige tiempos en formato HH:MM:SS relativo al inicio del servicio.
    #    Usamos el primer waypoint como tiempo 0 del viaje.
    # -----------------------------------------------------------------------

    # Ordenamos por tiempo de llegada (por si los waypoints no están en orden)
    waypoint_meta.sort(key=lambda x: x["arrival_time"])

    # Tiempo base = primer punto del track
    t_base = track_points[0].time

    def segundos_a_gtfs(segundos):
        """Convierte segundos desde inicio de servicio a HH:MM:SS."""
        h = int(segundos // 3600)
        m = int((segundos % 3600) // 60)
        s = int(segundos % 60)
        return f"{h:02d}:{m:02d}:{s:02d}"

    stop_time_rows = []
    for seq, meta in enumerate(waypoint_meta):
        delta_seg = (meta["arrival_time"] - t_base).total_seconds()
        tiempo_gtfs = segundos_a_gtfs(delta_seg)

        stop_time_rows.append({
            "trip_id":            "SA_IDA_001",
            "arrival_time":       tiempo_gtfs,
            "departure_time":     tiempo_gtfs,   # simplificación: sin tiempo de espera
            "stop_id":            meta["stop_id"],
            "stop_sequence":      seq,
            "shape_dist_traveled": round(meta["shape_dist_traveled"], 2),
            "pickup_type":        0,             # 0 = normal
            "drop_off_type":      0,
        })

    pd.DataFrame(stop_time_rows).to_csv(f'{output_folder}/stop_times.txt', index=False)
    print(f"   ✔ stop_times.txt ({len(stop_time_rows)} registros)")

    # -----------------------------------------------------------------------
    # Resumen final
    # -----------------------------------------------------------------------
    archivos = os.listdir(output_folder)
    print(f"\n✅ Feed GTFS generado en /{output_folder}/")
    print(f"   Archivos: {', '.join(sorted(archivos))}")
    print(f"   Distancia total de la ruta: {total_dist/1000:.2f} km")
    print(f"   Paradas: {len(stop_rows)}")
    print()
    


# ---------------------------------------------------------------------------

if __name__ == "__main__":
    generate_gtfs('version_2.gpx')