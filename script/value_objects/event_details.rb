# frozen_string_literal: true

require_relative "../services/webcal_event_finder_service"

# Data holder merging an events.yml entry with its locations.yml metadata.
EventDetails = Struct.new(
  :date,             # "YYYY-MM-DD"
  :location_name,
  :location_website,
  :notes,            # freeform notes from events.yml, may be nil
  :highlight,         # optional seasonal flourish, e.g. "First meetup of 2026!"
  :wifi_notes,        # from locations.yml, may be nil
  :found_events,      # [breakfast, lunch] WebcalEvent/NullWebcalEvent pair, defaults to two null events
  :cancelled,         # true for a skip/cancellation week, falsy otherwise
  :cancellation_reason, # freeform reason for a cancelled week (e.g. "Thanksgiving"), may be nil
  keyword_init: true
) do
  # @return [Array<WebcalEvent, NullWebcalEvent>] [breakfast, lunch] pair, defaulting to null events
  def found_events
    self[:found_events] || [NullWebcalEvent.new, NullWebcalEvent.new]
  end

  # @return [Boolean] true for a skip/cancellation week
  def cancelled?
    !!cancelled
  end
end
