# encoding: utf-8

from pattern import top_patterns

with open("data.txt", encoding="utf8") as fin:
    data = (line.strip().split(' ') for line in fin)
    for pattern in top_patterns(data):
        print("pattern: %s, support: %s" % pattern)
