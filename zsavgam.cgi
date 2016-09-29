#!/usr/bin/perl
use strict;
use warnings;

sub decode
{
  my($s) = @_;
  $s =~ s/\+/ /g;
  $s =~ s/%([0-9a-f]{2})/chr(hex($1))/gie;
  $s;
}

sub main
{
  my $t = time();
  my $ip = $ENV{REMOTE_ADDR} || die('cgi');
  my $user =
      ($ENV{PHP_AUTH_DIGEST} || '') =~ /^username="([^"]+)"/ ? $1 : '';

  my %q;
  /^([^=]+)=(.*)$/ and $q{decode($1)} = decode($2)
      for split(/&/, $ENV{QUERY_STRING} || '');
  my $k = $q{k} || return 'hello';
  my $v = $q{v};
  my $cb = $q{callback} || $q{jsonp} || '';
  my $path = "/home/zaphod/zsavgam/log";
  my $json = '{}';

  if($k !~ /^[0-9a-z]{5,50}$/)
  {
    $json = '{"error":"bad k"}';
  }
  elsif($v =~ /([^\x20-\x7e])/)
  {
    my $n = ord($1);
    $json = '{"error":"v has char $n"}';
  }
  elsif(length($v) > 1e5)
  {
    $json = '{"error":"v too large"}';
  }
  elsif($v)
  {
    open(my $fh, '>>', $path) or die("open $path for append: $!");
    binmode($fh);
    my $line = "\nk=$k ip=$ip user=$user t=$t v=$v ok\n";
    my $len = length($line);
    my $ret = syswrite($fh, $line);
    die("syswrite $path: $!") if !defined($ret);
    die("wrote $ret/$len bytes to $path") if $ret != $len;
    close($fh) or die("close $path for append: $!");
    $json = '{"ok":true}';
  }
  else
  {
    my $re = qr/^k=\Q$k\E .* v=(.+) ok$/;
    open(my $fh, '<', $path) or die("open $path for read: $!");
    binmode($fh);
    while(defined(my $line = readline($fh)))
    {
      next if $line !~ $re;
      my $v = $1;
      $v =~ s/([\\"])/\\$1/g;
      $json = qq[{"$k":"$v"}];
      last;
    }
  }

  return $cb =~ /^\w+$/ ? "$cb($json);" : $json;
}

my $response = main();
print("Content-Type: text/javascript\n\n$response\n");

