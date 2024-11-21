class AddPostgis < ActiveRecord::Migration[7.1]
  def change
    # system('brew install postgis')
    enable_extension "postgis"
  end
end
