import sqlite3, json

db_path = r'C:\Users\USER\Desktop\majo\code\mahjong_app\assets\mahjong.db'
json_path = r'C:\Users\USER\Desktop\majo\code\data.json'

db = sqlite3.connect(db_path)
c = db.cursor()

# Clear existing records
c.execute("DELETE FROM game_records")

try:
    c.execute("ALTER TABLE game_records ADD COLUMN gotSelfDrawnTimes INTEGER DEFAULT 0")
except:
    pass
try:
    c.execute("ALTER TABLE game_records ADD COLUMN highestTai INTEGER DEFAULT 0")
except:
    pass
try:
    c.execute("ALTER TABLE game_records ADD COLUMN maxCombo INTEGER DEFAULT 0")
except:
    pass
try:
    c.execute("ALTER TABLE game_records ADD COLUMN gameCount INTEGER DEFAULT 0")
except:
    pass

data = json.load(open(json_path, encoding='utf-8'))

records = []
for i, d in enumerate(data):
    batch = i // 4
    game_name = f"歷史總結 ({batch + 1})"
    records.append((game_name, d['玩家'], int(d['總分']), int(d['胡牌']), int(d['自摸']), int(d['放槍']), int(d['被自摸']), int(d['最高台數']), int(d['最多連莊']), int(d['總局數'])))

# Pad the last batch
last_batch_size = len(data) % 4
if last_batch_size != 0:
    for j in range(4 - last_batch_size):
        game_name = f"歷史總結 ({len(data) // 4 + 1})"
        records.append((game_name, f"空缺{j+1}", 0, 0, 0, 0, 0, 0, 0, 0))

c.executemany("INSERT INTO game_records (gameName, playerName, score, winTimes, selfDrawnTimes, chuckTimes, gotSelfDrawnTimes, highestTai, maxCombo, gameCount) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", records)

db.commit()
db.close()
print("Database updated successfully")
