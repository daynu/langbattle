import json
import sys

try:
    with open('figma_node.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    if 'nodes' not in data or '0:1' not in data['nodes']:
        print("Missing node 0:1 in Figma response:", str(data)[:500])
        sys.exit(1)

    node = data['nodes']['0:1']['document']

    with open('parsed_figma_utf8.txt', 'w', encoding='utf-8') as out_f:
        def print_node(n, level=0):
            indent = "  " * level
            name = n.get('name', 'Unknown')
            out_f.write(f"{indent}- {name}\n")
            
            if 'characters' in n:
                out_f.write(f"{indent}  Text: {n['characters']}\n")
                
            if 'style' in n:
                 out_f.write(f"{indent}  Style: {n['style']}\n")
                 
            if 'fills' in n:
                fills = [f for f in n['fills'] if f.get('type') == 'SOLID']
                if fills:
                    out_f.write(f"{indent}  Fills: {[f.get('color') for f in fills]}\n")

            for child in n.get('children', []):
                print_node(child, level + 1)

        print_node(node)

except Exception as e:
    print(f"Error parsing Figma JSON: {e}")
