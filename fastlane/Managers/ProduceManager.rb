# frozen_string_literal: true

class ProduceManager
  def initialize(fastlane:)
    @fastlane = fastlane
  end

  def create_app_identifier(username:, app_identifier:, app_name:, team_name:, skip_itc:)
    @fastlane.produce(
      username: username,
      app_identifier: app_identifier,
      app_name: app_name,
      team_name: team_name,
      skip_itc: skip_itc,
      enable_services: {
        push_notification: "on"
      }
    )
  end
end
