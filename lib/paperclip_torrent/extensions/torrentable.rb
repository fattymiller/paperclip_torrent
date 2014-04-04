module PaperclipTorrent
  module Torrentable
    extend ActiveSupport::Concern
    
    included do
      after_save :persist_torrent_files

      has_many :torrent_files, class_name: "PaperclipTorrent::TorrentFileAttachment", as: :torrentable      

      def torrentable_fields
        @torrentable_fields ||= []
      end
      def add_torrentable_field(field_name)
        torrentable_fields << field_name if !torrentable_fields.include?(field_name)
      end
      
      private 
      
      def persist_torrent_files
        torrentable_fields.uniq.each { |field_name| self.respond_to?(field_name) && send(field_name).persist_torrents }
      end
    end
  end
end