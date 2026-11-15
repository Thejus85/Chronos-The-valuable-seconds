import re

# 1. Player.tscn
p_path = r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Player.tscn'
with open(p_path, 'r', encoding='utf-8') as f:
    p_content = f.read()

if 'res://Scripts/player.gd' not in p_content:
    p_content = re.sub(
        r'(\[ext_resource type="Texture2D")',
        '[ext_resource type="Script" path="res://Scripts/player.gd" id="1_script"]\n\\1',
        p_content,
        count=1
    )
    p_content = re.sub(
        r'(\[node name="Player" type="CharacterBody2D"\])',
        '\\1\nscript = ExtResource("1_script")',
        p_content,
        count=1
    )
    with open(p_path, 'w', encoding='utf-8') as f:
        f.write(p_content)
    print('Attached script to Player.tscn')

# 2. main.tscn
m_path = r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\main.tscn'
with open(m_path, 'r', encoding='utf-8') as f:
    m_content = f.read()

if 'res://Scripts/time_slip_manager.gd' not in m_content:
    script_exts = '''[ext_resource type="Script" path="res://Scripts/time_slip_manager.gd" id="20_time_slip"]
[ext_resource type="Script" path="res://Scripts/quest_manager.gd" id="21_quest"]
[ext_resource type="Script" path="res://Scripts/door_transition.gd" id="22_door"]
'''
    first_node_idx = m_content.find('[node name="Main"')
    m_content = m_content[:first_node_idx] + script_exts + '\n' + m_content[first_node_idx:]
    
    # Attach time_slip to Main
    m_content = re.sub(
        r'(\[node name="Main" type="Node2D" unique_id=1499319488\])',
        '\\1\nscript = ExtResource("20_time_slip")',
        m_content,
        count=1
    )
    
    # Attach quest to QuestItems
    m_content = re.sub(
        r'(\[node name="QuestItems" type="Node2D" unique_id=936030152\])',
        '\\1\nscript = ExtResource("21_quest")',
        m_content,
        count=1
    )
    
    # Attach door to LastDoorTrigger
    m_content = re.sub(
        r'(\[node name="LastDoorTrigger" type="Area2D"\])',
        '\\1\nscript = ExtResource("22_door")',
        m_content,
        count=1
    )
    
    with open(m_path, 'w', encoding='utf-8') as f:
        f.write(m_content)
    print('Attached scripts to main.tscn')

# 3. npc_scientist_cozy.tscn
s_path = r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scenes\Characters\npc_scientist_cozy.tscn'
with open(s_path, 'r', encoding='utf-8') as f:
    s_content = f.read()

if 'res://Scripts/npc_dialogue.gd' not in s_content:
    s_content = re.sub(
        r'(\[ext_resource type="Texture2D")',
        '[ext_resource type="Script" path="res://Scripts/npc_dialogue.gd" id="3_npc_script"]\n\\1',
        s_content,
        count=1
    )
    s_content = re.sub(
        r'(\[node name="NPC_Dr_Aris" type="CharacterBody2D"\])',
        '\\1\nscript = ExtResource("3_npc_script")\nnpc_name = "Dr. Aris"\nnpc_role = "Lead Temporal Physicist"',
        s_content,
        count=1
    )
    with open(s_path, 'w', encoding='utf-8') as f:
        f.write(s_content)
    print('Attached script to npc_scientist_cozy.tscn')

# 4. npc_assistant_cozy.tscn
a_path = r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scenes\Characters\npc_assistant_cozy.tscn'
with open(a_path, 'r', encoding='utf-8') as f:
    a_content = f.read()

if 'res://Scripts/npc_dialogue.gd' not in a_content:
    a_content = re.sub(
        r'(\[ext_resource type="Texture2D")',
        '[ext_resource type="Script" path="res://Scripts/npc_dialogue.gd" id="3_npc_script"]\n\\1',
        a_content,
        count=1
    )
    a_content = re.sub(
        r'(\[node name="NPC_Kayla" type="CharacterBody2D"\])',
        '\\1\nscript = ExtResource("3_npc_script")\nnpc_name = "Kayla"\nnpc_role = "Systems Operator"\ninitial_dialogue = ["The outer perimeter blast doors are unlocked!","Sector 5 leads into the Ancient Jungle Valley where the waterfall flows.","Watch out for the temporal anomalies guarding the altar!"]',
        a_content,
        count=1
    )
    with open(a_path, 'w', encoding='utf-8') as f:
        f.write(a_content)
    print('Attached script to npc_assistant_cozy.tscn')

# 5. dialogue_box.tscn
d_path = r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scenes\UI\dialogue_box.tscn'
with open(d_path, 'r', encoding='utf-8') as f:
    d_content = f.read()

if 'res://Scripts/dialogue_box.gd' not in d_content:
    d_content = '[ext_resource type="Script" path="res://Scripts/dialogue_box.gd" id="1_dialogue_script"]\n\n' + d_content
    d_content = re.sub(
        r'(\[node name="DialogueBox" type="CanvasLayer"\])',
        '\\1\nscript = ExtResource("1_dialogue_script")',
        d_content,
        count=1
    )
    with open(d_path, 'w', encoding='utf-8') as f:
        f.write(d_content)
    print('Attached script to dialogue_box.tscn')

# 6. waterfall.tscn
w_path = r'c:\Users\THE_ JUZ\Documents\chronos--the-valuable-second\Scenes\Objects\waterfall.tscn'
with open(w_path, 'r', encoding='utf-8') as f:
    w_content = f.read()

if 'res://Scripts/waterfall.gd' not in w_content:
    w_content = re.sub(
        r'(\[ext_resource type="Texture2D")',
        '[ext_resource type="Script" path="res://Scripts/waterfall.gd" id="4_wf_script"]\n\\1',
        w_content,
        count=1
    )
    w_content = re.sub(
        r'(\[node name="Waterfall" type="Node2D"\])',
        '\\1\nscript = ExtResource("4_wf_script")',
        w_content,
        count=1
    )
    with open(w_path, 'w', encoding='utf-8') as f:
        f.write(w_content)
    print('Attached script to waterfall.tscn')
