#
# Error/Wait.pm
#
# $Author: grazz $
# $Date: 2003/11/03 21:47:55 $
#

my $err = \$?;
my $obj = Error::Wait::_overload->new;

{
    package Error::Wait;
    $VERSION = '0.01';

    use Tie::Scalar;
    use base qw(Tie::StdScalar);

    sub FETCH { return $obj }
    sub STORE { $$err = pop }

    tie my($tied), __PACKAGE__;
    *? = \$tied;
}

{
    package Error::Wait::_overload;

    use Config;
    my @sig_names = split ' ', $Config{sig_name};

    use overload
	'""' => \&to_string,
	'0+' => \&to_int,
	bool => \&to_int,
	fallback => 1;

    sub new {
	my $class = shift;
	bless [], $class;
    }

    sub to_int { 
	return $$err;
    }

    sub to_string {
	my $e = $$err;
	return $! if $e < 0;

	# importing from POSIX is broken in 5.8.0
	package POSIX;
	require POSIX;

	if (WIFEXITED($e)) {
	    my $status = WEXITSTATUS($e);
	    return "Exited: $status";
	}
	if (WIFSIGNALED($e)) {
	    my $sig = WTERMSIG($e);
	    if ($sig >= 0 and $sig < @sig_names) {
		$sig = $sig_names[$sig];
	    }
	    return "Killed: $sig";
	}
	if (WIFSTOPPED($e)) {
	    my $sig = WSTOPSIG($e);
	    if ($sig >= 0 and $sig < @sig_names) {
		$sig = $sig_names[$sig];
	    }
	    return "Stopped: $sig";
	}
    }
}

1;

__END__

=head1 NAME

Error::Wait - user-friendly version of C<$?>

=head1 SYNOPSIS

  use Error::Wait;
  system('/no/such/file') == 0 or die $?;   # "No such file or directory"
  system('/bin/false')    == 0 or die $?;   # "Exited: 1"
  system('kill -HUP $$')  == 0 or die $?;   # "Killed: HUP"

=head1 DESCRIPTION

Error::Wait overloads the stringification of C<$?>.  Numeric operations
continue to work as usual, so code using C<<< $? >> 8 >>> won't break.

=head1 KNOWN ISSUES

C<$?++> and C<$?--> won't work correctly.

=head1 SEE ALSO

L<POSIX/WAIT>

=head1 AUTHOR

Steve Grazzini <grazz@pobox.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Steve Grazzini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
