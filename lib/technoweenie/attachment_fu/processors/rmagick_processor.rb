require 'RMagick'
module Technoweenie # :nodoc:
  module AttachmentFu # :nodoc:
    module Processors
      module RmagickProcessor
        def self.included(base)
          base.send :extend, ClassMethods
          base.alias_method_chain :process_attachment, :processing
        end

        module ClassMethods
          # Yields a block containing an RMagick Image for the given binary data.
          def with_image(file, &block)
            begin
              # Workaround block scope for RMagick infos settings
              crop_box = attachment_options[:pdf_size_use_crop_box]
              binary_data = file.is_a?(Magick::Image) ? file : Magick::Image.ping(file){ self['pdf:use-cropbox'] = crop_box }.first unless !Object.const_defined?(:Magick)
            rescue
              # Log the failure to load the image.  This should match ::Magick::ImageMagickError
              # but that would cause acts_as_attachment to require rmagick.
              logger.debug("Exception working with image: #{$!}")
              binary_data = nil
            end
            block.call binary_data if block && binary_data
          ensure
            !binary_data.nil?
          end
          
          def supports_pdf?
            true
          end
        end

      protected
        def process_file?
          !pdf? || (pdf? && !attachment_options[:pdf_skip_width_height])
        end

        def process_attachment_with_processing
          return if !process_attachment_without_processing || !process_file?
          with_image do |img|
            resize_image_or_thumbnail!(img) if image? || (pdf? && process_pdfs?)
            self.width  = img.columns if respond_to?(:width)
            self.height = img.rows    if respond_to?(:height)
            callback_with_args :after_resize, [self, img]
          end if image? || pdf?
        end

        # Performs the actual resizing operation for a thumbnail
        def resize_image(img, size)
          size = size.first if size.is_a?(Array) && size.length == 1 && !size.first.is_a?(Fixnum)
          if size.is_a?(Fixnum) || (size.is_a?(Array) && size.first.is_a?(Fixnum))
            size = [size, size] if size.is_a?(Fixnum)
            img.thumbnail!(*size)
          elsif size.is_a?(String) && size =~ /^c.*$/ # Image cropping - example geometry string: c75x75
            dimensions = size[1..size.size].split("x")
            img.crop_resized!(dimensions[0].to_i, dimensions[1].to_i)
          else
            img.change_geometry(size.to_s) { |cols, rows, image| image.resize!(cols<1 ? 1 : cols, rows<1 ? 1 : rows) }
          end
          img.strip! unless attachment_options[:keep_profile]
          if respond_to?(:parent) && parent && parent.pdf? && process_pdfs?
            output_format = 'PNG'
          else
            output_format = img.format
          end  
          temp_paths.unshift write_to_temp_file(img.to_blob {self.format = output_format})
        end
      end
    end
  end
end
