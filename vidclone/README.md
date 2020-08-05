# VidClone

With permission from a user, automatically clones their video content into a format VidCast can host as a podcast

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
    + `rsync -va ~/.ssh/cdn77_id_rsa.pub user_amhl64ul@push-24.cdn77.com:/.ssh/authorized_keys`
    + Note that the password is not the password used to log into cdn77.com. The password can be found at https://client.cdn77.com/storage/edit/user_amhl64ul once logged in.

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
