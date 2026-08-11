# frozen_string_literal: true

require "date"

# Builds the AI prompt text for an event's announcement, voice matched to
# real past posts from https://ruby.social/@codencoffee. See EventContentService.
class EventPromptBuilder
  # Few-shot examples from the account's real post history. Deliberately all
  # "no hook line" posts, since only 1 of the 15 most recent real posts had one.
  REAL_EXAMPLES = [
    <<~EXAMPLE1.strip,
      💻️☕️️ Code && Coffee is tomorrow (Wednesday) at The Rayback - 8am start!

      Remote devs, time to get out! Join fellow engineers for coffee, coding, and connection until whenever.

      This week's food truck: Temaki Tornado 🍣
      Fresh handrolls and sushi - the Boulder lunch you deserve!

      See you there! 🧑‍💻👩‍💻👨‍💻
    EXAMPLE1
    <<~EXAMPLE2.strip,
      💻️☕️️ Code && Coffee is tomorrow (Wednesday) at The Rayback - 8am start!

      Remote workers, ditch the home office! Join us for coffee, coding, and community until whenever.

      This week's food truck: Salt Fire Chile 🌮🌶️
      Elevated tacos with bold flavors and fresh ingredients - come hungry!

      See you there! 🧑‍💻👩‍💻👨‍💻
    EXAMPLE2
    <<~EXAMPLE3.strip
      💻️☕️️ Code && Coffee is BACK tomorrow (Wednesday) at The Rayback - 8am start!

      🎉 First meetup of 2026! 🎉 Remote workers, kick off the new year right! Join fellow devs for coffee, coding, and community until whenever.

      This week's food truck: Temaki Tornado 🍣
      Fresh handrolls and sushi to fuel your fresh start!

      Happy New Year! See you there! 🧑‍💻👩‍💻👨‍💻✨️
    EXAMPLE3
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
      Mastodon and Slack, so it must work everywhere at once, in the exact voice of these real
      past posts from the account:

      #{REAL_EXAMPLES.map.with_index(1) { |ex, i| "Example #{i}:\n#{ex}" }.join("\n\n")}

      Match that structure exactly: start directly with the fixed announcement line "💻☕️ Code &&
      Coffee is tomorrow (#{day_name}) at #{event.location_name} - 8am start!" (do NOT add a punny
      opening hook line before it, that's not the normal pattern), then a one-line call to action
      encouraging remote workers to come hang out, then a food truck line if one is given below,
      then a sign-off ending in "🧑‍💻👩‍💻👨‍💻" (extra emoji flourish okay). No links, no hashtags.
      Never use an em dash (—) anywhere in the text; use a hyphen (-), a comma, or a new sentence
      instead. Plain text only, roughly the same length as the examples (comfortably under
      Mastodon's 500 character limit, a hard rule for every use of this text, not just the social
      posts).

      Formatting is as strict a rule as the character limit: separate every paragraph (the
      announcement line, the call to action, the food truck block, the sign-off) with one
      completely blank line, i.e. a real "\n\n" between them, exactly like the blank lines between
      paragraphs in the examples above. Do not run paragraphs together on consecutive single-newline
      lines, and do not use trailing spaces at the end of a line as a substitute for a blank line.

      If a food truck is given below, format that part as exactly two lines: "This week's food
      truck: <name> <emoji>" where <emoji> is a single emoji matching that truck's actual cuisine
      (sushi -> 🍣, tacos -> 🌮, BBQ/grill -> 🔥, pizza -> 🍕, etc.), followed by a short punchy
      description line ending in a hyphen-separated hook, e.g. "Fresh handrolls and sushi - the
      Boulder lunch you deserve!".

      Event details:
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

  def food_truck_notes
    breakfast, lunch = event.found_events
    truck = lunch&.found? ? lunch : breakfast
    return "" unless truck&.found?

    "- This week's food truck is called \"#{truck.summary}\". What it serves: #{truck.description}"
  end
end
