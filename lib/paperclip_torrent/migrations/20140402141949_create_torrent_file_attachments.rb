class CreateTorrentFileAttachments < ActiveRecord::Migration
  def change
    create_table :torrent_file_attachments do |t|
      t.string :torrentable_type
      t.integer :torrentable_id
      
      t.string :torrent_key
      
      t.attachment :attachment

      t.timestamps
    end
  end
end
