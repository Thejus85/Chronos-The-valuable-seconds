with open('Scenes/Characters/temporal_skeleton.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

# Add script resource
if 'res://Scripts/npc_dialogue.gd' not in text:
    text = text.replace(
        '[ext_resource type="Texture2D"',
        '[ext_resource type="Script" path="res://Scripts/npc_dialogue.gd" id="2_npc_script"]\n[ext_resource type="Texture2D"'
    )

    # Add CircleShape2D_interact sub resource
    circle_sub = '''[sub_resource type="CircleShape2D" id="CircleShape2D_interact"]
radius = 28.0

'''
    idx = text.find('[node name="TemporalSkeleton"')
    text = text[:idx] + circle_sub + text[idx:]

    # Update TemporalSkeleton node
    old_node = '[node name="TemporalSkeleton" type="CharacterBody2D"]\ncollision_layer = 4\ncollision_mask = 3'
    new_node = '''[node name="TemporalSkeleton" type="CharacterBody2D"]
script = ExtResource("2_npc_script")
npc_name = "Ancient Chrono-Echo"
npc_role = "Timeline 2146 Survivor"
initial_dialogue = PackedStringArray("Greetings, traveler of the 2096 origin line...", "I was an explorer who entered the Northern Portal when the Loom first fractured.", "The 4th stabilizer—the Chronal Phase Key—is enshrined on the sacred cliff altar to the north-west.", "Climb the carved stone stairs past the cliff to retrieve it.", "Then press [C] or [TAB] to open your portable Loom Terminal and weave the 4 stabilizers into the CHRONOS MASTER MATRIX!", "Once forged, step into the ancient Nexus Portal in the eastern grove to seal the tear forever!")
z_index = 2
collision_layer = 4
collision_mask = 3'''
    text = text.replace(old_node, new_node)

    # Add InteractionArea and PromptLabel
    children = '''

[node name="InteractionArea" type="Area2D" parent="."]
collision_layer = 4
collision_mask = 3

[node name="CollisionShape2D" type="CollisionShape2D" parent="InteractionArea"]
shape = SubResource("CircleShape2D_interact")

[node name="PromptLabel" type="Label" parent="."]
visible = false
offset_left = -35.0
offset_top = -28.0
offset_right = 35.0
offset_bottom = -14.0
theme_override_font_sizes/font_size = 10
text = "[E] SPEAK"
horizontal_alignment = 1
'''
    text = text.strip() + children + '\n'

    with open('Scenes/Characters/temporal_skeleton.tscn', 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    print("Updated temporal_skeleton.tscn with dialogue interaction!")
else:
    print("temporal_skeleton.tscn already has script.")
