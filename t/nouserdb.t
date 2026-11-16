use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../thirdparty/lib/perl5";
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Test::More;
use Test::Mojo;

# Multi user mode on a host that does not know the recipients, e.g. a
# service that writes to a sandbox tree mounted over SMB.
my $root = tempdir(CLEANUP => 1);
$ENV{US_ROOT}        = $root;
$ENV{US_EMAILMODE}   = 1;
$ENV{US_NO_USERDB}   = 1;
$ENV{MOJO_LOG_LEVEL} = 'fatal';
delete $ENV{US_SINGLEUSER};
delete $ENV{US_TAGMODE};

my $user = 'zz_nosuchuser_42';
die "test needs a user name unknown to this host\n" if defined getpwnam($user);
path("$root/$user/INBOX")->make_path;

my $t = Test::Mojo->new('UploadService');

sub upload {
    my ($who, $name, $content) = @_;
    return $t->post_ok("/$who/upload" => form => {
        resumableIdentifier       => length($content).'-x',
        resumableFilename         => $name,
        resumableChunkNumber      => 1,
        resumableChunkSize        => 1048576,
        resumableTotalChunks      => 1,
        resumableCurrentChunkSize => length($content),
        email                     => 'a@example.com',
        file => { content => $content, filename => 'blob' },
    });
}

subtest 'unknown user with an INBOX gets the upload' => sub {
    $t->get_ok("/$user/")->status_is(200)->content_like(qr/\Q$user\E/);
    upload($user, 't.txt', 'hello')->status_is(200)->content_is('ok');
    my @f = grep { /_t\.txt$/ } path("$root/$user/INBOX/a\@example.com")->list->map('basename')->each;
    is scalar(@f), 1, 'stored in the email folder of the INBOX';
};

subtest 'user without INBOX is refused' => sub {
    path("$root/nobody_inbox")->make_path;
    $t->get_ok('/nobody_inbox/')->status_is(403)->content_is('no INBOX directory in sandbox');
};

subtest 'INBOX that is a symlink is refused' => sub {
    my $target = path("$root/elsewhere")->make_path;
    path("$root/linked")->make_path;
    symlink "$target", "$root/linked/INBOX" or die $!;
    $t->get_ok('/linked/')->status_is(403);
    upload('linked', 'evil.txt', 'x')->status_is(403);
    is scalar(@{ $target->list_tree({hidden => 1})->to_array }), 0, 'nothing written through the link';
};

subtest 'user names outside \w never reach an INBOX' => sub {
    # the router already refuses these (404); what matters is: no 200
    $t->get_ok('/a.b/')->status_isnt(200);
    $t->get_ok('/%2e%2e/')->status_isnt(200);
    upload('..', 'evil.txt', 'x')->status_isnt(200);
    ok !-e "$root/evil.txt", 'nothing written next to the sandboxes';
};

subtest 'without US_NO_USERDB the user must exist' => sub {
    local $ENV{US_NO_USERDB};
    delete $ENV{US_NO_USERDB};
    $t->get_ok("/$user/")->status_is(403)->content_is('unknown user');
};

done_testing;
