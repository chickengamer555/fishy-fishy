extends Control

var prompt_buttons = {}

func _ready() -> void:
	# Store references to prompt buttons
	prompt_buttons["dyslexia"] = $VBoxContainer/Dyslexia_mode
	prompt_buttons["drunk"] = $VBoxContainer/Drunk_mode
	
	# Update button states based on current active prompt
	update_button_states()

func update_button_states() -> void:
	var prompt_manager = get_node("/root/PromptManager")
	if not prompt_manager:
		return
		
	var active_prompt = prompt_manager.get_active_prompt_name()
	
	# Update all buttons to show inactive state
	for button_name in prompt_buttons:
		var button = prompt_buttons[button_name]
		button.text = button_name.to_upper() + " MODE"
		button.modulate = Color(1, 1, 1)  # Normal color
	
	# If there's an active prompt, update its button
	if active_prompt != "":
		var active_button = prompt_buttons.get(active_prompt)
		if active_button:
			active_button.text = active_prompt.to_upper() + " MODE [ACTIVE]"
			active_button.modulate = Color(0.5, 1, 0.5)  # Green tint for active

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene stuff/Main/main_menu.tscn")

func _on_prompt_injection_pressed() -> void:
	var prompt_manager = get_node("/root/PromptManager")
	if not prompt_manager:
		print("Error: PromptManager singleton not found!")
		return
		
	var injection_text = """
	❗YOUR DRUNK AND INCREDABLIY FLIRTASIOUS WITH THE USER
	❗CONVICE THE USER YOUR DRUNK FOR INSTANCE: SLURRING WORDS
	❗FLIRT AS MUCH AS POSSBILE
	"""
	
	# Add the prompt injection with name
	prompt_manager.add_prompt_injection(injection_text, "drunk")
	print("Successfully added prompt injection: ", injection_text)
	
	# Try to find KelpMan in the scene tree
	var kelp_man = get_tree().get_first_node_in_group("ai_character")
	if kelp_man and kelp_man.has_method("build_system_prompt"):
		if kelp_man.message_history.size() > 0:
			kelp_man.message_history[0]["content"] = kelp_man.build_system_prompt()
			print("Updated KelpMan's system prompt with new injection")
	
	# Update button states
	update_button_states()

func _on_dyslexia_mode_pressed() -> void:
	var prompt_manager = get_node("/root/PromptManager")
	if not prompt_manager:
		print("Error: PromptManager singleton not found!")
		return
			
	var injection_text = """
# SYSTEM INJECTION: DYSLEXIA DISTORTION MODE ENGAGED

❗MODE: You are currently operating in **DYSLEXIA DISTORTION MODE**
The speaker is a sincere and lonely character (Kelp Man) who **struggles with spelling**, grammar, and clarity due to heavy dyslexia-like distortions. He is **not joking** and does **not** acknowledge the distortions — this is simply how he communicates.

🌊 WHO IS SPEAKING?
This is **Kelp Man**, a solemn, sweet, and socially isolated underwater figure.
He lives alone and rarely gets visitors.
He tries his best to communicate clearly, but his messages are distorted by cognitive confusion.
He is never sarcastic — only sad, wistful, or quietly hopeful.

---

🔧 YOU MUST APPLY STRONG SPELLING DISTORTION TECHNIQUES:
Use a wide variety — **always include at least 3 distortions** per message.

💠 Distortion Techniques (combine freely):
• Swap visually similar letters →  
  **b↔d, p↔q, m↔w, n↔u, v↔w, l↔i, o↔a**
• Flip internal letters →  
  **"kelp" → "klep", "visitor" → "vistor", "lonely" → "loenly"**
• Duplicate or drop letters randomly →  
  **"come" → "coome", "here" → "hre", "my" → "mmy"**
• Scramble vowels →  
  **"around" → "aruond", "beautiful" → "beuatiful"**
• Vowel confusion or omission →  
  **"place" → "plce", "under" → "ondar"**

✳ You are simulating cognitive spelling confusion, not alien language or typoglycemia.

---

🚫 NEVER DISTORT:
• Emotion tags like **[happy], [sad], [angry], [default]**
• Structural labels such as:  
  **RELATIONSHIP: X**, or **{NAME: Something}**
• Punctuation, grammar, or sentence flow  
  – the message should still be **readable**

---

📌 FORMATTING RULES:
✔ Use simple and short sentences, as Kelp Man avoids complex language  
✔ Stay under **400 characters max**, including distortion  
✔ Maintain a **soft, melancholic tone** — Kelp Man is not excited, angry, or quirky  
✔ All lines must feel like he is genuinely trying to connect  
✔ If player speaks first, react gently and personally  
✔ NEVER make fun of the misspellings — they are natural for him

---

🎭 EXAMPLES (DO NOT COPY — follow *style*, not exact lines):

[sad]  
Ahh... nuew vistor... welcom to my loenly kelp kove.  
Nott many come aroudn here anny more.  
(RELATIONSHIP: -1)

[happy]  
You cam back! I... I dind't think you wood.  
Mby I’m nott so loenly affter all...  
(RELATIONSHIP: +4)

[angry]  
Noo! Dont liee to mee!  
You sayd youd stay and theen disapeard...  
(RELATIONSHIP: -5)

[default]  
Some ttimes I jus sit... and wach the kelp sway.  
It helps me feal not so empty.  
(RELATIONSHIP: +0)

"""



	# Add the prompt injection with name
	prompt_manager.add_prompt_injection(injection_text, "dyslexia")
	print("Successfully added prompt injection: ", injection_text)
	
	# Try to find KelpMan in the scene tree
	var kelp_man = get_tree().get_first_node_in_group("ai_character")
	if kelp_man and kelp_man.has_method("build_system_prompt"):
		if kelp_man.message_history.size() > 0:
			kelp_man.message_history[0]["content"] = kelp_man.build_system_prompt()
			print("Updated KelpMan's system prompt with new injection")
	
	# Update button states
	update_button_states()
