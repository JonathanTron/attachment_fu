require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))
require 'ruby-debug'

class PdfAttachmentTest < Test::Unit::TestCase
  def test_should_create_thumbnail_with_png_type
    attachment_model PdfWithThumbsAttachment

    attachment = upload_file :filename => '/files/rails.pdf', :content_type => 'pdf'

    attachment.create_or_update_thumbnail(attachment.create_temp_file, 'thumb', 50, 50)
    attachment.save!

    thumbnail = attachment.thumbnails.first
    assert_equal 'pdf', attachment.content_type    
    assert_equal 'image/png', thumbnail.content_type
  end
  
  
  def test_should_correctly_set_width_height_when_thumbnailing_disabled
    attachment_model PdfWithoutThumbsAttachment

    attachment = upload_file :filename => '/files/rails.pdf', :content_type => 'pdf'
    attachment.save!

    assert_not_nil attachment.width
    assert_not_nil attachment.height
  end

  def test_should_correctly_set_width_height_with_crop_box_disabled
    attachment_model PdfWithoutThumbsWithoutCropboxAttachment

    attachment = upload_file :filename => '/files/rails_crop_box.pdf', :content_type => 'pdf'
    attachment.save!

    assert_equal 50, attachment.width
    assert_equal 64, attachment.height
  end

  def test_should_correctly_set_width_height_with_crop_box_enabled
    attachment_model PdfWithoutThumbsWithCropboxAttachment

    attachment = upload_file :filename => '/files/rails_crop_box.pdf', :content_type => 'pdf'
    attachment.save!

    assert_equal 45, attachment.width
    assert_equal 60, attachment.height
  end
  
  def test_should_skip_set_width_height_with_skip_width_height_enabled
    attachment_model PdfWithoutThumbsWithSkipWidthHeightAttachment

    attachment = upload_file :filename => '/files/rails_crop_box.pdf', :content_type => 'pdf'
    attachment.save!

    assert_nil attachment.width
    assert_nil attachment.height
  end
end