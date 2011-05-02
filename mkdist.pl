use File::Find qw(find);
use File::Spec;
use Archive::Tar;
use JSON;

my @MANIFEST = qw(
    LICENSE
    README.markdown
    package.json
);

sub add_manifest {
    my $re = shift;
    find {
        no_chdir => 1,
        wanted   => sub { push @MANIFEST, $_ if $_ =~ $re }
    }, $_ for @_;
}

add_manifest qr/\.js$/, qw(lib test);
add_manifest qr/\.coffee$/, 'examples';

my $version = do {
    open my $pkg, '<', 'package.json';
    local $/;
    JSON::decode_json(<$pkg>)->{version};
};

my $tar = Archive::Tar->new;
$tar->add_files(@MANIFEST);
my $name = "yanop-$version";
$tar->write("$name.tar.gz", COMPRESS_GZIP, $name);
