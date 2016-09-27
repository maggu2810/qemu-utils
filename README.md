# Requirements

* Install qemu with softmmu support for the ARM architecture
* Install sudo

# Create a RootFS image

Fetch an Arch Linux ARMv7 rootfs
```sh
wget http://de7.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
```

Create a image to put root fs content into
```sh
qemu-img create armv7.ext4 4G
```

Create FS for image
```sh
mkfs.ext4 armv7.ext4
```

Now fill the FS image with content
```sh
mkdir mnt
mount -o loop armv7.ext4 mnt
bsdtar -xpf ArchLinuxARM-armv7-latest.tar.gz -C mnt
umount mnt
rmdir mnt
```

Now you can remove the downloaded archive.
```sh
rm ArchLinuxARM-armv7-latest.tar.gz
```

# Startup Script

See files in repostiroy

# Start VM

Execute the script (above) to run the ARM VM.

```text
Arch Linux ARM:

username: alarm
password: alarm

username: root
password: root
```

# Examples

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
ssh -lalarm -p12022 127.0.0.1
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

Now watch in another terminal the content of the file
```sh
cd apache-karaf-4.0.7
tail -f data/log/karaf.log
```

It will take some time...
... and you will see this error

```text
2016-09-26 16:58:17,491 | ERROR | pool-1-thread-1  | BootFeaturesInstaller            | 8 - org.apache.karaf.features.core - 4.0.7 | Error installing boot features
org.apache.karaf.features.internal.util.MultiException: Error restarting bundles
	at org.apache.karaf.features.internal.service.Deployer.deploy(Deployer.java:854)[8:org.apache.karaf.features.core:4.0.7]
	at org.apache.karaf.features.internal.service.FeaturesServiceImpl.doProvision(FeaturesServiceImpl.java:1176)[8:org.apache.karaf.features.core:4.0.7]
	at org.apache.karaf.features.internal.service.FeaturesServiceImpl$1.call(FeaturesServiceImpl.java:1074)[8:org.apache.karaf.features.core:4.0.7]
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)[:1.8.0_101]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)[:1.8.0_101]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)[:1.8.0_101]
	at java.lang.Thread.run(Thread.java:745)[:1.8.0_101]
Caused by: org.osgi.framework.BundleException: Activator start error in bundle org.apache.karaf.shell.core [43].
	at org.apache.felix.framework.Felix.activateBundle(Felix.java:2276)[org.apache.felix.framework-5.4.0.jar:]
	at org.apache.felix.framework.Felix.startBundle(Felix.java:2144)[org.apache.felix.framework-5.4.0.jar:]
	at org.apache.felix.framework.BundleImpl.start(BundleImpl.java:998)[org.apache.felix.framework-5.4.0.jar:]
	at org.apache.felix.framework.BundleImpl.start(BundleImpl.java:984)[org.apache.felix.framework-5.4.0.jar:]
	at org.apache.karaf.features.internal.service.FeaturesServiceImpl.startBundle(FeaturesServiceImpl.java:1286)[8:org.apache.karaf.features.core:4.0.7]
	at org.apache.karaf.features.internal.service.Deployer.deploy(Deployer.java:846)[8:org.apache.karaf.features.core:4.0.7]
	... 6 more
Caused by: java.lang.UnsatisfiedLinkError: Could not load library. Reasons: [no jansi in java.library.path, /home/alarm/apache-karaf-4.0.7/data/tmp/libjansi-32-5523660977473402805.so: /home/alarm/apache-karaf-4.0.7/data/tmp/libjansi-32-5523660977473402805.so: cannot open shared object file: No such file or directory (Possible cause: can't load IA 32-bit .so on a ARM-bit platform)]
	at org.fusesource.hawtjni.runtime.Library.doLoad(Library.java:182)
	at org.fusesource.hawtjni.runtime.Library.load(Library.java:140)
	at org.fusesource.jansi.internal.CLibrary.<clinit>(CLibrary.java:42)
	at org.fusesource.jansi.AnsiConsole.wrapOutputStream(AnsiConsole.java:48)
	at org.fusesource.jansi.AnsiConsole.<clinit>(AnsiConsole.java:38)
	at org.apache.karaf.shell.impl.console.osgi.StreamWrapUtil.wrap(StreamWrapUtil.java:62)
	at org.apache.karaf.shell.impl.console.osgi.StreamWrapUtil.reWrap(StreamWrapUtil.java:89)
	at org.apache.karaf.shell.impl.console.osgi.LocalConsoleManager$2.run(LocalConsoleManager.java:81)
	at org.apache.karaf.shell.impl.console.osgi.LocalConsoleManager$2.run(LocalConsoleManager.java:76)
	at java.security.AccessController.doPrivileged(Native Method)[:1.8.0_101]
	at org.apache.karaf.util.jaas.JaasHelper.doAs(JaasHelper.java:93)
	at org.apache.karaf.shell.impl.console.osgi.LocalConsoleManager.start(LocalConsoleManager.java:76)
	at org.apache.karaf.shell.impl.console.osgi.Activator.start(Activator.java:112)
	at org.apache.felix.framework.util.SecureAction.startActivator(SecureAction.java:697)
	at org.apache.felix.framework.Felix.activateBundle(Felix.java:2226)
	... 11 more
```
