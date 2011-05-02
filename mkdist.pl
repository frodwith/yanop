use File::Find qw(find);
use File::Spec;
use Archive::Tar;
use JSON;

my @MANIFEST = qw(
    LICENSE
    README.markdown
    package.json
);

find {
    no_chdir => 1,
    wanted   => sub {
        next if /\.git/;
        push @MANIFEST, $_ if /\.js$/;
    }
}, '.';

my $version = do {
    open my $pkg, '<', 'package.json';
    local $/;
    JSON::decode_json(<$pkg>)->{version};
};

my $tar = Archive::Tar->new;
$tar->add_files(@MANIFEST);
my $name = "yanop-$version";
$tar->write("$name.tar.gz", COMPRESS_GZIP, $name);
