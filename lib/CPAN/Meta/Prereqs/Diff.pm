package CPAN::Meta::Prereqs::Diff;
use 5.008005;
use strict;
use warnings;
use version;
use Carp;
use CPAN::Meta;
use CPAN::Meta::Prereqs;
use File::Basename;
use Module::CPANfile;
use Module::CoreList;

our $VERSION = "0.01";

sub new {
    my ($class, $args) = @_;
    bless {
        perl_version => $args->{perl_version} || '5.008001',
    }, $class;
}

sub diff {
    my ($self, $prereqs, $meta_prereqs) = @_;

    my $normalized_meta_prereqs = $self->_normalize_prereq($meta_prereqs);
    my $normalized_prereqs      = $self->_normalize_prereq($prereqs);

    my $corelist      = $self->_blead_corelist;
    my @prereq_types  = ('runtime', 'test', 'configure', 'develop');
    my @require_types = ('requires', 'recommends', 'suggests', 'conflicts');
    for my $prereq_type (@prereq_types) {
        for my $req_type (@require_types) {
            $self->_remove_prereqs($normalized_prereqs, $normalized_meta_prereqs, $prereq_type, $req_type);
        }
    }
    return $normalized_prereqs;
}

sub _remove_prereqs {
    my ($self, $prereqs, $allowed, $prereq_type, $req_type) = @_;
    return unless $allowed;

    $self->{corelist} ||= $self->_blead_corelist;

    for my $module (keys %{$allowed->{$prereq_type}{$req_type}}) {
        if (exists $allowed->{$prereq_type}{$req_type}{$module}) {
            my $allowed_module = $allowed->{$prereq_type}{$req_type}{$module};
            my $prereqs_module = $prereqs->{$prereq_type}{$req_type}{$module};

            if ($self->_parse_version($allowed_module) >= $self->_parse_version($prereqs_module)) {
                delete $prereqs->{$prereq_type}{$req_type}{$module};
            }
        }
    }
}

sub _blead_corelist {
    my $self = shift;
    my %corelist = %{$Module::CoreList::version{$self->{perl_version}}};
    for my $module (keys %corelist) {
        my $upstream = $Module::CoreList::upstream{$module};
        if ($upstream && $upstream eq 'cpan') {
            delete $corelist{$module};
        }
    }
    return \%corelist;
}

sub _normalize_prereq {
    my ($self, $prereq) = @_;

    my $ref = ref $prereq;
    if ($ref eq 'CPAN::Meta::Prereqs') {
        return $prereq->as_string_hash;
    }
    if ($ref eq 'CPAN::Meta::Requirements') {
        return $prereq->as_string_hash;
    }
    if ($ref eq 'HASH') {
        return CPAN::Meta::Prereqs->new($prereq)->as_string_hash;
    }

    return $self->_load_prereq_from_file($prereq);
}

sub _load_prereq_from_file {
    my ($self, $src) = @_;

    if (File::Basename::basename($src) eq 'cpanfile') {
        return Module::CPANfile->load($src)->prereq_specs;
    } elsif ($src =~ /\.(yml|json)$/) {
        my $meta = CPAN::Meta->load_file($src);
        my $meta_prereqs = CPAN::Meta::Prereqs->new($meta->prereqs)->as_string_hash;
        return $meta_prereqs;
    } else {
        croak "No META.json and cpanfile\n";
    }
}

sub _parse_version {
    my ($self, $v) = @_;
    return version->parse(0) unless defined $v;
    return version->parse(''.$v);
}
1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Meta::Prereqs::Diff - It's new $module

=head1 SYNOPSIS

    use CPAN::Meta::Prereqs::Diff;

=head1 DESCRIPTION

CPAN::Meta::Prereqs::Diff is ...

=head1 LICENSE

Copyright (C) Taiki Kawakami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Taiki Kawakami E<lt>kgw5o.kawakami@gmail.comE<gt>

=cut

