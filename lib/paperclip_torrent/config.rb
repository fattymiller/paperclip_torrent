module PaperclipTorrent
  class Config
    include Singleton

    def self.settings
      instance.settings
    end
    def settings
      @settings ||= default_settings
    end
    
    private
    
    def default_settings
      {
        torrent_path: ":fingerprint/:style/:filename",
        default_piece_size: 256.kilobytes
      }
    end
    
  end  
end