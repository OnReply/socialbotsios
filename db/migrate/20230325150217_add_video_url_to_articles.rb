class AddVideoUrlToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :video_url, :string, default: ''
  end
end
