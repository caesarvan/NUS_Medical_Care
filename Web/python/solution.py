# 在一行输入3个数
a, b, c = map(int, input().split())
# treemap
map = {}

bias = 2
max = 0

while(len(map) < c):
    for x in range(1, a + 1):
        y = bias - x
        if y < 1 or y > b:
            continue
        product = x * y
        max = product if product > max else max
        if product not in map.values():
            map[len(map)] = product
            if len(map) == c:
                break
    bias += 1

    # print(map)

print(max)

