
use Test;
use Errno;

BEGIN { plan tests => 7 };

#
# load
#

ok eval{ require Error::Wait };

ok tied $?;
ok ref tied $?, "Error::Wait";

#
# catch exit status
#

system $^X, '-e', 'exit 1';
ok "$?", qr/Exited: 1/;

#
# use $! when $? == -1
#

$? = -1; 
$! = Errno::ENOENT();

ok "$?", "$!";
ok $?+0, -1;

#
# catch signal
#

$? = 1;
ok "$?", qr/Killed/;

