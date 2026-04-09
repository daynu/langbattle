import json, codecs
try:
    text = codecs.open('langbattle/machine_analyze.log', 'r', 'utf-16').read()
    data = json.loads(text)
    with open('langbattle/errors.txt', 'w', encoding='utf-8') as f:
        for err in data:
            # check if file ends in home_page.dart
            if err.get('location', {}).get('file', '').endswith('home_page.dart'):
                f.write(f"{err.get('severity')}: {err.get('message')} at line {err.get('location', {}).get('startLine')}\n")
except Exception as e:
    with open('langbattle/errors.txt', 'w', encoding='utf-8') as f:
        f.write("Error: " + str(e))
