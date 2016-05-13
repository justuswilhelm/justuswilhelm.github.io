"""."""
from sys import stdin


if __name__ == "__main__":
    in_code = False
    code_segments = []
    code_segment = []
    language = None
    for line in map(lambda l: l.rstrip(), stdin.readlines()):
        if line.startswith('language'):
            language = line.split(':')[1].strip()
            continue
        if not in_code and line.startswith('```') and language in line:
            in_code = True
            continue
        elif in_code and line == '```':
            code_segments.append("\n".join(code_segment))
            code_segment = []
            in_code = False
        if in_code:
            code_segment.append(line)
    for code_segment in code_segments:
        print(code_segment)
