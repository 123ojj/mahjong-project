import sqlite3
import pprint

conn = sqlite3.connect('mahjong.db')
cursor = conn.cursor()
cursor.execute("SELECT name, sql FROM sqlite_master WHERE type='table'")
tables = cursor.fetchall()
for table in tables:
    print(f"Table: {table[0]}")
    print(f"Schema: {table[1]}")
    print("-" * 20)
    
    # get a few rows
    cursor.execute(f"SELECT * FROM {table[0]} LIMIT 3")
    rows = cursor.fetchall()
    pprint.pprint(rows)
    print("=" * 40)
conn.close()
