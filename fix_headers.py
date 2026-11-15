import re

# 1. Fix npc_dialogue.gd
with open(r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scripts\npc_dialogue.gd', 'r', encoding='utf-8') as f:
    npc_code = f.read()

npc_code = npc_code.replace('body is PlayerController or body.name == "Player"', 'body.name == "Player"')
with open(r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scripts\npc_dialogue.gd', 'w', encoding='utf-8') as f:
    f.write(npc_code)
print('Fixed npc_dialogue.gd')

# 2. Fix quest_manager.gd
with open(r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scripts\quest_manager.gd', 'r', encoding='utf-8') as f:
    qm_code = f.read()

qm_code = qm_code.replace('body is PlayerController or body.name == "Player"', 'body.name == "Player"')
with open(r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scripts\quest_manager.gd', 'w', encoding='utf-8') as f:
    f.write(qm_code)
print('Fixed quest_manager.gd')

# 3. Fix dialogue_box.tscn: ensure [gd_scene ...] is first line
with open(r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scenes\UI\dialogue_box.tscn', 'r', encoding='utf-8') as f:
    d_content = f.read()

# remove any misplaced [ext_resource
d_lines = d_content.splitlines()
header = '[gd_scene format=3 uid="uid://chronos_dialogue_ui"]'
ext_res = '[ext_resource type="Script" path="res://Scripts/dialogue_box.gd" id="1_dialogue_script"]'

clean_d_lines = [l for l in d_lines if not l.startswith('[gd_scene') and not l.startswith('[ext_resource')]
new_d_content = header + '\n\n' + ext_res + '\n\n' + '\n'.join(clean_d_lines)
with open(r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scenes\UI\dialogue_box.tscn', 'w', encoding='utf-8') as f:
    f.write(new_d_content)
print('Fixed dialogue_box.tscn')

# 4. Fix main.tscn: all [ext_resource ...] must be grouped together immediately after [gd_scene ...]
with open(r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\main.tscn', 'r', encoding='utf-8') as f:
    m_content = f.read()

m_lines = m_content.splitlines()
gd_scene_line = m_lines[0] # [gd_scene format=4]
ext_resources = []
other_lines = []

for line in m_lines[1:]:
    if line.startswith('[ext_resource'):
        ext_resources.append(line)
    else:
        other_lines.append(line)

new_main_content = gd_scene_line + '\n\n' + '\n'.join(ext_resources) + '\n\n' + '\n'.join(other_lines)
with open(r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\main.tscn', 'w', encoding='utf-8') as f:
    f.write(new_main_content)
print('Fixed main.tscn header and ext_resources')
