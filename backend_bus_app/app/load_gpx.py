import gpxpy
import psycopg2
import os

def load_gpx():
    ruta_archivo = 'data/version_2.gpx'
    
    if not os.path.exists(ruta_archivo):
        print(f"❌ Error: No se encontró el archivo en {ruta_archivo}")
        return

    print("🔌 Conectando a la base de datos PostGIS...")
    try:
        # Nos conectamos usando el nombre del servicio de docker-compose ('db')
        conn = psycopg2.connect(
            dbname="san_antonio_db",
            user="admin",
            password="password123",
            host="db", 
            port="5432"
        )
        cur = conn.cursor()

        print("🏗️  Creando tabla 'ruta_bus'...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS ruta_bus (
                id SERIAL PRIMARY KEY,
                lat DOUBLE PRECISION,
                lon DOUBLE PRECISION,
                elevacion DOUBLE PRECISION,
                tiempo TIMESTAMP,
                geom GEOMETRY(Point, 4326)
            );
        """)
        conn.commit()

        print("📂 Leyendo archivo GPX...")
        with open(ruta_archivo, 'r', encoding='utf-8') as gpx_file:
            gpx = gpxpy.parse(gpx_file)

        puntos_insertados = 0

        # Iterar sobre las pistas, segmentos y puntos
        for track in gpx.tracks:
            for segment in track.segments:
                for point in segment.points:
                    # Crear el punto espacial (Longitud primero, luego Latitud en PostGIS)
                    query = """
                        INSERT INTO ruta_bus (lat, lon, elevacion, tiempo, geom) 
                        VALUES (%s, %s, %s, %s, ST_SetSRID(ST_MakePoint(%s, %s), 4326))
                    """
                    valores = (
                        point.latitude, 
                        point.longitude, 
                        point.elevation, 
                        point.time,
                        point.longitude, # x = lon
                        point.latitude   # y = lat
                    )
                    cur.execute(query, valores)
                    puntos_insertados += 1

        conn.commit()
        cur.close()
        conn.close()
        print(f"✅ ¡Éxito! Se insertaron {puntos_insertados} puntos de la ruta de San Antonio en la base de datos.")

    except Exception as e:
        print(f"❌ Ocurrió un error en la base de datos: {e}")

if __name__ == "__main__":
    load_gpx()