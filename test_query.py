import sqlite3
import pandas as pd

db_path = r'C:\Users\USER\Desktop\majo\code\mahjong_app\assets\mahjong.db'
conn = sqlite3.connect(db_path)

query = """
SELECT
  B.playerName as coPlayer,
  SUM(A.score) as score,
  SUM(A.winTimes) as wins,
  SUM(A.gameCount) as games
FROM game_records A
JOIN game_records B ON A.gameName = B.gameName
WHERE A.playerName = '小智' AND A.playerName != B.playerName
GROUP BY B.playerName
"""

df = pd.read_sql_query(query, conn)
print("小智 stats when playing with others:")
print(df)
