import pandas as pd
import sqlite3

# 1. 連接你的資料庫
conn = sqlite3.connect('mahjong.db')

# 2. 寫 SQL 撈取你想輸出的資料
# 這裡示範撈取「小智」的所有戰績，如果你想印出全部人，就把 WHERE 那段拿掉
sql_query = "SELECT * FROM game_records WHERE playerName = '小智'"
df = pd.read_sql_query(sql_query, conn)

# 3. 建立「中英文對照表」(這就是讓標題變成中文的魔法)
rename_dict = {
    'gameName': '牌局名稱',
    'gameCount': '局數',
    'playerName': '玩家',
    'score': '分數',
    'winTimes': '胡牌次數',
    'selfDrawnTimes': '自摸次數',
    'chuckTimes': '放槍次數',
    'loseSelfDrawnTimes': '被自摸次數',
    'nextPlayerWinTimes': '下家胡牌',
    'nextPlayerSelfDrawnTimes': '下家自摸',
    'maxScore': '單局最高分',
    'maxComboBanker': '最高連莊',
    'maxExtraPointNum': '最高台數'
}

# 4. 把 DataFrame 的欄位名稱替換成中文
df = df.rename(columns=rename_dict)

# 5. 輸出成帶有中文標題的 CSV 檔案
# 💡 關鍵：使用 encoding='utf-8-sig'，保證 Excel 打開絕對不會有亂碼
output_filename = '小智的專屬戰績表.csv'
df.to_csv(output_filename, index=False, encoding='utf-8-sig')

print(f"✅ 報表產出成功！請在資料夾查看：{output_filename}")
conn.close()