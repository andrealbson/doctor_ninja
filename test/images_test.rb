# encoding: UTF-8
require "minitest/autorun"
require "doctor_ninja"
require "phashion"

class ImagesTest < MiniTest::Test
  def test_normal_image
    test_image "test/fixtures/img.docx", "test/fixtures/img.html"
  end
  
  def test_cropped_image
    test_image "test/fixtures/img_crop.docx", "test/fixtures/img_crop.html"
  end
  private

  def test_image docx_path, html_path
    doc = DoctorNinja::Document.new(docx_path)
    expected = Nokogiri::HTML(File.read(html_path))
    parser = DoctorNinja::Parser.new(doc)
    result = Nokogiri::HTML(parser.parse)

    with_image_from result do |result_img|
      with_image_from expected do |expected_img|
        assert(result_img.duplicate?(expected_img), "Image is not close enough")
      end
    end
  end

  def with_image_from htmldoc
    img = Tempfile.new(["image",".png"])
    img.close
    File.open(img.path, "wb") do |f|
      f.write Base64.decode64 htmldoc.xpath("//img").attribute("src").value.split(";base64,").last
    end
    yield Phashion::Image::new img.path
    img.unlink
  end
end
