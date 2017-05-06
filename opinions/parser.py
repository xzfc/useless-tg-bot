def parse(message):
    # <mention> " — " {text}
    if len(message) >= 2 and \
       message[0].type in ['mention', 'text_mention'] and \
       message[1].type == 'plain' and message[1].text.startswith(" — "):
        print("add")
        print("  subj =", message[0].user)
        print("  text =", message[1])
        return

    # <mention> " and " <mention> " — " {text}
    if len(message) >= 4 and \
       message[0].type in ['mention', 'text_mention'] and \
       message[1].type in ['plain'] and message[1].text.strip() == "и" and \
       message[2].type in ['mention', 'text_mention'] and \
       message[3].type in ['plain'] and message[3].text.startswith(" — "):
        print("add")
        print("  subj0 =", message[0].user)
        print("  subj1 =", message[2])
        print("  text =", message[3])
        return
