#!/usr/bin/perl

use Fcntl;
use Errno;
use IO::Socket::INET;
use Pod::Usage qw/pod2usage/;
use warnings;
use strict;

our $VERSION = 0.01;
my $prog = ($0 =~ m{([^/]+)$})[0];
my $usage = "$prog [OPTIONS] -l|-c host1:port1 -l|-c host2:port2";

my $count = undef;
my $fork = 0;
my $verbose = 0;
my $bufsize = 1024;
my @lsocks;
my @addr;

while (@ARGV) {
  my $flag = shift;

  if ($flag eq '-l' && @addr < 2) {
    push @addr, (shift or die $usage);
    push @lsocks, lsock($addr[-1]);
  }
  elsif ($flag eq '-c' && @addr < 2) {
    push @addr, (shift or die $usage);
    push @lsocks, undef;
  }
  elsif ($flag eq '-N' && @ARGV) {
    $count = 0+shift;
  }
  elsif ($flag eq '-k') {
    $fork = 1;
  }
  elsif ($flag eq '-s') {
    $bufsize = 0+(shift or die $usage);
  }
  elsif ($flag eq '-V') {
    print $VERSION."\n";
    exit 0;
  }
  elsif ($flag eq '-v') {
    $verbose++;
  }
  elsif ($flag eq '-h') {
    pod2usage();
  }
  else {
    die $usage;
  }
}

die $usage unless @addr == 2;

for (my $n=0; !defined $count || $n<$count; $n++) {
  my @socks;

  for my $i (0, 1) {
    $socks[$i] = $lsocks[$i] ? asock($lsocks[$i]) : csock($addr[$i]);
    $socks[$i] = nonblock($socks[$i]);
    verbose(1, sprintf 'sock %s %d', $addr[$i], fileno $socks[$i]);
  }

  if ($fork) {
    defined (my $pid = fork) or
      die "fork error: $!";

    if ($pid == 0) {
      verbose(1, "fork $$");
      forward(@socks);
      verbose(1, "exit $$");
      exit(0);
    }
  }
  else {
    forward(@socks);
  }
}

while ($fork && wait >= 0) {}
exit 0;

sub forward {
  my @socks = @_;
  my @eof;

  while (my @readable = map $socks[$_] => grep !$eof[$_] => (0, 1)) {
    my $rin = fdset(@readable);

    select(my $rout=$rin, undef, undef, undef) >= 0 or
      die "select error: $!";

    if (vec($rout, fileno $socks[0], 1)) {
      $eof[0] = !transfer($socks[0], $socks[1]);
      $socks[1]->shutdown(1) if $eof[0];
    }

    if (vec($rout, fileno $socks[1], 1)) {
      $eof[1] = !transfer($socks[1], $socks[0]);
      $socks[0]->shutdown(1) if $eof[1];
    }
  }
}

sub transfer {
  my ($rfh, $wfh) = @_;
  my $total = 0;
  my $bytes;

  while ($bytes = sysread $rfh, my $data, $bufsize) {
    $total += $bytes;

    while ($bytes > 0) {
      my $written = syswrite $wfh, $data, $bytes, length($data) - $bytes;
      die "write error: $!" if !defined $written && !$!{EAGAIN};
      $bytes -= $written if defined $written;
    }
  }

  verbose(1, sprintf 'xfer %d %d %d', fileno $rfh, fileno $wfh, $total);
  return 0 if defined $bytes; # sysread == 0, EOF
  return 1 if $!{EAGAIN};
  die "read error: $!";
}

sub lsock {
  my $addr = shift;
  my $sock = IO::Socket::INET->new(
    LocalAddr => $addr, Listen => SOMAXCONN, ReuseAddr => 1, @_) or
      die "listen error for $addr: $!";
  return $sock;
}

sub asock {
  my $listen = shift;
  my $sock = $listen->accept or
    die "accept error: $!";
  return $sock;
}

sub csock {
  my $addr = shift;
  my $sock = IO::Socket::INET->new(PeerAddr => $addr, @_) or
    die "connect error for $addr: $!";
  return $sock;
}

sub nonblock {
  my $fh = shift;
  my $flags = fcntl $fh, F_GETFL, 0 or
    die "fcntl error: $!";
  fcntl $fh, F_SETFL, $flags | O_NONBLOCK or
    die "fcntl error: $!";
  return $fh;
}

sub fdset {
  my $set = '';
  vec($set, fileno $_, 1) = 1 for @_;
  return $set;
}

sub verbose {
  my $level = shift;
  print join("\n" => @_, '') if $verbose >= $level;
}

__END__

=head1 NAME

tcpforward - forward or tunnel TCP connections

=head1 SYNOPSIS

tcpforward [OPTIONS] -l|-c host1:port1 -l|-c host2:port2

  -l host:port   listen on host:port, forward accepted connections
  -c host:port   connect to host:port, forward this connection
  -N count       exit after forwarding count connections
  -k             fork before forwarding (default: no)
  -s size        chunk size for non-blocking reads (default: 1024)
  -V             print version and exit
  -v             turn on parseable logging
  -h             display usage information

=head1 EXAMPLES 

Forward local SMTP to a remote mailserver:

  $ tcpforward -k -c mailserver:25 -l localhost:25

Forward tunnel the SSH service on 10.0.0.100 to 10.0.0.101:

  [10.0.0.100]$ tcpforward -l 10.0.0.100:9922 -c localhost:22
  [10.0.0.101]$ tcpforward -c 10.0.0.100:9922 -l localhost:22 
  [10.0.0.101]$ ssh localhost

Reverse tunnel the SSH service on 10.0.0.100 to 10.0.0.101:

  [10.0.0.101]$ tcpforward -l 10.0.0.101:9922 -l localhost:22
  [10.0.0.100]$ tcpforward -c 10.0.0.101:9922 -c localhost:22
  [10.0.0.101]$ ssh localhost

=head1 DESCRIPTION

tcpforward is a userspace TCP connection forwarder. It uses efficient
non-blocking I/O and is protocol agnostic.

Some uses include:

=over

=item *

Making remote services look like local ones

=item *

Offering a service on a different port number without restarting it

=item *

Allowing a non-root user to bind to a selected low port

=item *

Tunneling connections into NAT'ed networks or past firewalls

=item *

Evenly distributing a service-oriented architecture

=item *

Monitoring a service's network usage

=back

=head1 SECURITY

tcpforward does B<not> provide encryption of any sort. Forward
only encrypted connections if security is an issue. Consider SSH tunneling
or stunnel if you need an encrypted tunnel.

That said, part of the original motivation for tcpforward was reverse
tunneling of the SSH service itself back through a NAT'ed gateway.
Using ssh to establish the tunnel would have incurred the penalty of
double encryption.

=head1 OPTIONS

=over 4

=item -c host:port

Connect to host:port, then do forwarding on the socket.

=item -l host:port

Listen for connections on host:port, then do forwarding on the accepted socket.

=item -N count

Exit after forwarding count TCP connections.

=item -k

Fork and perform forwarding in a child process. This permits multiple
simultaneous forwarded connections. The default is non-forking.

=item -s size

When forwarding, attempt non-blocking reads of size bytes at a time. Setting
this to the median packet size for a given protocol may result in some small
performance gain.

=item -v

Print version number and exit.

=item -v

Turn on parseable logging to standard out. Increase logging level with
extra -v options.

=item -h

Display usage information.

=back

=head1 BUGS

tcpforward should be rewritten in C. Please report other bugs on CPAN.

=head1 AUTHOR

Alan Grow <agrow+nospam@thegotonerd.com>

=head1 COPYRIGHT

Copyright (C) 2007 by Alan Grow

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.3 or, at
your option, any later version of Perl 5 you may have available.

=cut

