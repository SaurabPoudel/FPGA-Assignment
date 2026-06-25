#!/usr/bin/env python3
import sys

def parse_vcd(filename):
    signals = {
        '%': 'A',
        '&': 'B',
        "'": 'sel',
        '"': 'Result',
        '$': 'Cout',
        '!': 'Zero',
        '#': 'Overflow'
    }
    
    # Store history: signal_name -> list of (time_ns, value)
    history = {name: [] for name in signals.values()}
    current_values = {
        'A': 0,
        'B': 0,
        'sel': 0,
        'Result': 0,
        'Cout': 0,
        'Zero': 0,
        'Overflow': 0
    }
    
    t_ns = 0
    
    with open(filename, 'r') as f:
        in_dumpvars = False
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            if line == '$dumpvars':
                in_dumpvars = True
                continue
            if line == '$end' and in_dumpvars:
                for name, val in current_values.items():
                    history[name].append((0, val))
                in_dumpvars = False
                continue
            
            if line.startswith('#'):
                t_val = int(line[1:])
                t_ns = t_val // 1000  # convert ps to ns
                continue
                
            if line.startswith('b'):
                parts = line[1:].split()
                if len(parts) == 2:
                    val_str, sig_id = parts
                    if sig_id in signals:
                        name = signals[sig_id]
                        try:
                            val = int(val_str, 2)
                        except ValueError:
                            val = val_str
                        current_values[name] = val
                        if not history[name] or history[name][-1][0] != t_ns:
                            history[name].append((t_ns, val))
                        else:
                            history[name][-1] = (t_ns, val)
            elif line[0] in ('0', '1', 'x', 'z') and len(line) >= 2:
                val_str = line[0]
                sig_id = line[1:]
                if sig_id in signals:
                    name = signals[sig_id]
                    try:
                        val = int(val_str)
                    except ValueError:
                        val = val_str
                    current_values[name] = val
                    if not history[name] or history[name][-1][0] != t_ns:
                        history[name].append((t_ns, val))
                    else:
                        history[name][-1] = (t_ns, val)
                        
    # Ensure every signal has a state up to end_time
    end_time = 220
    for name in history:
        if history[name]:
            # If the last recorded time is less than end_time, extend it
            if history[name][-1][0] < end_time:
                history[name].append((end_time, history[name][-1][1]))
        else:
            history[name] = [(0, 0), (end_time, 0)]
            
    return history

def generate_svg(history, output_filename):
    # Dimensions and layout
    width = 1200
    height = 580
    pad_left = 150
    pad_right = 60
    pad_top = 100
    pad_bottom = 60
    
    total_time = 220  # ns
    scale_x = 4.5     # pixels per ns
    
    # y-coordinates for signals
    y_coords = {
        'sel': 130,
        'A': 190,
        'B': 250,
        'Result': 310,
        'Cout': 390,
        'Zero': 450,
        'Overflow': 510
    }
    
    # Colors for signals
    colors = {
        'sel': '#c084fc',      # Purple
        'A': '#38bdf8',        # Cyan/Sky
        'B': '#f472b6',        # Pink/Rose
        'Result': '#34d399',   # Emerald Green
        'Cout': '#fbbf24',     # Amber
        'Zero': '#f87171',     # Light Red
        'Overflow': '#fb7185'  # Soft Rose/Pink-red
    }
    
    # Operation names for intervals (each is 10ns)
    ops = [
        "ADD", "SUB", "AND", "OR", "XOR", "NOR", "NAND", "XNOR",
        "NOT", "SLL", "SRL", "ROL", "ROR", "MUL", "GT", "EQ",
        "ADD", "SUB", "OR(Z)", "ADD(O)", "SUB(O)", "EQ(1)"
    ]
    
    svg = []
    
    # Header
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="100%" height="100%">')
    
    # Definitions for fonts & filters
    svg.append('''  <defs>
    <style>
      .bg { fill: #0f172a; }
      .grid { stroke: #334155; stroke-width: 1; }
      .grid-dash { stroke: #1e293b; stroke-width: 1; stroke-dasharray: 4,4; }
      .title { font-family: system-ui, -apple-system, sans-serif; font-weight: 800; font-size: 20px; fill: #f8fafc; }
      .subtitle { font-family: system-ui, -apple-system, sans-serif; font-weight: 500; font-size: 13px; fill: #94a3b8; }
      .sig-name { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-weight: bold; font-size: 13px; }
      .sig-type { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 10px; fill: #64748b; }
      .wave-text { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 10px; fill: #ffffff; text-anchor: middle; font-weight: bold; }
      .axis-text { font-family: system-ui, -apple-system, sans-serif; font-size: 11px; fill: #64748b; text-anchor: middle; }
      .op-text { font-family: system-ui, -apple-system, sans-serif; font-weight: 700; font-size: 10px; fill: #94a3b8; text-anchor: middle; }
    </style>
  </defs>''')
    
    # Background
    svg.append(f'  <rect width="{width}" height="{height}" class="bg" />')
    
    # Title & Metadata
    svg.append(f'  <text x="30" y="45" class="title">8-bit ALU (alu8) Simulation Waveforms</text>')
    svg.append(f'  <text x="30" y="70" class="subtitle">Lab Assignment | Student: Saurab Poudel (Roll No: 079BEI036)</text>')
    
    # Vertical grid lines & ticks
    for i in range(23):
        t = i * 10
        x = pad_left + t * scale_x
        
        # Grid line
        if i == 0 or i == 22:
            svg.append(f'  <line x1="{x}" y1="{pad_top}" x2="{x}" y2="{height - pad_bottom}" class="grid" stroke-width="1.5" />')
        else:
            svg.append(f'  <line x1="{x}" y1="{pad_top}" x2="{x}" y2="{height - pad_bottom}" class="grid-dash" />')
            
        # Axis label
        if i % 2 == 0:
            svg.append(f'  <text x="{x}" y="{height - pad_bottom + 20}" class="axis-text">{t} ns</text>')
            
    # Operation labels at the top
    for i in range(22):
        t_mid = i * 10 + 5
        x = pad_left + t_mid * scale_x
        op_name = ops[i]
        # Highlight boundary for different test sections
        # Draw operation text
        svg.append(f'  <text x="{x}" y="{pad_top - 10}" class="op-text">{op_name}</text>')
        
    # Draw horizontal guides for signals
    for sig, y in y_coords.items():
        svg.append(f'  <line x1="{pad_left}" y1="{y}" x2="{pad_left + total_time * scale_x}" y2="{y}" stroke="#1e293b" stroke-width="1" />')

    # Draw Signal Names & Types
    for sig, y in y_coords.items():
        color = colors[sig]
        # Label
        svg.append(f'  <text x="30" y="{y + 4}" fill="{color}" class="sig-name">{sig}</text>')
        # Type
        sig_t = "wire [7:0]" if sig in ['A', 'B', 'Result'] else "wire [3:0]" if sig == 'sel' else "wire"
        svg.append(f'  <text x="95" y="{y + 4}" class="sig-type">{sig_t}</text>')
        
    # Helper to format values for display inside buses
    def fmt_val(sig_name, val):
        if isinstance(val, str):
            return val
        if sig_name == 'sel':
            return f"{val:X}"
        return f"{val:02X}"
        
    # Draw waveforms
    for sig, y in y_coords.items():
        color = colors[sig]
        hist = history[sig]
        
        # Determine if it's a bus or a single bit
        is_bus = sig in ['A', 'B', 'sel', 'Result']
        
        if is_bus:
            # Render bus segments
            # A segment is formed between consecutive transitions
            for idx in range(len(hist) - 1):
                t1, val1 = hist[idx]
                t2, val2 = hist[idx+1]
                
                x1 = pad_left + t1 * scale_x
                x2 = pad_left + t2 * scale_x
                
                # Check endpoints to draw hex-like transitions
                x1_top = x1 if t1 == 0 else x1 + 4
                x1_mid = None if t1 == 0 else x1
                x1_bot = x1 if t1 == 0 else x1 + 4
                
                x2_top = x2 if t2 == total_time else x2 - 4
                x2_mid = None if t2 == total_time else x2
                x2_bot = x2 if t2 == total_time else x2 - 4
                
                # Build polygon path
                path = f"M {x1_top} {y-12} L {x2_top} {y-12}"
                if x2_mid is not None:
                    path += f" L {x2_mid} {y}"
                path += f" L {x2_bot} {y+12} L {x1_bot} {y+12}"
                if x1_mid is not None:
                    path += f" L {x1_mid} {y}"
                path += " Z"
                
                # Fill color with opacity, border with full color
                svg.append(f'  <path d="{path}" fill="{color}15" stroke="{color}" stroke-width="1.8" />')
                
                # Draw text inside if there's enough space
                seg_width = x2 - x1
                if seg_width > 24:
                    val_str = fmt_val(sig, val1)
                    svg.append(f'  <text x="{(x1+x2)/2}" y="{y+4}" class="wave-text">{val_str}</text>')
        else:
            # Render single bit
            # Generate path step-by-step
            path_parts = []
            curr_y = y + 12 if hist[0][1] == 0 else y - 12
            path_parts.append(f"M {pad_left} {curr_y}")
            
            for idx in range(len(hist) - 1):
                t1, val1 = hist[idx]
                t2, val2 = hist[idx+1]
                
                x1 = pad_left + t1 * scale_x
                x2 = pad_left + t2 * scale_x
                
                next_y = y + 12 if val2 == 0 else y - 12
                
                # Line to end of current segment
                path_parts.append(f"L {x2} {curr_y}")
                # Vertical transition if y changes
                if curr_y != next_y and t2 < total_time:
                    path_parts.append(f"L {x2} {next_y}")
                curr_y = next_y
                
            # Close path line
            svg.append(f'  <path d="{" ".join(path_parts)}" fill="none" stroke="{color}" stroke-width="2" stroke-linejoin="miter" stroke-linecap="square" />')
            
    svg.append('</svg>')
    
    with open(output_filename, 'w') as f:
        f.write('\n'.join(svg))
    print(f"Successfully generated {output_filename}")

if __name__ == '__main__':
    vcd_file = 'alu.vcd'
    if len(sys.argv) > 1:
        vcd_file = sys.argv[1]
    hist = parse_vcd(vcd_file)
    generate_svg(hist, 'waveform.svg')
