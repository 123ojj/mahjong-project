import sqlite3
import pandas as pd

db_path = r'C:\Users\USER\Desktop\majo\code\mahjong_app\assets\mahjong.db'
excel_path = r'C:\Users\USER\Desktop\majo\code\mahjong_report.xlsx'

db = sqlite3.connect(db_path)
c = db.cursor()

c.execute("DELETE FROM game_records")

try:
    c.execute("ALTER TABLE game_records ADD COLUMN createdAt TEXT")
except:
    pass

df = pd.read_excel(excel_path, sheet_name=1)

records = []
for index, row in df.iterrows():
    if pd.isna(row['playerName']):
        continue
    gameName = str(row['gameName'])
    playerName = str(row['playerName'])
    score = int(row['score']) if not pd.isna(row['score']) else 0
    winTimes = int(row['winTimes']) if not pd.isna(row['winTimes']) else 0
    selfDrawnTimes = int(row['selfDrawnTimes']) if not pd.isna(row['selfDrawnTimes']) else 0
    chuckTimes = int(row['chuckTimes']) if not pd.isna(row['chuckTimes']) else 0
    gotSelfDrawnTimes = int(row['loseSelfDrawnTimes']) if not pd.isna(row['loseSelfDrawnTimes']) else 0
    highestTai = int(row['maxExtraPointNum']) if not pd.isna(row['maxExtraPointNum']) else 0
    maxCombo = int(row['maxComboBanker']) if not pd.isna(row['maxComboBanker']) else 0
    gameCount = int(row['gameCount']) if not pd.isna(row['gameCount']) else 0
    
    date_val = row['date']
    try:
        date_str = pd.to_datetime(date_val).strftime('%Y/%m/%d %H:%M')
    except:
        date_str = str(date_val)
        
    records.append((gameName, playerName, score, winTimes, selfDrawnTimes, chuckTimes, gotSelfDrawnTimes, highestTai, maxCombo, gameCount, date_str))

c.executemany("INSERT INTO game_records (gameName, playerName, score, winTimes, selfDrawnTimes, chuckTimes, gotSelfDrawnTimes, highestTai, maxCombo, gameCount, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", records)

db.commit()
db.close()
print("Database updated with individual games successfully")
