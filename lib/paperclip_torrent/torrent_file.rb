require 'bencode'

module PaperclipTorrent
  class TorrentFile
    
    attr_accessor :tracker_url, :attachment, :attachment_style
    
    def self.create_for(file, options, paperclip_attachment)
      instance = self.new
      
      instance.tracker_url = options[:tracker]
      instance.piece_size = options[:piece_size]
      
      instance.source_file = file
      
      instance.attachment = paperclip_attachment
      instance.attachment_style = options[:style]
      instance.download_path_pattern = options[:torrent_path]
      
      instance
    end
    def self.open_from_file(filepath, options = {})
      options ||= {}
      
      instance = nil
      
      begin
        torrent_file_contents = open(filepath).read
        torrent_hash = BEncode.load(torrent_file_contents, ignore_trailing_junk: !!options[:ignore_trailing_junk])
      
        instance = self.new
        instance.existing_info = torrent_hash.delete("info")
        instance.existing_header = torrent_hash
        instance.current_save_path = filepath
      rescue => e
        instance = nil
      end
      
      instance
    end
    def self.open_from_attachment(attachment, style_key)
      file_attachment = attachment.torrent_file(style_key)
      return nil unless file_attachment
      
      instance = open_from_file(file_attachment.attachment.path)
      return nil unless instance
      
      instance.attachment = attachment
      instance.attachment_style = style_key
      
      instance
    end
    def self.open_from_torrent_file_attachment(file_attachment)
      torrentable = file_attachment.torrentable
      return nil unless torrentable
      
      attachment = torrentable.send(file_attachment.attachment_instance) if file_attachment.attachment_instance && torrentable.respond_to?(file_attachment.attachment_instance)
      return nil unless attachment
      
      open_from_attachment(attachment, file_attachment.torrent_key)
    end
    
    def source_file=(file)
      @source_file = file
      @source_file_hash = nil
      @filesize = nil
    end
    def source_file
      @source_file
    end
    
    def existing_header=(existing_header)
      self.tracker_url = existing_header.delete("announce")
      
      # "11\n12\n\n21\n22" => [[11,12], [21,22]]
      # [[11,12], [21,22]] => "['11\n12', '21\n22']" => "11\n12\n\n21\n22"

      announce_list = existing_header.delete("announce-list")
      self.tracker_url ||= announce_list.collect { |aa| aa.is_a?(Array) ? aa.reject(&:blank?).join(TorrentFile.tracker_seperator) : aa }.reject(&:blank?).join(TorrentFile.tracker_tier_seperator) if announce_list && announce_list.is_a?(Array)
      
      @existing_header = existing_header
    end
    def existing_info=(existing_info)
      @source_file = nil
      
      @source_file_hash = existing_info["pieces"]
      @filesize = existing_info["files"] ? existing_info["files"].first["length"] : existing_info["length"]
      
      path = [existing_info["name"]]
      path += existing_info["files"].first["path"] if existing_info["files"]
      @existing_torrent_download_path = path.compact.join(File::SEPARATOR)
    end
    
    def download_path=(path)
      @download_path = path
      
      @download_path_pattern = nil
      @existing_torrent_download_path = nil
    end
    def download_path
      @existing_torrent_download_path || @download_path || interpolated_download_path
    end

    def download_path_pattern=(pattern)
      @download_path_pattern = pattern
      
      @download_path = nil
      @existing_torrent_download_path = nil
    end
    def download_path_pattern
      @download_path_pattern || PaperclipTorrent::Config.settings[:torrent_path]
    end
    def download_path_pattern!
      self.download_path_pattern = self.download_path_pattern
    end
    
    def piece_size=(piece_size)
      @piece_size = piece_size
    end
    def piece_size
      @piece_size || default_piece_size
    end
        
    def filename
      full_filepath.last
    end
    def filesize
      @filesize ||= ensure_source_file!.size
    end
    
    def current_save_path=(path)
      @current_save_path = path
    end
    def current_save_path
      @current_save_path
    end
    
    def build(refresh = true)
      header(refresh).merge(download_path ? build_directory : build_single_file).bencode
    end
    def save
      tempfile = Tempfile.new([filename, ".torrent"])
      tempfile.binmode
      
      tempfile.write(build(true))
      tempfile.rewind
      
      tempfile
    end
    def update!
      !!self.current_save_path ? File.write(self.current_save_path, build(true), { mode: "wb" }) : save
    end
    
    def self.tracker_seperator
      "\n"
    end
    def self.tracker_tier_seperator
      "\n\n"
    end
    
    private
    
    def full_filepath
      path = download_path
      fullpath = path ? path.split(File::SEPARATOR) : [File.basename(source_file_path)]
      
      fullpath.reject(&:blank?)
    end

    def header(refresh = false)
      raise "'tracker_url' required for PaperclipTorrent::TorrentFile#initialize" unless tracker_url
      
      # "11\n12\n\n21\n22" => [[11,12], [21,22]]
      # [[11,12], [21,22]] => "['11\n12', '21\n22']" => "11\n12\n\n21\n22"
      
      announce_url = tracker_url.gsub("\r", "").split(TorrentFile.tracker_tier_seperator).collect { |i| i.split(TorrentFile.tracker_seperator) }
      flattened = announce_url.flatten.reject(&:blank?)
      
      header = flattened.size == 1 ? { 'announce' => flattened.first } : { 'announce-list' => announce_url }
      
      if refresh || !@existing_header
        header.merge!({ 
          'created by' => "PaperclipTorrent/#{PaperclipTorrent::VERSION}",
          'creation date' => Time.now.to_i,
          'encoding' => 'UTF-8',
        })
      else
        header.merge!(@existing_header)
      end
      
      header
    end
    def build_single_file
      puts "[PaperclipTorrent::TorrentFile] [warning] Building torrent file for a single file. No directory structure could mean data is overridden on download. Consider setting `PaperclipTorrent::Config.settings[:torrent_path]` to something that will generate unique save paths."
      
      { 
        'info' => {
          'name' => filename,
          'piece length' => piece_size,
          'length' => filesize,
          'pieces' => source_file_hash
        }
      }
    end
    def build_directory
      folder_structure = full_filepath
      root_folder = folder_structure.first
      sub_folders = folder_structure[1..-1]
      
      { 
        'info' => {
          'name' => root_folder,
          'piece length' => piece_size,
          'files' => [{ 'path' => sub_folders, 'length' => filesize }],
          'pieces' => source_file_hash
        }
      }
    end
    
    def interpolated_download_path
      Paperclip::Interpolations.interpolate(download_path_pattern, attachment, attachment_style) if download_path_pattern && attachment && attachment_style
    end
    
    def default_piece_size
      PaperclipTorrent::Config.settings[:default_piece_size] || 256.kilobytes
    end
    
    def source_file_path
      ensure_source_file!.path
    end
    def source_file_hash
      unless @source_file_hash
        offset = 0
        @source_file_hash = ""
      
        while offset < filesize
          chunk = File.binread(source_file_path, piece_size, offset)
          offset += chunk.length
        
          @source_file_hash += Digest::SHA1.digest(chunk)
        end
      end
      
      @source_file_hash
    end
    
    def ensure_source_file!
      source_file || raise("'source_file' required for PaperclipTorrent::TorrentFile#initialize")
    end
    
  end
end