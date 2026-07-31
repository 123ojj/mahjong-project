from PIL import Image
import os

img_path = 'assets/rank.png'
img = Image.open(img_path)
width, height = img.size
piece_width = width // 6

names = ['rank_0', 'rank_1', 'rank_2', 'rank_3', 'rank_4', 'rank_5']

for i in range(6):
    left = i * piece_width
    right = (i + 1) * piece_width if i < 5 else width
    box = (left, 0, right, height)
    piece = img.crop(box)
    piece.save(f'assets/{names[i]}.png')
    print(f'Saved {names[i]}.png')

print("Done")
