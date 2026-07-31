from PIL import Image

img = Image.open('assets/rank2.png').convert("RGBA")
width, height = img.size

# Exact Y boundaries determined from image analysis
y_ranges = [
    (49, 167),
    (202, 311),
    (348, 459),
    (498, 614),
    (652, 772),
    (806, 937)
]

for i, (y_start, y_end) in enumerate(y_ranges):
    left = 130
    upper = y_start - 10 # add a small padding
    right = 350
    lower = y_end + 10 # add a small padding
    
    piece = img.crop((left, upper, right, lower))
    pixels = piece.load()
    pw, ph = piece.size
    
    # BFS flood fill to remove background
    visited = set()
    from collections import deque
    queue = deque()
    
    # Start flood fill from edges
    for x in range(pw):
        queue.append((x, 0))
        queue.append((x, ph-1))
    for y in range(ph):
        queue.append((0, y))
        queue.append((pw-1, y))
        
    def is_bg(r, g, b):
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
                    
    bbox = piece.getbbox()
    if bbox:
        piece = piece.crop(bbox)
        
    piece.save(f'assets/new_rank_{i}.png')
    print(f'Saved new_rank_{i}.png (width: {piece.size[0] if bbox else 0}, height: {piece.size[1] if bbox else 0})')

print("Done")
