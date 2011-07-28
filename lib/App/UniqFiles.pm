package App::UniqFiles;

use 5.010;
use strict;
use warnings;
use Log::Any qw($log);

use Digest::MD5;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(uniq_files);

our $VERSION = '0.02'; # VERSION

our %SPEC;

$SPEC{uniq_files} = {
    summary => 'Report or omit duplicate file contents',
    description => <<'_',

Given a list of filenames, will check each file size and content for duplicate
content. Interface is a bit like the `uniq` Unix command-line program.

_
    args    => {
        files => ['array*' => {
            of         => 'str*',
            arg_pos    => 0,
            arg_greedy => 1,
        }],
        report_unique => [bool => {
            summary => 'Return unique items',
            default => 1,
            arg_aliases => {
                u => {
                    summary => 'Alias for --report-unique --noreport-duplicate',
                    code => sub {
                        my %args = @_;
                        my $args = $args{args};
                        $args->{report_unique}    = 1;
                        $args->{report_duplicate} = 0;
                    },
                },
            },
        }],
        report_duplicate => [bool => {
            summary => 'Return duplicate items',
            default => 0,
            arg_aliases => {
                d => {
                    summary => 'Alias for --noreport-unique --report-duplicate',
                    code => sub {
                        my %args = @_;
                        my $args = $args{args};
                        $args->{report_unique}    = 0;
                        $args->{report_duplicate} = 1;
                    },
                },
            },
        }],
        count => [bool => {
            summary => "Return each file content's number of occurence",
            description => <<'_',

1 means the file content is only encountered once (unique), 2 means there is one
duplicate, and so on.

_
            default => 0,
        }],
    },
};
sub uniq_files {
    my %args = @_;

    my $files = $args{files};
    return [400, "Please specify files"] if !$files || !@$files;
    my $report_unique    = $args{report_unique}    // 1;
    my $report_duplicate = $args{report_duplicate} // 0;
    my $count            = $args{count}            // 0;

    # get sizes of all files
    my %size_counts; # key = size, value = number of files having that size
    my %file_sizes; # key = filename, value = file size, for caching stat()
    for my $f (@$files) {
        my @st = stat $f;
        unless (@st) {
            $log->error("Can't stat file `$f`: $!, skipped");
            next;
        }
        $size_counts{$st[7]}++;
        $file_sizes{$f} = $st[7];
    }

    # calculate digest for all files having non-unique sizes
    my %digest_counts; # key = digest, value = num of files having that digest
    my %file_digests; # key = filename, value = file digest
    for my $f (@$files) {
        next unless defined $file_sizes{$f};
        next if $size_counts{ $file_sizes{$f} } == 1;
        my $fh;
        unless (open $fh, "<", $f) {
            $log->error("Can't open file `$f`: $!, skipped");
            next;
        }
        my $ctx = Digest::MD5->new;
        $ctx->addfile($fh);
        my $digest = $ctx->hexdigest;
        $digest_counts{$digest}++;
        $file_digests{$f} = $digest;
    }

    my %file_counts; # key = file name, value = num of files having file content
    for my $f (@$files) {
        next unless defined $file_sizes{$f};
        if (!defined($file_digests{$f})) {
            $file_counts{$f} = 1;
        } else {
            $file_counts{$f} = $digest_counts{ $file_digests{$f} };
        }
    }

    if ($count) {
        return [200, "OK", \%file_counts];
    } else {
        my @files;
        for (sort keys %file_counts) {
            if ($file_counts{$_} == 1) {
                push @files, $_ if $report_unique;
            } else {
                push @files, $_ if $report_duplicate;
            }
        }
        return [200, "OK", \@files];
    }
}

1;
#ABSTRACT: Report or omit duplicate file contents


=pod

=head1 NAME

App::UniqFiles - Report or omit duplicate file contents

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 # See uniq-files script

=head1 DESCRIPTION

=head1 FUNCTIONS

None are exported, but they are exportable.

=head2 uniq_files(%args) -> [STATUS_CODE, ERR_MSG, RESULT]


Report or omit duplicate file contents.

Given a list of filenames, will check each file size and content for duplicate
content. Interface is a bit like the `uniq` Unix command-line program.

Returns a 3-element arrayref. STATUS_CODE is 200 on success, or an error code
between 3xx-5xx (just like in HTTP). ERR_MSG is a string containing error
message, RESULT is the actual result.

Arguments (C<*> denotes required arguments):

=over 4

=item * B<files>* => I<array>

=item * B<count> => I<bool> (default C<0>)

Return each file content's number of occurence.

1 means the file content is only encountered once (unique), 2 means there is one
duplicate, and so on.

=item * B<report_duplicate> => I<bool> (default C<0>)

Aliases: B<d> (Alias for --noreport-unique --report-duplicate)

Return duplicate items.

=item * B<report_unique> => I<bool> (default C<1>)

Aliases: B<u> (Alias for --report-unique --noreport-duplicate)

Return unique items.

=back

=head1 TODO

=over 4

=item * Handle symlinks

Provide options on how to handle symlinks: ignore them? Follow?

=item * Handle special files (socket, pipe, device)

Ignore them.

=item * Check hardlinks/inodes first

For fast checking.

=item * Arguments hash_skip_bytes & hash_bytes

For only checking uniqueness against parts of contents.

=item * Arguments hash_module/hash_method/hash_sub

For doing custom hashing instead of Digest::MD5.

=back

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

