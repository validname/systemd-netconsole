pkgname=systemd-netconsole
pkgver=0.0
pkgrel=1
pkgdesc="Loads netconsole kernel module and configures it via dynamic configuration"
arch=('any')
license=('MIT')
depends=('bash' 'systemd' 'iproute2' 'iputils' 'grep' 'gawk' 'findutils')
backup=('etc/default/netconsole')
source=("git+https://github.com/validname/systemd-netconsole.git")
md5sums=('SKIP')
noextract=()

pkgver() {
	cd "$srcdir/$pkgname"
	local date=$(git log -1 --format="%cd" --date=short | sed s/-//g)
	local count=$(git rev-list --count HEAD)
	local commit=$(git rev-parse --short HEAD)
	echo "$date.${count}_$commit"
}

package() {
	for dir in `find ${srcdir}/${pkgname}/ -mindepth 1 -maxdepth 1 -type d \! -name '.git'`; do
		echo "Copying $dir..."
		cp -r -t $pkgdir $dir
	done
}
