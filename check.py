import pandas as pd
import json

excel_path = r'C:\Users\USER\Desktop\majo\code\mahjong_report.xlsx'
df2 = pd.read_excel(excel_path, sheet_name=2)
df3 = pd.read_excel(excel_path, sheet_name=3)

data = {
    'sheet2_cols': list(df2.columns),
    'sheet3_cols': list(df3.columns),
    'sheet2_head': df2.head(2).to_dict('records'),
    'sheet3_head': df3.head(2).to_dict('records')
}

with open('check_sheets.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
