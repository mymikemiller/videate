# VidClone

With permission from a user, automatically clones their media content into a
format VidCast can host as a podcast

## Usage
```
cd vidclone
dart bin/main.dart
```

### Prerequisites
Get Dart: (https://dart.dev/get-dart)

```
 brew tap dart-lang/dart
 brew install dart
```

Get app dependencies:

```
cd vidclone
pub get
```

#### Cloner prerequisites

* Cdn77Uploader:
  + The email address for our cdn77.com account is mike@videate.org
  + See the steps below and [this
    article](https://client.cdn77.com/support/knowledgebase/cdn-resource/how-to-use-rsync-without-password)
    for info on uploading your public ssh key to cdn77's servers
  + Generate private/public keys
    + Run `ssh-keygen -t rsa`, saved into `~/.ssh/cdn77_id_rsa` (passphrase can
      be left empty). This will generate `cdn77_id_rsa` and `cdn77_id_rsa.pub`.
      Leave `cdn77_id_rsa` in the `~/.ssh` folder, and securely copy to
      `~/.ssh` of any user that will be performing uploads. 
  + Upload the public key to CDN77
    + `rsync -va ~/.ssh/cdn77_id_rsa.pub
      user_amhl64ul@push-24.cdn77.com:/.ssh/authorized_keys`
    + Note that the password is not the password used to log into cdn77.com.
      The password can be found at
      https://client.cdn77.com/storage/edit/user_amhl64ul once logged in.
* InternetArchiveCliUploader:
  + Internet Archive's 'ia' command line tool
    (https://github.com/jjjake/internetarchive) is checked in to our source
    control. To update this tool:
    + `cd vidclone/bin/integrations/internet_archive`
    + `curl -LO https://archive.org/download/ia-pex/ia`
    + `chmod +x ia`
  + To supply a user's archive.org credentials and create the necessary ini
    file for that user, run the following. SCREEN_NAME can be found and set at
    https://archive.org/account/index.php?settings=1 when logged in, and should
    be lowercased and have spaces replaced with underscores to match what is
    seen after the '@' in the url for the user's library page at
    https://archive.org/details/@my_screen_name
    + `cd vidclone/bin/integrations/internet_archive`
    + `./ia --config-file '{FULL_IA_CREDENTIAL_FOLDER_PATH}/.ia-{SCREEN_NAME}' configure`

## Development (VSCode)
Open the videate/videate.code-workspace workspace in VSCode

### Debug VidClone server

Set Run Configuration to "VidClone (vidclone)"
Start Debugging

### Debug Tests
Set Run Configuration to "VidClone (vidclone)"
Start Debugging

## Authors

* **Mike Miller** - *Initial work* - [mymikemiller](https://github.com/mymikemiller)
