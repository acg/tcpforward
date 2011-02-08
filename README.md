# NAME

tcpforward - forward or tunnel TCP connections

# SYNOPSIS

    tcpforward [OPTIONS] -l|-c host1:port1 -l|-c host2:port2

    -l host:port   listen on host:port, forward accepted connections
    -c host:port   connect to host:port, forward this connection
    -N count       exit after forwarding count connections
    -k             fork before forwarding (default: no)
    -s size        chunk size for non-blocking reads (default: 1024)
    -V             print version and exit
    -v             turn on parseable logging
    -h             display usage information

# EXAMPLES 

Forward local SMTP to a remote mailserver:

    $ tcpforward -k -c mailserver:25 -l localhost:25

Forward tunnel the SSH service on host1 to host2:

    [host1]$ tcpforward -l host1:9922 -c localhost:22
    [host2]$ tcpforward -c host1:9922 -l localhost:22 
    [host2]$ ssh localhost

Reverse tunnel the SSH service on host1 to host2:

    [host2]$ tcpforward -l host2:9922 -l localhost:22
    [host1]$ tcpforward -c host2:9922 -c localhost:22
    [host2]$ ssh localhost

# DESCRIPTION

tcpforward is a userspace TCP connection forwarder. It uses efficient
non-blocking I/O and is protocol agnostic.

Some uses include:

* Making remote services look like local ones
* Offering a service on a different port number without restarting it 
* Allowing a non-root user to bind to a selected low port
* Tunneling connections into NAT'ed networks or past firewalls
* Evenly distributing a service-oriented architecture
* Monitoring a service's network usage

# SECURITY

tcpforward does __not__ provide encryption of any sort. Forward
only encrypted connections if security is an issue. Consider SSH tunneling
or stunnel if you need an encrypted tunnel.

That said, part of the original motivation for tcpforward was reverse
tunneling of the SSH service itself back through a NAT'ed gateway.
Using ssh to establish the tunnel would have incurred the penalty of
double encryption.

# OPTIONS

* `-c host:port`

Connect to `host:port`, then do forwarding on the socket.

* `-l host:port`

Listen for connections on `host:port`, then do forwarding on the accepted socket.

* `-N count`

Exit after forwarding `count` TCP connections.

* `-k`

Fork and perform forwarding in a child process. This permits multiple
simultaneous forwarded connections. The default is non-forking.

* `-s size`

When forwarding, attempt non-blocking reads of `size` bytes at a time. Setting
this to the median packet size for a given protocol may result in some small
performance gain.

* `-V`

Print version number and exit.

* `-v`

Turn on parseable logging to standard out. Increase logging level with
extra `-v` options.

* `-h`

Display usage information.

# BUGS

tcpforward should be rewritten in C. Please report other bugs on CPAN.

# AUTHOR

Alan Grow <alangrow+tcpforward@gmail.com>

# COPYRIGHT

Copyright (C) 2007, 2010 by Alan Grow

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.3 or, at
your option, any later version of Perl 5 you may have available.
