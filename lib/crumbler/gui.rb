#!/usr/bin/env ruby

require_relative 'gui/menu_bar'
require_relative 'gui/input_section'
require_relative 'gui/processing_options'
require_relative 'gui/run_section'

module Crumbler
  module GUI
    class CrumblerGUI
      include Glimmer
      include Crumbler::Pipeline

      def initialize
        ProgressBar.create
        @menu_bar = Components::MenuBar.new
        @input_section = Components::InputSection.new
      end

      def launch
        @menu_bar.create
        create_main_window
      end

      private

      def create_main_window
        window('Crumbler', 300, 800) do
          margined(true)
          vertical_box do
            @input_section.create
            horizontal_separator { stretchy false }
            create_run_section
          end
        end.show
      end

      def create_run_section
        @run_section = Components::RunSection.new(@input_section, @input_section.processing_options)
        @run_section.create
      end
    end
  end
end
