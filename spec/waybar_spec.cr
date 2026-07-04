require "./spec_helper"
require "file_utils"

# Reopen WaybarNotifier in tests to mock system calls
class Salamander::WaybarNotifier
  class_property waybar_updates = 0
  class_property notifications = [] of String

  private def update_waybar
    @@waybar_updates += 1
  end

  def notify(title : String, message : String)
    @@notifications << "#{title}: #{message}"
  end
end

describe Salamander::WaybarNotifier do
  # Track temporary files for cleanup
  test_files = [] of String

  after_each do
    test_files.each do |file|
      File.delete(file) if File.exists?(file)
    end
    test_files.clear

    # Reset mock class state
    Salamander::WaybarNotifier.waybar_updates = 0
    Salamander::WaybarNotifier.notifications.clear
  end

  describe "#initialize" do
    it "creates an instance without error" do
      notifier = Salamander::WaybarNotifier.new("🐾", "")
      notifier.should be_a(Salamander::WaybarNotifier)
    end
  end

  describe "#start and #update" do
    it "writes the correct mapped status to the status file" do
      temp_status_file = File.tempname("waybar_status", ".txt")
      test_files << temp_status_file

      notifier = Salamander::WaybarNotifier.new("🐾", temp_status_file)
      notifier.start

      # Yield to allow fibers to run deterministically
      Fiber.yield

      File.exists?(temp_status_file).should be_true
      File.read(temp_status_file).should eq("Idle")

      # Test update to :thinking
      notifier.update(:thinking)
      Fiber.yield
      File.read(temp_status_file).should eq("Thinking")
      Salamander::WaybarNotifier.waybar_updates.should be > 0

      # Test update to :evaluating
      notifier.update(:evaluating)
      Fiber.yield
      File.read(temp_status_file).should eq("Loading/Working")
    end
  end

  describe "#notify" do
    it "mock handles notification calls" do
      notifier = Salamander::WaybarNotifier.new("🐾", "")

      notifier.notify("Test Title", "Test Message")
      Fiber.yield
      Salamander::WaybarNotifier.notifications.should contain("Test Title: Test Message")
    end
  end
end
