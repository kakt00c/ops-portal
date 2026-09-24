require "test_helper"

class Issues::DraftTest < ActiveSupport::TestCase
  test "load_geo_from_exif does not set coordinates when GPS contains NaN values" do
    user = users(:one)
    draft = Issues::Draft.create!(author: user)

    # Attach a fake photo
    draft.photos.attach(io: StringIO.new("fake image"), filename: "photo.jpg", content_type: "image/jpeg")
    photo = draft.photos.first

    # Mock Exif::Data to return GPS with NaN values (Android empty GPS edge case)
    exif_data_mock = Minitest::Mock.new
    gps_data = {
      gps_latitude: [ Float::NAN, Float::NAN, Float::NAN ],
      gps_longitude: [ Float::NAN, Float::NAN, Float::NAN ]
    }
    exif_data_mock.expect(:[], gps_data, [ :gps ])

    Exif::Data.stub :new, exif_data_mock do
      draft.load_geo_from_exif(photo)
    end

    assert_nil draft.latitude, "Latitude should not be set when GPS contains NaN"
    assert_nil draft.longitude, "Longitude should not be set when GPS contains NaN"
    assert_not draft.latlon_from_exif

    exif_data_mock.verify
  end
end
