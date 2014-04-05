module PaperclipTorrent
  module Torrentable
    extend ActiveSupport::Concern
    
    included do
      after_save :persist_torrent_files

      has_many :torrent_files, class_name: "PaperclipTorrent::TorrentFileAttachment", as: :torrentable      

      private 
      
      def persist_torrent_files
        self.class.attachment_definitions.keys.each { |field_name| send(field_name).persist_torrents }
      end
    end
  end
end