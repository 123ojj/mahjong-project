import pandas as pd
import json

excel_path = r'C:\Users\USER\Desktop\majo\code\mahjong_report .xlsx'
xl = pd.ExcelFile(excel_path)
sheet_names = xl.sheet_names

data = {'sheet_names': sheet_names, 'sheets': {}}

for i, name in enumerate(sheet_names):
    df = pd.read_excel(excel_path, sheet_name=name)
    data['sheets'][f"{i}_{name}"] = {
        'columns': list(df.columns),
        'head': df.head(3).to_dict('records')
    }

with open('check_sheets2.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
