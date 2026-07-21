import sqlite3

# 連接到我們剛建好的完美資料庫
conn = sqlite3.connect('mahjong.db')
cursor = conn.cursor()

# 執行 SQL 查詢：把小智的所有 score 加總
cursor.execute("SELECT SUM(score) FROM game_records WHERE playerName = '小智'")

# 抓取計算結果
result = cursor.fetchone()[0]

# 印出結果
if result > 0:
    print(f"🎉 查詢成功！小智這 4000 局以來的總戰績是：贏了 {result} 分！")
else:
    print(f"💸 查詢成功！小智這 4000 局以來的總戰績是：輸了 {result} 分 (幫QQ)")

conn.close()