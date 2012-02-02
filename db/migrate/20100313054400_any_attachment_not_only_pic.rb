class AnyAttachmentNotOnlyPic < ActiveRecord::Migration
  def self.up
    rename_column :cards, :pic_content_type, :attachment_content_type
    rename_column :cards, :pic_updated_at, :attachment_updated_at
    rename_column :cards, :pic_file_name, :attachment_file_name
    rename_column :cards, :pic_file_size, :attachment_file_size
  end

  def self.down
    rename_column :cards, :attachment_content_type, :pic_content_type
    rename_column :cards, :attachment_updated_at, :pic_updated_at
    rename_column :cards, :attachment_file_name, :pic_file_name
    rename_column :cards, :attachment_file_size, :pic_file_size
  end
end
