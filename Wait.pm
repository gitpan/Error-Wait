#
# Error/Wait.pm
#
# $Author: grazz $
# $Date: 2003/11/16 03:53:01 $
#

package Error::Wait;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';
our $ERR;

use Tie::Scalar;
use POSIX;
use Config;

use base qw(Tie::StdScalar);
use overload '""' => \&to_string,
	     '0+' => sub { $ERR },
	     bool => sub { $ERR },
	     fallback => 1;

sub new {
    my $class = shift;
    bless [], $class;
}

sub FETCH { 
    return $_[0];
}

sub STORE {
    $ERR = $_[1];
}

my @names = split ' ', $Config{sig_name};

sub to_string {
    return $! if $ERR < 0;

    if (WIFEXITED($ERR)) {
	my $status = WEXITSTATUS($ERR);
	return "Exited: $status";
    }
    if (WIFSIGNALED($ERR)) { 
	my $sig = WTERMSIG($ERR);
	return "Killed: $names[$sig]";
    }
    if (WIFSTOPPED($ERR)) { 
	my $sig = WSTOPSIG($ERR);
	return "Stopped: $names[$sig]";
    }
}

#
# Windows doesn't define these macros (?)
#
eval { WIFEXITED(0) };
if ($@) {
    no warnings 'redefine';
    *WIFEXITED   = sub { 0 == ($_[0] & 0xff) };
    *WEXITSTATUS = sub { $_[0] >> 8 };
    *WIFSIGNALED = sub { $_[0] & 0xff };
    *WTERMSIG    = sub { $_[0] & 0xff };
}

#
# Keep the original $? in $ERR
#

*ERR = \$?;
*? = do { tie my($tmp), __PACKAGE__; \$tmp };


__END__

=head1 NAME

Error::Wait - User-friendly version of C<$?>

=head1 SYNOPSIS

  use Error::Wait;
  system('/no/such/file') == 0 or die $?;   # "No such file or directory"
  system('/bin/false')    == 0 or die $?;   # "Exited: 1"
  system('kill -HUP $$')  == 0 or die $?;   # "Killed: HUP"

=head1 DESCRIPTION

Error::Wait overloads the stringification of C<$?> to provide sensible
error messages.  Numeric operations continue to work as usual, so code
using C<<< $? >> 8 >>> won't break.

=head1 SEE ALSO

L<POSIX/WAIT>

=head1 AUTHOR

Steve Grazzini <grazz@pobox.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Steve Grazzini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

