## Overview

These are scripts for my personals arch linux instllations.

### Prepare disk for installation

+ Download script:

```
$ curl -LOJ https://raw.githubusercontent.com/arperalta3/scripts/master/arch/prepare-disk.sh
```

+ Run prepare disk script:

 ```
$ bash prepare-disk.sh
```

### Installation part 1

+ Download script:

```
$ curl -LOJ https://raw.githubusercontent.com/arperalta3/scripts/master/arch/install-1.sh
```

+ Run script:

 ```
$ bash install-1.sh sda sda1 sda2 sda3 la-latin1 false
```
The params are: disk name. boot partition, swap partition, root partition, keyboard layout and if use wifi

### Installation part 2

+ Download script:

```
$ curl -LOJ https://raw.githubusercontent.com/arperalta3/scripts/master/arch/install-2.sh
```

+ Run script:

 ```
$ bash install-2.sh America/Bogota la-latin1 latam s4n-arpp andres false
```
The params are: local time zone, keyboard layout, keyboard layout for x11, hostname, system user to create and if use wifi
