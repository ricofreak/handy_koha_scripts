#! /usr/bin/perl
use t::lib::TestBuilder;
use Koha::Libraries;
use Koha::Serials;
use Koha::Patrons;
use Koha::DateUtils qw( dt_from_string );

my $libraries = Koha::Libraries->search();
my $builder = t::lib::TestBuilder->new();
while( my $library = $libraries->next) {
    my $several = int( rand(100) );
    my $biblio = Koha::Biblios->find( int(rand(432))+1 );
    for( my $i = 0; $i < $several; $i++ ){
        $builder->build_object({
            class => 'Koha::Serials',
            value => {
                serialseq      => 'serialseq',
                status         => 3,
                biblionumber   => $biblio->biblionumber,
                claimdate      => '2024-01-01',
                claims_count   => $i,
            }
        });
    }
}

1;
