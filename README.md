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

## AUR

### Install bauerbill

Add the `xyne-any` repository (this should be done only once).
```sh
# root
cat <<EOF >>/etc/pacman.conf
[xyne-any]
Server = http://xyne.archlinux.ca/repos/xyne
EOF
```

Install bauerbill
```sh
# root
pacman -Sy bauerbill
```

### Install base-devel

```sh
# root
pacman -Sy --needed base-devel
```

### Setup sudo

You need to allow at least root privilege for user `alarm`.
```sh
# root
visudo
```

### Oracle JDK

This will need some time, be patient.
```sh
# user
bb-wrapper -S --aur AUR/jdk-arm
```

## Oracle JDK (manually)

__I would prefer to use the AUR method (see above).__
But you can also extract a manually downloaded archive.

Fetch the file jdk-8u101-linux-arm32-vfp-hflt.tar.gz
from http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html

Execute this on the host system to copy the JDK to the ARM qemu system
```sh
scp -P12022 stuff/jdk-8u101-linux-arm32-vfp-hflt.tar.gz alarm@127.0.0.1:/home/alarm
```

Extract the ARM JDK
```sh
# user
tar xzf jdk-8u101-linux-arm32-vfp-hflt.tar.gz
```

Add Java to PATH
```sh
export PATH="${PATH}":"${PWD}"/jdk1.8.0_101/bin
```

## Test Karaf

You need a Java VM installed (see methods above)...

Download Karaf
```sh
curl -O http://artfiles.org/apache.org/karaf/4.0.7/apache-karaf-4.0.7.tar.gz
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

## Test openHAB

You need a Java VM installed (see methods above)...

Choose between offline and online distribution
* offline `export OH_DIST=offline`
* online  `export OH_DIST=online`

Download openHAB
```sh
curl -O "https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab-${OH_DIST}/target/openhab-${OH_DIST}-2.0.0-SNAPSHOT.tar.gz"
```

Extract openHAB (create oh directory and cleanup if already present before)
```sh
rm -rf oh; mkdir -p oh; cd oh
tar xzf "../openhab-${OH_DIST}-2.0.0-SNAPSHOT.tar.gz"
```

Start openHAB (reside in oh directory)
```sh
./start.sh
```
