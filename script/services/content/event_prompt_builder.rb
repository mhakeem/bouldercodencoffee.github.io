# frozen_string_literal: true

require "date"

# Builds the AI prompt text for an event's announcement, voice matched to
# real past posts from https://ruby.social/@codencoffee. See EventContentService.
class EventPromptBuilder
  # Few-shot examples from the account's real post history, deliberately picked for
  # structural variety (not just wording variety) since most of the account's real
  # posts converge on the same "Remote workers, <verb> your home office!" template.
  REAL_EXAMPLES = [
    <<~EXAMPLE1.strip,
      💻️☕️️ Code && Coffee is tomorrow (Wednesday) at The Rayback - 8am until whenever! Come for
      the coffee, stay for the company. Write some code, catch up with fellow devs, and get out of
      your home office for a bit.

      This week's food truck: Temaki Tornado 🍣
      Fresh handrolls and sushi, if you happen to get hungry!

      See you tomorrow! 🧑‍💻👩‍💻👨‍💻
    EXAMPLE1
    <<~EXAMPLE2.strip,
      🍣 Handrolls and laptops — name a better combo. We'll wait.

      💻☕️ Code && Coffee is tomorrow (Wednesday) at The Rayback - 8am until whenever! Come for
      the fish, stay for the company.

      This week's food truck: Temaki Tornado 🍣
      Fresh sushi and handrolls, back by popular demand!

      See you there! 🧑‍💻👩‍💻👨‍💻
    EXAMPLE2
    <<~EXAMPLE3.strip,
      💻️☕️️ Code && Coffee is tomorrow (Wednesday) at The Rayback - 8am start!

      Join fellow devs for coffee, coding, and community until whenever.

      This week's food truck: Arepas Caribbean 🌴
      Latin Caribbean fusion - gluten & dairy free!

      See you there! 🧑‍💻👩‍💻👨‍💻
    EXAMPLE3
    <<~EXAMPLE4.strip,
      💻️☕️️ Code && Coffee is tomorrow (Wednesday) at The Rayback - 8am start!

      It's April 1st, but this is no joke: Remote workers, join us for coffee, coding, and community until whenever!

      This week's food truck: La Rue Bayou 🦞
      French Creole cuisine - Crab Cakes, Po boys, Gumbo & Beignets! New Orleans flavor in Boulder.

      See you there! 🧑‍💻👩‍💻👨‍💻
    EXAMPLE4
    <<~EXAMPLE5.strip
      💻️☕️️ Code && Coffee is tomorrow (Wednesday) at The Rayback - 8am start!

      Snow in the forecast? Perfect coding weather! Brave the elements and join fellow devs for coffee, warm vibes, and productivity until whenever.

      This week's food truck: Temaki Tornado 🍣
      Fresh handrolls to warm you up from the inside out!

      See you there, snow or shine! 🧑‍💻👩‍💻👨‍💻❄️
    EXAMPLE5
  ].freeze

  # @param event [EventDetails]
  def initialize(event)
    @event = event
  end

  # @return [String] the AI prompt text
  def build
    event.cancelled? ? cancellation_prompt : meetup_prompt
  end

  private

  attr_reader :event

  def meetup_prompt
    <<~PROMPT
      Write the announcement text for tomorrow's "Code && Coffee" developer meetup in Boulder, CO.
      This exact text will be used as the website's event page content AND posted verbatim to
      Mastodon and Slack, so it must work everywhere at once, in the exact voice of the real past
      posts from the account shown below.

      ## Rules

      1. Most weeks, start directly with the fixed announcement line "💻☕️ Code && Coffee is
         tomorrow (#{day_name}) at #{event.location_name} - 8am start!". Occasionally (not most
         weeks) you may lead with a short, topical hook line before it instead, as a couple of the
         examples below do - don't do this by default.
      2. Follow with a one-line call to action inviting people to join. Use the examples below as a
         voice and tone reference, not a script - vary your specific wording and reach for synonyms
         rather than repeating the same phrase verbatim across posts. Occasional repetition is fine
         and normal; don't force awkward phrasing just to avoid it.
      3. Vary how you open that line - don't default to directly addressing "remote workers" or
         "remote devs" every time, even though that fits the audience. Mix it up across posts:
         sometimes address them directly, sometimes address everyone generally, sometimes lead with
         a plain imperative ("Join fellow devs for...") with no direct address at all, as some of
         the examples below do.
      4. If a food truck is given below, add it as exactly two lines: "This week's food truck:
         <name> <emoji>" where <emoji> is a single emoji matching that truck's actual cuisine
         (sushi -> 🍣, tacos -> 🌮, BBQ/grill -> 🔥, pizza -> 🍕, etc.), followed by a short punchy
         description line ending in a hyphen-separated hook, e.g. "Fresh handrolls and sushi - the
         Boulder lunch you deserve!".
      5. End with a sign-off ending in "🧑‍💻👩‍💻👨‍💻" (extra emoji flourish okay).
      6. No links, no hashtags. Never use an em dash (—) anywhere in the text; use a hyphen (-), a
         comma, or a new sentence instead.
      7. Plain text only, roughly the same length as the examples (comfortably under Mastodon's
         500 character limit, a hard rule for every use of this text, not just the social posts).
      8. Separate every paragraph (the announcement line, the call to action, the food truck
         block, the sign-off) with one completely blank line, i.e. a real "\n\n" between them,
         exactly like the blank lines between paragraphs in the examples below. Do not run
         paragraphs together on consecutive single-newline lines, and do not use trailing spaces
         at the end of a line as a substitute for a blank line.

      ## Examples (voice and structure reference only - do not copy their call-to-action wording)

      #{rotating_examples.map.with_index(1) { |ex, i| "Example #{i}:\n#{ex}" }.join("\n\n")}

      ## Event details

      - Date: #{event.date}
      - Location: #{event.location_name}
      #{event.notes ? "- Notes: #{event.notes}" : ""}
      #{event.highlight ? "- Special occasion to call out: #{event.highlight}" : ""}
      #{food_truck_notes}

      Output only the announcement text, nothing else.
    PROMPT
  end

  def cancellation_prompt
    <<~PROMPT
      Write a short announcement that there is NO "Code && Coffee" developer meetup this week in
      Boulder, CO. This exact text will be used as the website's event page content AND posted
      verbatim to Mastodon and Slack, so it must work everywhere at once, in a tone similar to
      these real past (normal, non-cancellation) posts from the account, adapted for a "we're not
      meeting this week" message instead of a regular announcement:

      #{REAL_EXAMPLES.map.with_index(1) { |ex, i| "Example #{i}:\n#{ex}" }.join("\n\n")}

      Clearly state there is no Code && Coffee this week#{event.cancellation_reason ? " because of #{event.cancellation_reason}" : ""},
      and that everyone should come back next time. Keep it short and warm; a light pun is fine if
      it fits naturally, but don't force a joke if the reason sounds serious (e.g. bad weather,
      safety). End with a sign-off containing "🧑‍💻👩‍💻👨‍💻". No links, no hashtags. Never use an
      em dash (—) anywhere in the text; use a hyphen (-), a comma, or a new sentence instead. Plain
      text only, comfortably under Mastodon's 500 character limit.

      If the message spans more than one paragraph, separate paragraphs with one completely blank
      line (a real "\n\n"), never with trailing spaces at the end of a line.

      Event details:
      - Date this would have been: #{event.date}
      - Location this would normally be at: #{event.location_name}
      #{event.cancellation_reason ? "- Reason for cancellation: #{event.cancellation_reason}" : "- Reason for cancellation: not given"}

      Output only the announcement text, nothing else.
    PROMPT
  end

  def day_name
    Date.parse(event.date).strftime("%A")
  end

  # Shows a rotating 3-of-N sliding window of REAL_EXAMPLES per event date, so the
  # model isn't anchored on the same full example set (and its exact wording) every
  # week. Cycles through every combination as event dates advance.
  def rotating_examples
    size = REAL_EXAMPLES.size
    count = [3, size].min
    start = Date.parse(event.date).jd % size
    Array.new(count) { |i| REAL_EXAMPLES[(start + i) % size] }
  end

  def food_truck_notes
    breakfast, lunch = event.found_events
    truck = lunch&.found? ? lunch : breakfast
    return "" unless truck&.found?

    "- This week's food truck is called \"#{truck.summary}\". What it serves: #{truck.description}"
  end
end
