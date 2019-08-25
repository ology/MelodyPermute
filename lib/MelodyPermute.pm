package MelodyPermute;

our $VERSION = '0.1';

use lib '/Users/gene/sandbox/Music';
use MIDIUtil;

use Dancer ':syntax';
use MIDI::Simple;
use Math::Combinatorics;
use List::Util qw( shuffle );

get '/' => sub {
    template 'index';
};

post '/generate' => sub {
    my %params = (
        treb_notes => params->{treb_notes} || 'C5 D5 Ds5 As4',
        treb_dura  => params->{treb_dura}  || 'en en qn qn',
        treb_velo  => params->{treb_velo}  || 'mp mezzo mf f',
        bass_notes => params->{bass_notes} || 'C3 F3 G3 C3',
        bass_dura  => params->{bass_dura}  || 'qn qn qn qn',
        bass_velo  => params->{bass_velo}  || 'f f f f',
        max        => defined params->{max} ? params->{max} : 16,
        patch      => defined params->{patch} ? params->{patch} : 0,
        channel    => params->{channel}    || 1,
        bpm        => params->{bpm}        || 120,
        filename   => params->{filename}   || 'MelodyPermute',
        patches    => \%MIDI::number2patch,
    );

    generate(%params);

    template 'index', \%params;
};

sub generate {
    my %args = @_;

    my @treb_notes = split /\s+/, $args{treb_notes};
    my @treb_dura  = split /\s+/, $args{treb_dura};
    my @treb_velo  = split /\s+/, $args{treb_velo};
    my @bass_notes = split /\s+/, $args{bass_notes};
    my @bass_dura  = split /\s+/, $args{bass_dura};
    my @bass_velo  = split /\s+/, $args{bass_velo};

    my @treb_combos      = shuffle permute(@treb_notes);
    my @treb_dura_combos = shuffle permute(@treb_dura);
    my @treb_velo_combos = shuffle permute(@treb_velo);
    my @bass_combos      = shuffle permute(@bass_notes);
    my @bass_dura_combos = shuffle permute(@bass_dura);
    my @bass_velo_combos = shuffle permute(@bass_velo);

    my $score = MIDIUtil::setup_midi(
        lead_in => scalar(@treb_notes),
        %args
    );

    my $n = 0;

    for my $i ( 0 .. @treb_combos - 1 ) {
        for my $j ( 0 .. @{ $treb_combos[$i] } - 1 ) {
            $n++;
            last if $args{max} && $n > $args{max};

            if ( $treb_dura_combos[$i][$j] eq $bass_dura_combos[$i][$j] ) {
                $score->n(
                    $treb_velo_combos[$i][$j],
                    $treb_dura_combos[$i][$j],
                    $treb_combos[$i][$j],
                    $bass_combos[$i][$j]
                );
            }
            else {
                $score->n(
                    $treb_velo_combos[$i][$j],
                    $treb_dura_combos[$i][$j],
                    $treb_combos[$i][$j]
                );
                $score->n(
                    $bass_velo_combos[$i][$j],
                    $bass_dura_combos[$i][$j],
                    $bass_combos[$i][$j]
                );
            }
        }

        last if $args{max} && $n > $args{max};
    }

    $score->write_score( "public/$args{filename}.mid" );
}

true;

__END__

=head1 AUTHOR
 
Gene Boggs <gene@cpan.org>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2019 by Gene Boggs.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
 
=cut
