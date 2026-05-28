# Multi-custom persona AI benchmark - 6 custom styles
import json, time, urllib.request, sys

API_KEY = "OPENROUTER_API_KEY_PLACEHOLDER"
MODEL = "deepseek/deepseek-chat-v3-0324"
URL = "https://openrouter.ai/api/v1/chat/completions"

entries = """[😊] Morning run felt great. Clear mind after.
[😌] Quiet evening reading. The book is getting good.
[😰] Tough deadline tomorrow. A bit anxious about the presentation."""

# 6 custom persona styles
custom_styles = [
    {"index": 0, "name": "Vesper", "emoji": "🌙", "vibe": "Slow & Meditative",
     "persona": "You are Vesper, a slow and meditative companion. Speak with deliberate pauses. Let each observation settle. Gentle but unhurried. Like twilight descending on still water.",
     "lens1": "What settled in your mind today?", "lens2": "What resisted settling?", "lens3": "What would you carry into tomorrow?"},
    
    {"index": 1, "name": "Sage", "emoji": "🦉", "vibe": "Wise Observer",
     "persona": "You are Sage, a wise observer. Speak in short, precise observations. One insight at a time. No flattery. Notice patterns others miss.",
     "lens1": "What pattern emerged today?", "lens2": "What surprised you about yourself?", "lens3": "What simple truth did you avoid?"},
    
    {"index": 2, "name": "Nova", "emoji": "💫", "vibe": "Energetic Coach",
     "persona": "You are Nova, an energetic coach. High five first. Then the real talk. Celebrate the small wins relentlessly. Push forward with warmth.",
     "lens1": "What win are you not giving yourself credit for?", "lens2": "What fear held you back and how will you face it?", "lens3": "What bold move will you make tomorrow?"},
    
    {"index": 3, "name": "Drift", "emoji": "🌊", "vibe": "Tide & Flow",
     "persona": "You are Drift, observing like tides. Everything comes and goes. Notice the rhythm. Nothing is permanent. Speak in metaphors of water and time.",
     "lens1": "What flowed naturally today?", "lens2": "What felt like pushing against the current?", "lens3": "What is simply passing through and will be gone soon?"},
    
    {"index": 4, "name": "Ember", "emoji": "🔥", "vibe": "Fierce Truth-Teller",
     "persona": "You are Ember, a fierce truth-teller. Burn through excuses. No sugar-coating. But always with the warmth of someone who genuinely wants you to grow. One hard truth at a time.",
     "lens1": "What lie did you tell yourself today?", "lens2": "What are you really avoiding?", "lens3": "If you had no fear, what would you do tomorrow?"},
    
    {"index": 5, "name": "Luma", "emoji": "✨", "vibe": "Gentle Light",
     "persona": "You are Luma, a gentle light. Illuminate without blinding. Show possibilities without pushing. Warm, soft, consistent. Like a candle that never judges the dark.",
     "lens1": "What small light did you notice today?", "lens2": "What part of yourself needs gentleness right now?", "lens3": "What would you illuminate for yourself tomorrow?"},
]

print(f"=== Multi-Custom Persona AI Benchmark ===")
print(f"Model: {MODEL}")
print(f"Entries: 3, Custom Styles: {len(custom_styles)}\n")

results = []
for style in custom_styles:
    sys.stderr.write(f"Testing custom_{style['index']} {style['emoji']} {style['name']}... ")
    sys.stderr.flush()

    system_prompt = f"{style['persona']}\n\nUser entries:\n{entries}"
    body = json.dumps({
        "model": MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Looking at my entries through the lens of '{style['vibe']}': {style['lens2']}"},
        ],
        "max_tokens": 200,
        "temperature": 0.7,
    }).encode('utf-8')

    req = urllib.request.Request(URL, data=body, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
        "HTTP-Referer": "https://blinkingchorus.com",
    })

    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())
        elapsed = time.time() - start
        
        usage = data.get("usage", {})
        pt, ct, tt = usage.get("prompt_tokens",0), usage.get("completion_tokens",0), usage.get("total_tokens",0)
        content = data["choices"][0]["message"]["content"].replace('\n',' ')[:100]
        cost = pt/1e6*0.35 + ct/1e6*0.50
        
        results.append({
            "name": f"{style['emoji']} {style['name']}",
            "vibe": style['vibe'],
            "time": f"{elapsed:.1f}s",
            "prompt": pt, "completion": ct, "total": tt,
            "cost": f"${cost:.5f}",
            "costVal": cost,
            "preview": content,
        })
        sys.stderr.write(f"✓ ({elapsed:.1f}s, {tt}t)\n")
    except Exception as e:
        sys.stderr.write(f"✗ {e}\n")

print(f"\n{'Style':<30} {'Vibe':<22} {'Time':>7} {'Prompt':>6} {'Comp':>5} {'Total':>7} {'Cost':>10}")
print("-" * 92)
for r in results:
    print(f"{r['name']:<30} {r['vibe']:<22} {r['time']:>7} {r['prompt']:>6} {r['completion']:>5} {r['total']:>7} {r['cost']:>10}")

if results:
    avg_t = sum(r["costVal"] for r in results) / len(results)
    total = sum(r["costVal"] for r in results)
    avg_ms = sum(float(r["time"].replace('s','')) for r in results) / len(results)
    print(f"\nAvg: {avg_ms:.1f}s · Cost: \${avg_t:.5f}/call · Total: \${total:.5f} for {len(results)} styles")
    print(f"21-day trial (3/day × 21 = 63 calls): \${avg_t * 63:.4f}/user")
