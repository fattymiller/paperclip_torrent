require 'bencode'

module PaperclipTorrent
  class TorrentFile
    
    attr_accessor :source_file, :tracker_url, :piece_size, :directory_path
    
    def self.create_for(file, options, paperclip_attachment)
      directory_path_pattern = options[:torrent_path] || PaperclipTorrent::Config.settings[:torrent_path]
      directory_path = Paperclip::Interpolations.interpolate(directory_path_pattern, paperclip_attachment, options[:style]) if directory_path_pattern
      
      self.new(file, options[:tracker], directory_path, options[:piece_size]).save
    end
    
    def initialize(source_file, tracker_url, directory_path, piece_size = nil)
      raise "'source_file' required for PaperclipTorrent::TorrentFile#initialize" unless source_file
      raise "'tracker_url' required for PaperclipTorrent::TorrentFile#initialize" unless tracker_url
      
      self.source_file = source_file
      self.tracker_url = tracker_url.to_s
      self.directory_path = directory_path
      self.piece_size = piece_size || PaperclipTorrent::Config.settings[:default_piece_size] || 256.kilobytes
    end
    
    def filename
      @filename ||= File.basename(source_filename)
    end
    def filesize
      @filesize ||= source_file.size
    end
    
    def build
      header.merge(directory_path ? build_directory : build_single_file).bencode
    end
    def save
      tempfile = Tempfile.new([filename, ".torrent"])
      tempfile.binmode
      
      tempfile.write(build)
      tempfile.rewind
      
      tempfile      
    end
    
    private
    
    def full_filepath
      directory_path ? directory_path.split(File::SEPARATOR) : []
    end

    def header
      { 'announce' => tracker_url,
        'created by' => "PaperclipTorrent/#{PaperclipTorrent::VERSION}",
        'creation date' => Time.now.to_i,
        'encoding' => 'UTF-8',
      }
    end
    def build_single_file
      puts "[PaperclipTorrent::TorrentFile] [warning] Building torrent file for a single file. No directory structure could mean data is overridden on download. Consider setting `PaperclipTorrent::Config.settings[:torrent_path]` to something that will generate unique save paths."
      
      { 
        'info' => {
          'name' => File.basename(source_file.path),
          'piece length' => piece_size,
          'length' => filesize,
          'pieces' => file_hashes
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
          'pieces' => file_hashes
        }
      }
    end
    
    def source_filename
      @source_filename ||= source_file.path
    end
    
    def file_hashes
      offset = 0
      hashes = ""
      
      while offset < filesize
        chunk = File.binread(source_filename, piece_size, offset)
        offset += chunk.length
        
        hashes += Digest::SHA1.digest(chunk)
      end
      
      hashes
    end
    
  end
end