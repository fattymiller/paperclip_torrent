module Paperclip
  class Torrentify < Processor
    def initialize(file, options = {}, attachment = nil)
      @file       = file
      @options    = options
      @attachment = attachment
      @style_key  = @options[:style]
      @torrentify = !!@options[:torrentify]
      
      @options[:tracker] ||= attachment.options[:tracker]
      @options[:torrent_path] ||= attachment.options[:torrent_path]
    end
    
    def make
      # If no tracker is defined for this style, just return out and let other processors handle
      return @file if !@options[:tracker] || !@torrentify
      
      if !@style_key
        self.class.log "Unknown style key, skipping."
        return @file
      end
      
      self.class.log "Creating torrent file: #{@style_key}"
      
      torrent_file = nil

      begin
        torrent_file = PaperclipTorrent::TorrentFile.create_for(@file, @options, @attachment)
        self.class.log "  torrent file created"

        @attachment.add_torrent_result(@style_key, torrent_file)
        self.class.log "  pending torrent files: #{@attachment.torrent_results.keys.count}"
      rescue => e
        raise Paperclip::Error, "error creating torrent file for #{File.basename(@file.path)}: #{e}"
      end

      @file # don't return the torrent file here, this will just make future processing impossible
    end

    def self.log(message)
      Paperclip.log "[torrentify] #{message}"
    end
  end
  
  class Attachment
    def torrent_results
      @torrent_results ||= default_torrent_results
    end
    
    def torrent_file(torrent_key)
      instance.torrent_files.for(name).where({ torrent_key: torrent_key }).first if torrent_key && instance.respond_to?(:torrent_files)
    end

    def add_torrent_result(key, torrent_file)
      torrent_results[key] = { torrent_file: torrent_file, dirty: true }
    end
    
    def persist_torrents
      return unless instance.respond_to?(:torrent_files)
      
      torrent_results.each do |key, result|
        file = result[:torrent_file]
        dirty = result[:dirty]
        next unless file && dirty
        
        torrent_file_record = instance.torrent_files.for(name).where({ torrent_key: key }).first_or_create
        torrent_file_record.attachment = file.save
        torrent_file_record.save!
        
        result[:dirty] = false
      end
      
      true
    end
    
    private
    
    def default_torrent_results
      result = {}
      instance.torrent_files.for(name).select(:torrent_key).collect(&:torrent_key).each { |key| result[key] = { torrent_file: nil, dirty: false } } if instance.respond_to?(:torrent_files)
      
      result
    end
  end
end