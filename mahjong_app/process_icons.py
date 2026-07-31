from PIL import Image

img = Image.open('assets/rank2.png').convert("RGBA")
width, height = img.size
row_height = height // 6

for i in range(6):
    left = 0
    upper = i * row_height
    # Take the left half of the image to ensure we capture the whole emblem
    right = width // 2
    lower = (i + 1) * row_height
    
    piece = img.crop((left, upper, right, lower))
    
    # Make near-black background transparent
    datas = piece.getdata()
    newData = []
    
    # Threshold for black background
    threshold = 20
    for item in datas:
        if item[0] <= threshold and item[1] <= threshold and item[2] <= threshold:
            # Change to transparent
            newData.append((0, 0, 0, 0))
        else:
            newData.append(item)
            
    piece.putdata(newData)
    
    # Crop tightly to the non-transparent pixels
    bbox = piece.getbbox()
    if bbox:
        piece = piece.crop(bbox)
        
    piece.save(f'assets/new_rank_{i}.png')
    print(f'Saved new_rank_{i}.png')

print("Done")
