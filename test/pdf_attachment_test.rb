require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class PdfAttachmentTest < Test::Unit::TestCase
  attachment_model PdfWithThumbsAttachment
  
  

  def test_should_create_thumbnail_with_png_type
    attachment = upload_file :filename => '/files/rails.pdf', :content_type => 'pdf'

    attachment.create_or_update_thumbnail(attachment.create_temp_file, 'thumb', 50, 50)
    attachment.save!

    thumbnail = attachment.thumbnails.first
    assert_equal 'pdf', attachment.content_type    
    assert_equal 'image/png', thumbnail.content_type
    
    
  end
  
  
end