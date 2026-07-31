from PIL import Image

img = Image.open('assets/rank2.png')
width, height = img.size
row_height = height // 6

for i in range(6):
    left = 0
    upper = i * row_height
    # The emblem is on the left side, roughly square.
    # Taking a slightly wider crop to ensure it's not cut off, since the background is black.
    # Let's take 1.2 * row_height to be safe.
    right = int(row_height * 1.25)
    lower = (i + 1) * row_height
    
    piece = img.crop((left, upper, right, lower))
    piece.save(f'assets/new_rank_{i}.png')
    print(f'Saved new_rank_{i}.png')

print("Done")
