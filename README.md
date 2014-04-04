PaperclipTorrent
=========

Convert processed paperclip attachments in to a downloadable torrent file for later retrieval.

Setup
----

Currently PaperclipTorrent requires an edge version on Paperclip to support multiple style saving.

To use, add the following to your **Gemfile**:

```
gem 'paperclip', github: "thoughtbot/paperclip"
gem 'paperclip_torrent', github: "fattymiller/paperclip_torrent"
```

In your model, setup your `has_attached_files` as normal, including the `:torrentify` processor like so:

```
  has_attached_file :attachment, { styles: {
    audio_128kbps_44100hz: { format: 'mp3', torrentify: true }, 
    hd_720p_16x9_5000kbps: { geometry: '1280x720', format: 'mp4', torrentify: true }, 

    preview_image: { geometry: '1024x768', format: 'jpg', time: 10 }
  }, processors: [:ffmpeg, :qtfaststart, :torrentify] }
```

The above example shows three paperclip styles to be parsed by ffmpeg processors, two of which (based on the `torrentify: true` setting) will output torrent files.

To access your generated torrent files, create an `after_save` callback, and iterate over `<attachment_field>.torrent_results`.

### Optional

Optionally, PaperclipTorrent can be setup to automatically save your torrent files against your model on save when new files are detected. To do so:


#### Run the installer and migrate
```
rails generate paperclip_torrent:install
bundle exec rake db:migrate
```


#### Include in your model
`include PaperclipTorrent::Torrentable`

This will add a `has_many torrent_files` association and add `persist_torrent_files` to your model's `after_save` callback.

#### Retrieving records
If your model responds to `torrent_results`, you can call `<attachment_field>.torrent_files` at any time to fetch available torrent keys.

This method will result in a hash of torrent key and file properties hash: `{ torrent_file: TorrentFile, dirty: boolean }`. 

If the file instance is nil, you can fetch the paperclip record by calling `<attachment_field>.torrent_file(torrent_key)`. From here you can access the file path or URL as normal.


Settings
---

### Torrent file generation

To generate a torrent file from a Paperclip style, two things are required `torrentify: true` and `tracker: <tracker_announce_url>`

**For example,** either of the following will work:

```
  has_attached_file :attachment, { styles: {
    audio_128kbps_44100hz: { format: 'mp3', torrentify: true }
  }, 
  processors: [:ffmpeg, :qtfaststart, :torrentify],
  tracker: "http://tracker.mysite.com/announce" }
```

```
  has_attached_file :attachment, { styles: {
    audio_128kbps_44100hz: { format: 'mp3', torrentify: true, tracker: "http://tracker.mysite.com/announce" },
    hd_720p_16x9_5000kbps: { geometry: '1280x720', format: 'mp4', torrentify: true, tracker: "http://tracker.anothersite.com/announce" }
  }, 
  processors: [:ffmpeg, :qtfaststart, :torrentify] }
```

### Download file save path

Using PaperclipTorrent, you can set a torrent file to save its downloaded file to either the download directory, or a sub-directory thereof.

By default, PaperclipTorrent is set to download the file in to a sub-directory using the default path structure: `:fingerprint/:style/:filename`.

To set this, in an initializer set `PaperclipTorrent::Config.settings[:torrent_path]` to any directory using the standard Paperclip directory markup.

Although not recommended, setting this value to nil will create the torrent file as if it is to save the file directly in the download directory.

### Default values

The default values for the config hash are:

```
PaperclipTorrent::Config.settings = {
    torrent_path: ":fingerprint/:style/:filename",
    default_piece_size: 256.kilobytes
}
```

Still to do
---

Still on my to do list for this project:
 - Customisable torrent file save path
 - Support multiple attachment fields by storing the attachment name in the TorrentFileAttachment class
 - Open existing torrent
 - Auto load torrent when accessing an existing record

License
---

MIT


**Free Software, Hell Yeah!**
