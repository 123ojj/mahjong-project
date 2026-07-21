import sqlite3
import pandas as pd
import json
import math

db_path = r'C:\Users\USER\Desktop\majo\code\mahjong_app\assets\mahjong.db'
excel_path = r'C:\Users\USER\Desktop\majo\code\mahjong_report .xlsx'

db = sqlite3.connect(db_path)
c = db.cursor()

# Get players for each game
try:
    c.execute("ALTER TABLE game_records ADD COLUMN historyJson TEXT DEFAULT '[]'")
except:
    pass

c.execute("SELECT gameName, playerName FROM game_records ORDER BY rowid")
rows = c.fetchall()
games = {}
for r in rows:
    gname = r[0]
    pname = r[1]
    if gname not in games:
        games[gname] = []
    if len(games[gname]) < 4:
        games[gname].append(pname)

df = pd.read_excel(excel_path, sheet_name=1)

updates = []

for gname, players in games.items():
    if len(players) != 4:
        continue
    
    game_df = df[df['牌局名稱'] == gname].sort_values(by=['第幾將', '第幾局'])
    if len(game_df) == 0:
        continue
    
    # Initialize state
    currentScores = [0, 0, 0, 0]
    selfDrawnCount = [0, 0, 0, 0]
    winCount = [0, 0, 0, 0]
    chuckCount = [0, 0, 0, 0]
    gotSelfDrawnCount = [0, 0, 0, 0]
    maxTaiCount = [0, 0, 0, 0]
    maxComboCount = [0, 0, 0, 0]
    uiPositions = [0, 1, 2, 3]
    viewOffset = 0
    dealerPassCount = 0
    totalHandsPlayed = 1
    
    # initial dealer is the dealer of the first hand
    first_row = game_df.iloc[0]
    dealerName = str(first_row['莊家'])
    if dealerName in players:
        currentDealerIndex = players.index(dealerName)
    else:
        currentDealerIndex = 0
        
    comboCount = 0
    
    historyJson = []
    
    # add initial state
    historyJson.append([
        *currentScores,
        *selfDrawnCount,
        *winCount,
        *chuckCount,
        *gotSelfDrawnCount,
        *maxTaiCount,
        *maxComboCount,
        currentDealerIndex,
        comboCount,
        *uiPositions,
        viewOffset,
        dealerPassCount,
        totalHandsPlayed
    ])
    
    for _, row in game_df.iterrows():
        res = str(row['結果']).strip()
        winner = str(row['贏家']).strip()
        loser = str(row['放槍者']).strip()
        cur_dealer = str(row['莊家']).strip()
        tai = int(row['台數']) if not pd.isna(row['台數']) else 0
        
        # update scores
        for i, p in enumerate(players):
            if p in row and not pd.isna(row[p]):
                currentScores[i] += int(row[p])
                
        if res == '胡牌':
            if winner in players:
                w_idx = players.index(winner)
                winCount[w_idx] += 1
                if tai > maxTaiCount[w_idx]:
                    maxTaiCount[w_idx] = tai
            if loser in players:
                l_idx = players.index(loser)
                chuckCount[l_idx] += 1
        elif res == '自摸':
            if winner in players:
                w_idx = players.index(winner)
                selfDrawnCount[w_idx] += 1
                if tai > maxTaiCount[w_idx]:
                    maxTaiCount[w_idx] = tai
                for i in range(4):
                    if i != w_idx:
                        gotSelfDrawnCount[i] += 1
                        
        totalHandsPlayed += 1
        
        # calculate next dealer / combo
        if cur_dealer in players:
            d_idx = players.index(cur_dealer)
        else:
            d_idx = currentDealerIndex
            
        if winner == cur_dealer or res == '流局' or res == '和局':
            comboCount += 1
            if comboCount > maxComboCount[d_idx]:
                maxComboCount[d_idx] = comboCount
        else:
            comboCount = 0
            currentDealerIndex = (d_idx + 1) % 4
            dealerPassCount += 1
            
        historyJson.append([
            *currentScores,
            *selfDrawnCount,
            *winCount,
            *chuckCount,
            *gotSelfDrawnCount,
            *maxTaiCount,
            *maxComboCount,
            currentDealerIndex,
            comboCount,
            *uiPositions,
            viewOffset,
            dealerPassCount,
            totalHandsPlayed
        ])
        
    updates.append((json.dumps(historyJson), gname))

print(f"Prepared {len(updates)} games to update.")
c.executemany("UPDATE game_records SET historyJson = ? WHERE gameName = ?", updates)
db.commit()
db.close()
print("historyJson updated successfully.")
