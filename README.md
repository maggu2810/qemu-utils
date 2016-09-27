# Requirements

* Install qemu with softmmu support for the ARM architecture
* Install sudo

# Create a RootFS image

Use the script provided by this repository
```sh
sh ctrl.sh create_img
```

# Start VM

Use the script provided by this repository
```sh
sh ctrl.sh run
```

That are the usernames and passwords used by the Arch Linux ARM images:
```text
Arch Linux ARM:

username: alarm
password: alarm

username: root
password: root
```

# Examples

## Install bauerbill

Add the `xyne-any` repository (this should be done only once).
```sh
cat <<EOF >>/etc/pacman.conf
[xyne-any]
Server = http://xyne.archlinux.ca/repos/xyne
EOF
```

Install bauerbill
```sh
pacman -Sy bauerbill
```

## Test Karaf or something similar stuff

On the host system:

Download Karaf
```sh
wget http://artfiles.org/apache.org/karaf/4.0.7/apache-karaf-4.0.7.tar.gz
```

Fetch the file jdk-8u101-linux-arm32-vfp-hflt.tar.gz
from http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html

Execute this on the host system to copy the JDK and Karaf to the ARM qemu system
```sh
scp -P12022 stuff/jdk-8u101-linux-arm32-vfp-hflt.tar.gz alarm@127.0.0.1:/home/alarm
scp -P12022 stuff/apache-karaf-4.0.7.tar.gz alarm@127.0.0.1:/home/alarm
```

Connect to the ARM qemu system using SSH
```sh
sh ctrl.sh ssh
```

Extract the ARM JDK
```sh
tar xzf jdk-8u101-linux-arm32-vfp-hflt.tar.gz
```

Add Java to PATH
```sh
export PATH="${PATH}":"${PWD}"/jdk1.8.0_101/bin
```

Extract Karaf
```sh
tar xzf apache-karaf-4.0.7.tar.gz
```

Start Karaf
```sh
cd apache-karaf-4.0.7
bin/karaf
```

To watch the log file if there went something wrong while booting, you can have a look at the file in another terminal:
```sh
cd apache-karaf-4.0.7
tail -f data/log/karaf.log
```

