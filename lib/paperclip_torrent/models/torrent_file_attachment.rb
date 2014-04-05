module PaperclipTorrent
  class TorrentFileAttachment < ActiveRecord::Base
    include Paperclip::Glue
    
    scope :for, ->(attachment_name) { where({ attachment_instance: attachment_name }) }
    
    belongs_to :torrentable, polymorphic: true

    has_attached_file :attachment
    validates_attachment_content_type :attachment, content_type: "application/x-bittorrent"
  end
end