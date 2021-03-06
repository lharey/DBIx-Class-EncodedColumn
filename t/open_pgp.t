use strict;
use warnings;
use Test::More;

use Dir::Self;
use File::Spec;
use File::Temp 'tempdir';
use lib File::Spec->catdir(__DIR__, 'lib');
use DigestTest::Schema;

BEGIN {
  if( eval 'require Crypt::OpenPGP' && eval 'require Math::Pari' ){
    plan tests => 6;
  } else {
    plan skip_all => 'Crypt::OpenPGP not available';
    exit;
  }
}

#1
DigestTest::Schema->load_classes('PGP');

my $tmp = tempdir( CLEANUP => 1 );
my $db_file = File::Spec->catfile($tmp, 'testdb.sqlite');
my $schema = DigestTest::Schema->connect("dbi:SQLite:dbname=${db_file}");
$schema->deploy({}, File::Spec->catdir(__DIR__, 'var'));

my $row = $schema->resultset('PGP')->create( {
  dummy_col          => 'Dummy Column',
  pgp_col_passphrase => 'Test Encrypted Column with Passphrase',
  pgp_col_key        => 'Test Encrypted Column with Key Exchange',
  pgp_col_key_ps     => 'Test Encrypted Column with Key Exchange + Pass',
} );

like($row->pgp_col_passphrase, qr/BEGIN PGP MESSAGE/, 'Passphrase encrypted');
like($row->pgp_col_key, qr/BEGIN PGP MESSAGE/, 'Key encrypted');
like($row->pgp_col_key_ps, qr/BEGIN PGP MESSAGE/, 'Key+Passphrase encrypted');

is(
  $row->decrypt_pgp_passphrase('Secret Words'),
  'Test Encrypted Column with Passphrase',
  'Passphrase decryption/encryption'
);

is(
  $row->decrypt_pgp_key,
  'Test Encrypted Column with Key Exchange',
  'Key Exchange decryption/encryption'
);

is(
  $row->decrypt_pgp_key_ps('Secret Words'),
  'Test Encrypted Column with Key Exchange + Pass',
  'Secured Key Exchange decryption/encryption'
);
