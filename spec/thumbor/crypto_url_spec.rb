require 'spec_helper'
require 'json'
require 'ruby-thumbor'
require 'util/thumbor'

image_url = 'my.domain.com/some/image/url.jpg'
image_md5 = 'f33af67e41168e80fcc5b00f8bd8061a'
key = 'my-security-key'

describe Thumbor::CryptoURL do
  subject { Thumbor::CryptoURL.new key }

  describe '#new' do
    it "should create a new instance passing key and keep it" do
      subject.computed_key.should == 'my-security-keym'
    end
  end

  describe '#url_for' do

    it "should return just the image hash if no arguments passed" do
      url = subject.url_for :image => image_url
      url.should == image_md5
    end

    it "should raise if no image passed" do
      expect { subject.url_for Hash.new }.to raise_error(RuntimeError)
    end

    it "should return proper url for width-only" do
      url = subject.url_for :image => image_url, :width => 300
      url.should == '300x0/' << image_md5
    end

    it "should return proper url for height-only" do
      url = subject.url_for :image => image_url, :height => 300
      url.should == '0x300/' << image_md5
    end

    it "should return proper url for width and height" do
      url = subject.url_for :image => image_url, :width => 200, :height => 300
      url.should == '200x300/' << image_md5
    end

    it "should return proper smart url" do
      url = subject.url_for :image => image_url, :width => 200, :height => 300, :smart => true
      url.should == '200x300/smart/' << image_md5
    end

    it "should return proper fit-in url" do
      url = subject.url_for :image => image_url, :width => 200, :height => 300, :fit_in => true
      url.should == 'fit-in/200x300/' << image_md5
    end

    it "should return proper flip url if no width and height" do
      url = subject.url_for :image => image_url, :flip => true
      url.should == '-0x0/' << image_md5
    end

    it "should return proper flop url if no width and height" do
      url = subject.url_for :image => image_url, :flop => true
      url.should == '0x-0/' << image_md5
    end

    it "should return proper flip-flop url if no width and height" do
      url = subject.url_for :image => image_url, :flip => true, :flop => true
      url.should == '-0x-0/' << image_md5
    end

    it "should return proper flip url if width" do
      url = subject.url_for :image => image_url, :width => 300, :flip => true
      url.should == '-300x0/' << image_md5
    end

    it "should return proper flop url if height" do
      url = subject.url_for :image => image_url, :height => 300, :flop => true
      url.should == '0x-300/' << image_md5
    end

    it "should return horizontal align" do
      url = subject.url_for :image => image_url, :halign => :left
      url.should == 'left/' << image_md5
    end

    it "should not return horizontal align if it is center" do
      url = subject.url_for :image => image_url, :halign => :center
      url.should == image_md5
    end

    it "should return vertical align" do
      url = subject.url_for :image => image_url, :valign => :top
      url.should == 'top/' << image_md5
    end

    it "should not return vertical align if it is middle" do
      url = subject.url_for :image => image_url, :valign => :middle
      url.should == image_md5
    end

    it "should return halign and valign properly" do
      url = subject.url_for :image => image_url, :halign => :left, :valign => :top
      url.should == 'left/top/' << image_md5
    end

    it "should return meta properly" do
      url = subject.url_for :image => image_url, :meta => true
      url.should == 'meta/' << image_md5
    end

    it "should return proper crop url" do
      url = subject.url_for :image => image_url, :crop => [10, 20, 30, 40]
      url.should == '10x20:30x40/' << image_md5
    end

    it "should ignore crop if all zeros" do
      url = subject.url_for :image => image_url, :crop => [0, 0, 0, 0]
      url.should == image_md5
    end

    it "should have smart after halign and valign" do
      url = subject.url_for :image => image_url, :halign => :left, :valign => :top, :smart => true
      url.should == 'left/top/smart/' << image_md5
    end

    it "should ignore filters if empty" do
      url = subject.url_for :image => image_url, :filters => []
      url.should == image_md5
    end

    it "should have trim without params" do
      url = subject.url_for :image => image_url, :trim => true
      url.should == 'trim/' << image_md5
    end

    it "should have trim with direction param" do
      url = subject.url_for :image => image_url, :trim => ['bottom-right']
      url.should == 'trim:bottom-right/' << image_md5
    end

    it "should have trim with direction and tolerance param" do
      url = subject.url_for :image => image_url, :trim => ['bottom-right', 15]
      url.should == 'trim:bottom-right:15/' << image_md5
    end

    it "should have the right crop when cropping horizontally and given a left center" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => 40, :height => 50, :center => [0, 50]
      url.should == '0x0:80x100/40x50/' << image_md5
    end

    it "should have the right crop when cropping horizontally and given a right center" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => 40, :height => 50, :center => [100, 50]
      url.should == '20x0:100x100/40x50/' << image_md5
    end

    it "should have the right crop when cropping horizontally and given the actual center" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => 40, :height => 50, :center => [50, 50]
      url.should == '10x0:90x100/40x50/' << image_md5
    end

    it "should have the right crop when cropping vertically and given a top center" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => 50, :height => 40, :center => [50, 0]
      url.should == '0x0:100x80/50x40/' << image_md5
    end

    it "should have the right crop when cropping vertically and given a bottom center" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => 50, :height => 40, :center => [50, 100]
      url.should == '0x20:100x100/50x40/' << image_md5
    end

    it "should have the right crop when cropping vertically and given the actual center" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => 50, :height => 40, :center => [50, 50]
      url.should == '0x10:100x90/50x40/' << image_md5
    end

    it "should have the no crop when not necessary" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => 50, :height => 50, :center => [50, 0]
      url.should == '50x50/' << image_md5
    end

    it "should blow up with a bad center" do
      expect { subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => 50, :height => 40, :center => 50 }.to raise_error(RuntimeError)
    end

    it "should have no crop with a missing original_height" do
      url = subject.url_for :image => image_url, :original_width => 100, :width => 50, :height => 40, :center => [50, 50]
      url.should == '50x40/' << image_md5
    end

    it "should have no crop with a missing original_width" do
      url = subject.url_for :image => image_url, :original_height => 100, :width => 50, :height => 40, :center => [50, 50]
      url.should == '50x40/' << image_md5
    end

    it "should have no crop with out a width and height" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :center => [50, 50]
      url.should == image_md5
    end

    it "should use the original width with a missing width" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :height => 80, :center => [50, 50]
      url.should == '0x10:100x90/0x80/' << image_md5
    end

    it "should use the original height with a missing height" do
      url = subject.url_for :image => image_url,:original_width => 100, :original_height => 100, :width => 80, :center => [50, 50]
      url.should == '10x0:90x100/80x0/' << image_md5
    end

    it "should have the right crop with a negative width" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => -50, :height => 40, :center => [50, 50]
      url.should == '0x10:100x90/-50x40/' << image_md5
    end

    it "should have the right crop with a negative height" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => 50, :height => -40, :center => [50, 50]
      url.should == '0x10:100x90/50x-40/' << image_md5
    end

    it "should have the right crop with a negative height and width" do
      url = subject.url_for :image => image_url, :original_width => 100, :original_height => 100, :width => -50, :height => -40, :center => [50, 50]
      url.should == '0x10:100x90/-50x-40/' << image_md5
    end
  end

  describe '#generate' do
    it "should generate a proper url when only an image url is specified" do
      url = subject.generate :image => image_url

      url.should == "/964rCTkAEDtvjy_a572k7kRa0SU=/#{image_url}"
    end

    it "should create a new instance passing key and keep it" do
      url = subject.generate :width => 300, :height => 200, :image => image_url

      url.should == '/TQfyd3H36Z3srcNcLOYiM05YNO8=/300x200/my.domain.com/some/image/url.jpg'
    end

    it "should create a new instance passing key and keep it" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url

      url.should == '/YBQEWd3g_WRMnVEG73zfzcr8Zj0=/meta/300x200/my.domain.com/some/image/url.jpg'
    end

    it "should create a new instance passing key and keep it" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :smart => true

      url.should == '/jP89J0qOWHgPlm_lOA28GtOh5GU=/meta/300x200/smart/my.domain.com/some/image/url.jpg'
    end

    it "should create a new instance passing key and keep it" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :smart => true, :fit_in => true

      url.should == '/zrrOh_TtTs4kiLLEQq1w4bcTYdc=/meta/fit-in/300x200/smart/my.domain.com/some/image/url.jpg'
    end

    it "should create a new instance passing key and keep it" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :smart => true, :fit_in => true, :flip => true

      url.should == '/4t1XK1KH43cOb1QJ9tU00-W2_k8=/meta/fit-in/-300x200/smart/my.domain.com/some/image/url.jpg'
    end

    it "should create a new instance passing key and keep it" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :smart => true, :fit_in => true, :flip => true, :flop => true

      url.should == '/HJnvjZU69PkPOhyZGu-Z3Uc_W_A=/meta/fit-in/-300x-200/smart/my.domain.com/some/image/url.jpg'
    end

    it "should create a new instance passing key and keep it" do
      url = subject.generate :filters => ["quality(20)", "brightness(10)"], :image => image_url

      url.should == '/q0DiFg-5-eFZIqyN3lRoCvg2K0s=/filters:quality(20):brightness(10)/my.domain.com/some/image/url.jpg'
    end
  end

  describe "#generate :old => true" do

    it "should create a new instance passing key and keep it" do
      url = subject.generate :width => 300, :height => 200, :image => image_url, :old => true

      url.should == '/qkLDiIbvtiks0Up9n5PACtmpOfX6dPXw4vP4kJU-jTfyF6y1GJBJyp7CHYh1H3R2/' << image_url
    end

    it "should allow thumbor to decrypt it properly" do
      url = subject.generate :width => 300, :height => 200, :image => image_url, :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["horizontal_flip"].should == false
      decrypted["vertical_flip"].should == false
      decrypted["smart"].should == false
      decrypted["meta"].should == false
      decrypted["fit_in"].should == false
      decrypted["crop"]["left"].should == 0
      decrypted["crop"]["top"].should == 0
      decrypted["crop"]["right"].should == 0
      decrypted["crop"]["bottom"].should == 0
      decrypted["valign"].should == 'middle'
      decrypted["halign"].should == 'center'
      decrypted["image_hash"].should == image_md5
      decrypted["width"].should == 300
      decrypted["height"].should == 200

    end

    it "should allow thumbor to decrypt it properly with meta" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["meta"].should == true
      decrypted["image_hash"].should == image_md5
      decrypted["width"].should == 300
      decrypted["height"].should == 200

    end

    it "should allow thumbor to decrypt it properly with smart" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :smart => true, :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["meta"].should == true
      decrypted["smart"].should == true
      decrypted["image_hash"].should == image_md5
      decrypted["width"].should == 300
      decrypted["height"].should == 200

    end

    it "should allow thumbor to decrypt it properly with fit-in" do
      url = subject.generate :width => 300, :height => 200, :fit_in => true, :image => image_url, :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["fit_in"].should == true
      decrypted["image_hash"].should == image_md5
      decrypted["width"].should == 300
      decrypted["height"].should == 200

    end

    it "should allow thumbor to decrypt it properly with flip" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :smart => true, :flip => true, :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["meta"].should == true
      decrypted["smart"].should == true
      decrypted["image_hash"].should == image_md5
      decrypted["width"].should == 300
      decrypted["height"].should == 200
      decrypted["flip_horizontally"] == true

    end

    it "should allow thumbor to decrypt it properly with flop" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :smart => true, :flip => true, :flop => true, :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["meta"].should == true
      decrypted["smart"].should == true
      decrypted["image_hash"].should == image_md5
      decrypted["width"].should == 300
      decrypted["height"].should == 200
      decrypted["flip_horizontally"] == true
      decrypted["flip_vertically"] == true

    end

    it "should allow thumbor to decrypt it properly with halign" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :smart => true, :flip => true, :flop => true,
      :halign => :left, :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["meta"].should == true
      decrypted["smart"].should == true
      decrypted["image_hash"].should == image_md5
      decrypted["width"].should == 300
      decrypted["height"].should == 200
      decrypted["flip_horizontally"] == true
      decrypted["flip_vertically"] == true
      decrypted["halign"] == "left"

    end

    it "should allow thumbor to decrypt it properly with valign" do
      url = subject.generate :width => 300, :height => 200, :meta => true, :image => image_url, :smart => true, :flip => true, :flop => true,
      :halign => :left, :valign => :top, :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["meta"].should == true
      decrypted["smart"].should == true
      decrypted["image_hash"].should == image_md5
      decrypted["width"].should == 300
      decrypted["height"].should == 200
      decrypted["flip_horizontally"] == true
      decrypted["flip_vertically"] == true
      decrypted["halign"] == "left"
      decrypted["valign"] == "top"

    end

    it "should allow thumbor to decrypt it properly with cropping" do
      url = subject.generate :width => 300, :height => 200, :image => image_url, :crop => [10, 20, 30, 40], :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["horizontal_flip"].should == false
      decrypted["vertical_flip"].should == false
      decrypted["smart"].should == false
      decrypted["meta"].should == false
      decrypted["crop"]["left"].should == 10
      decrypted["crop"]["top"].should == 20
      decrypted["crop"]["right"].should == 30
      decrypted["crop"]["bottom"].should == 40
      decrypted["valign"].should == 'middle'
      decrypted["halign"].should == 'center'
      decrypted["image_hash"].should == image_md5
      decrypted["width"].should == 300
      decrypted["height"].should == 200

    end

    it "should allow thumbor to decrypt it properly with filters" do
      url = subject.generate :filters => ["quality(20)", "brightness(10)"], :image => image_url, :old => true

      encrypted = url.split('/')[1]

      decrypted = decrypt_in_thumbor(encrypted)

      decrypted["filters"].should == "quality(20):brightness(10)"
    end
  end
end
