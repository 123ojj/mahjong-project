from PIL import Image

img = Image.open('assets/rank2.png').convert("RGBA")
width, height = img.size
row_height = height // 6

for i in range(6):
    left = 150
    upper = i * row_height
    # The text on the right starts quite early for some rows.
    # 330 should safely capture the emblem without touching the text.
    right = 330
    lower = (i + 1) * row_height
    
    piece = img.crop((left, upper, right, lower))
    pixels = piece.load()
    pw, ph = piece.size
    
    # BFS flood fill to remove background connected to the edges
    visited = set()
    from collections import deque
    queue = deque()
    
    # Add all border pixels as starting points for background removal
    for x in range(pw):
        queue.append((x, 0))
        queue.append((x, ph-1))
    for y in range(ph):
        queue.append((0, y))
        queue.append((pw-1, y))
        
    def is_bg(r, g, b):
        # Background is very dark (around 14, 14, 16)
        # Using a relaxed threshold to catch halos, but since it's flood fill, 
        # it won't destroy the dark parts inside the emblem.
        return sum([r,g,b]) < 150 and max(r,g,b) < 65

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited: continue
        visited.add((x, y))
        
        r, g, b, a = pixels[x, y]
        if is_bg(r, g, b):
            pixels[x, y] = (0, 0, 0, 0)
            for dx, dy in [(-1,0), (1,0), (0,-1), (0,1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < pw and 0 <= ny < ph and (nx, ny) not in visited:
                    queue.append((nx, ny))
                    
    # Clean up isolated pixels or noise that flood fill missed?
    # Flood fill handles continuous background perfectly.
    
    bbox = piece.getbbox()
    if bbox:
        piece = piece.crop(bbox)
        
    piece.save(f'assets/new_rank_{i}.png')
    print(f'Saved new_rank_{i}.png (width: {piece.size[0] if bbox else 0}, height: {piece.size[1] if bbox else 0})')

print("Done")
