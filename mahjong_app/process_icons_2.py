from PIL import Image

img = Image.open('assets/rank2.png').convert("RGBA")
width, height = img.size
row_height = height // 6

for i in range(6):
    # Based on our calculations, the emblem is between x=183 and x=320.
    # We will crop from x=100 to x=400 to safely capture the emblem but exclude the text.
    left = 100
    upper = i * row_height
    right = 400
    lower = (i + 1) * row_height
    
    piece = img.crop((left, upper, right, lower))
    
    # Make near-black background transparent
    datas = piece.getdata()
    newData = []
    
    threshold = 30
    for item in datas:
        # Check if the pixel is near-black
        if max(item[:3]) <= threshold:
            newData.append((0, 0, 0, 0))
        else:
            newData.append(item)
            
    piece.putdata(newData)
    
    # Crop tightly to the non-transparent pixels (the emblem)
    bbox = piece.getbbox()
    if bbox:
        piece = piece.crop(bbox)
        
    piece.save(f'assets/new_rank_{i}.png')
    print(f'Saved new_rank_{i}.png (width: {piece.size[0] if bbox else 0}, height: {piece.size[1] if bbox else 0})')

print("Done")
