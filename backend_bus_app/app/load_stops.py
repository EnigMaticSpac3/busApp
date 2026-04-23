import xml.etree.ElementTree as ET
import psycopg2

try:
    # Conexión ajustada a tus credenciales de Docker
    conn = psycopg2.connect(
        host="db",
        database="san_antonio_db",
        user="admin",
        password="password123",
        port="5432"
    )
    cur = conn.cursor()

    tree = ET.parse('version_2.gpx')
    root = tree.getroot()
    ns = {'gpx': 'http://www.topografix.com/GPX/1/1'}

    print("🚀 Iniciando carga de paradas de San Antonio...")

    conteo = 0
    for wpt in root.findall('gpx:wpt', ns):
        lat = wpt.get('lat')
        lon = wpt.get('lon')
        nombre = wpt.find('gpx:name', ns).text
        
        cur.execute("""
            INSERT INTO paradas (nombre, ubicacion)
            VALUES (%s, ST_SetSRID(ST_MakePoint(%s, %s), 4326))
            ON CONFLICT DO NOTHING;
        """, (nombre, lon, lat))
        conteo += 1

    conn.commit()
    print(f"✅ Se procesaron {conteo} paradas correctamente.")

except Exception as e:
    print(f"❌ Error: {e}")
finally:
    if conn:
        cur.close()
        conn.close()