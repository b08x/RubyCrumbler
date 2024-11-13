#!/usr/bin/env ruby

module Crumbler
  module GUI
    module Components
      class InputSection
        include Glimmer

        attr_reader :lang, :input, :projectname, :doc, :processing_options

        def initialize
          @lang = 'EN'
          @processing_options = Components::ProcessingOptions.new
        end

        def create
          horizontal_box do
            stretchy false
            vertical_box do
              create_language_selection
              create_upload_center
            end
            create_processing_options_box
          end
        end

        private

        def create_language_selection
          group('Language of Text Input') do
            stretchy false
            vertical_box do
              label("Please specify the language in which your input text data is written.\n" \
              "Note: This information is mandatory to run the program.\n") { stretchy false }

              combobox do
                stretchy false
                items 'English', 'German'
                selected 'English'

                on_selected do |c|
                  @lang = if c.selected_item == 'English'
                            'EN'
                          else
                            'DE'
                          end
                end
              end
              label
            end
          end
        end

        def create_upload_center
          group('Upload Center') do
            stretchy false
            vertical_box do
              label("Choose a file(s) or a directory, or specify a URL whose text content should be used to upload.\n" \
              "Note: Total file size may not exceed 50MB. File type must be TXT.\n") do
                stretchy false
              end
              create_file_upload_button
              create_directory_upload_button
              create_url_upload_section
            end
          end
        end

        def create_file_upload_button
          button('Upload from file(s)') do
            stretchy false
            on_clicked do
              file = open_file
              if file.nil?
                msg_box('ERROR: No File selected.')
              else
                @input = file
                @projectname = File.basename(@input, '.*')
                @doc = Crumbler::Pipeline::Features.new
                puts @input unless file.nil?
                @doc.newproject(@input, @projectname)
                msg_box('Notification', 'Upload successfully completed.')
              end
            end
          end
        end

        def create_directory_upload_button
          button('Upload file(s) from directory') do
            stretchy false
            on_clicked do
              dir = Tk.chooseDirectory
              @input = dir
              @projectname = File.basename(@input, '.*')
              @projectname = "#{@projectname}_process"
              if @projectname == '_process'
                msg_box('ERROR: No Folder selected.')
              else
                @doc = Crumbler::Pipeline::Features.new
                @doc.newproject(@input, @projectname)
                msg_box('Notification', 'Upload successfully completed.')
              end
            end
          end
        end

        def create_url_upload_section
          label("\nEnter URL:") { stretchy false }
          @entry = entry do
            stretchy false
            on_changed do
              @url = @entry.text
            end
          end
          button('Upload text from website') do
            stretchy false
            on_clicked do
              @input = @url
              if @input.nil?
                msg_box('ERROR: No URL selected.')
              else
                @projectname = File.basename(@input, '.*')
                @doc = Crumbler::Pipeline::Features.new
                puts @input unless @input.nil?
                @doc.newproject(@input, @projectname)
                msg_box('Notification', 'Upload successfully completed.')
              end
            end
          end
        end

        def create_processing_options_box
          vertical_box do
            @processing_options.create(self)
          end
        end
      end
    end
  end
end
