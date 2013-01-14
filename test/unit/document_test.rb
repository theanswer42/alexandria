require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  def setup
    FileUtils.rm_rf(BASE_PATH, :secure => true)
    FileUtils.mkdir(BASE_PATH)
  end
  
  def test_import
    file = Rails.root.join('test', 'files', 'DSC_0001.JPG').to_s
    result = {}
    Document.import!(file, ['tag1'], :result => result)
    imported_document = Document.first

    assert imported_document.is_a?(Photo)
    assert_equal 'DSC_0001', imported_document.name
    assert_equal '9b48487e060abb5424391b0f1ddad09e0e920046', imported_document.checksum
    assert_equal '9b48487e060abb5424391b0f1ddad09e0e920046.jpg', File.basename(imported_document.library_filename)
    assert_equal "2012-10-29 23:02:38", imported_document.timestamp.to_s(:db)

    assert_equal 3872, imported_document.photo_information.exif_data[:width]
    assert_equal 2592, imported_document.photo_information.exif_data[:height]
    
    assert_equal imported_document.photo_information.roll.started_at, imported_document.timestamp
    assert_equal imported_document.photo_information.roll.finished_at, imported_document.timestamp
  end

  def test_import_directory
    directory = Rails.root.join('test', 'files', 'tag1').to_s
    result = {}
    result = Document.import_directory(directory, ['tag55'])
    assert_equal 1, result[:total]
    assert_equal 0, result[:errors]
    assert_equal 0, result[:skipped].length
    imported_document = Document.last
    
    assert_equal 'DSC_0003', imported_document.name
    assert_equal ['tag55', 'tag2'].sort, imported_document.tag_list.sort
    
    result = {}
    result = Document.import_directory(directory, ['tag55'])
    assert_equal 1, result[:total]
    assert_equal 0, result[:errors]
    assert_equal 1, result[:skipped].length
    assert_equal 1, Document.count
  end
end
