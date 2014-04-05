class AddAttachmentInstanceToTorrentFileAttachment < ActiveRecord::Migration
  def change
    add_column :torrent_file_attachments, :attachment_instance, :string
  end
end