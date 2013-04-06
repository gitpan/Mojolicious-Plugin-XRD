#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::JSON;

my $t = Test::Mojo->new;

my $app = $t->app;

$app->plugin('XRD');

# Silence
$app->log->level('error');

my $wk = '/.well-known/host-meta';

$app->get_xrd(
  'undef', ['author'] => sub {
    my $xrd = shift;
    ok(!$xrd, 'Not found');
  });

pass('No life tests');

done_testing;
exit;

my ($xrd, $headers) = $app->get_xrd('//yahoo.com' . $wk);

is($xrd->subject, 'yahoo.com', 'Title');
is($headers->content_type, 'text/plain; charset=utf-8', 'Content Type');
is($headers->header('Server'), 'YTS/1.20.13', 'Serber');
is($headers->content_length, 998, 'Content Length');


is($app->get_xrd('//yahoo.com' . $wk)->subject, 'yahoo.com', 'Title');
ok(!$app->get_xrd('https://yahoo.com' . $wk), 'Not found for secure');

$app->get_xrd(
  'https://yahoo.com' . $wk => sub {
    ok(!$_[0], 'Insecure');
  });

$app->get_xrd(
  '//yahoo.com' . $wk => sub {
    my $xrd = shift;
    is($xrd->link('hub')->attrs('href'),
       'http://yhub.yahoo.com',
       'Correct template');
    is($xrd->subject, 'yahoo.com', 'Title');
  });

$app->get_xrd(
  '//e14n.com' . $wk => sub {
    my $xrd = shift;
    is($xrd->link('lrdd')->attrs('template'),
       'https://e14n.com/api/lrdd?resource={uri}',
       'Correct template');

    is($xrd->link('registration_endpoint')->attrs('href'),
       'https://e14n.com/api/client/register',
       'Correct template');
});

$app->get_xrd(
  '//e14n.com' . $wk => ['lrdd'] => sub {
    my $xrd = shift;
    is($xrd->link('lrdd')->attrs('template'),
       'https://e14n.com/api/lrdd?resource={uri}',
       'Correct template');
    ok(!$xrd->link('registration_endpoint'),
       'no registration endpoint');
});

$app->get_xrd(
  '//gmail.com' . $wk => sub {
    my $xrd = shift;
    ok($xrd->extension('XML::Loy::HostMeta'), 'Add Extension');
    is($xrd->host, 'gmail.com', 'Correct Host');
    is($xrd->link('lrdd')->attrs('template'),
       'http://profiles.google.com/_/webfinger/?q={uri}',
       'Correct Template');
  });

$app->get_xrd(
  'https://gmail.com' . $wk => {'X-MyHeader' => 'Just for fun' } => [''] => sub {
    my $xrd = shift;
    ok($xrd->extension('XML::Loy::HostMeta'), 'Add Extension');
    is($xrd->host, 'gmail.com', 'Correct Host');
    ok(!$xrd->link('lrdd'),'Filtered links');
  });



done_testing;
exit;

__END__
