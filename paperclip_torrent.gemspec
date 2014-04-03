$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "paperclip_torrent/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "paperclip_torrent"
  s.version     = PaperclipTorrent::VERSION
  s.authors     = ["fattymiller"]
  s.email       = ["fatty@mobcash.com.au"]
  s.homepage    = "https://github.com/fattymiller/base_jump"
  s.summary     = "Create a torrent file to compliment your paperclip attachment."
  s.description = "Create a torrent file to compliment your paperclip attachment."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.1"
  s.add_dependency "bencode", "~> 0.8.0"
  s.add_dependency "paperclip", ">= 4.1.1"

  s.add_development_dependency "sqlite3"
end
