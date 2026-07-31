from PIL import Image

img = Image.open('assets/rank2.png').convert("RGB")
width, height = img.size

y_sums = []
for y in range(height):
    row_sum = 0
    for x in range(150, 330):
        r, g, b = img.getpixel((x, y))
        row_sum += max(r, g, b)
    y_sums.append(row_sum)

# Find rows where row_sum is very low (gap between emblems)
for y, s in enumerate(y_sums):
    if s < 180 * 25: # Arbitrary small threshold, 180 pixels * 25 brightness
        pass

# Let's just print the y indices of the peaks or the gaps.
gaps = [y for y, s in enumerate(y_sums) if s < 180 * 30]

def compact_gaps(gap_list):
    if not gap_list: return []
    res = []
    start = gap_list[0]
    prev = gap_list[0]
    for y in gap_list[1:]:
        if y == prev + 1:
            prev = y
        else:
            res.append((start, prev))
            start = y
            prev = y
    res.append((start, prev))
    return res

print(compact_gaps(gaps))
