# This is a test for module JSON::Create.

use warnings;
use strict;
use Test::More;
use JSON::Create 'create_json';
use JSON::Parse 'valid_json';
my %hash = ('a' => 'b');
my $json_hash = create_json (\%hash);
is ($json_hash, '{"a":"b"}', "json simple hash OK");
my $hashhash = {a => {b => 'c'}, d => {e => 'f'}};
my $json_hashhash = create_json ($hashhash);
ok (valid_json ($json_hashhash), "json nested hash valid");
like ($json_hashhash, qr/"a":{"b":"c"}/, "json nested hash OK part 1");
like ($json_hashhash, qr/"d":{"e":"f"}/, "json nested hash OK part 2");

# Arrays

my $array = ['there', 'is', 'no', 'other', 'day'];
my $json_array = create_json ($array);
is ($json_array, '["there","is","no","other","day"]', "flat array JSON correct");
my $nested_array = ['let\'s', ['try', ['it', ['another', ['way']]]]];
my $json_nested_array = create_json ($nested_array);
ok (valid_json ($json_nested_array), "Nested array JSON valid");
is ($json_nested_array, '["let\'s",["try",["it",["another",["way"]]]]]', "Nested array JSON correct");

SKIP: {
    # https://metacpan.org/source/JKEENAN/ExtUtils-ModuleMaker-0.54/t/03_quick.t#L15
    eval {
	require 5.012_000;
    };
    if ($@) {
	skip "Regex serialization not available for Perl < 5.12";
    }
    my $rx = qr/See+ Emily play/;
    my $rx_json = create_json ($rx);
    ok (valid_json ($rx_json), "regex JSON valid");
    # "stringified" regexes are different on different Perls.
    # http://www.cpantesters.org/cpan/report/bf3447c2-744c-11e5-9c9f-1c89e0bfc7aa
    like ($rx_json, qr/See\+ Emily play/, "regex JSON as expected");
};

my $numbers = [1,2,3,4,5,6];
my $numbers_json = create_json ($numbers);
is ($numbers_json, '[1,2,3,4,5,6]', "simple integers");
my $fnumbers = [0.5,0.25];
my $fnumbers_json = create_json ($fnumbers);
is ($fnumbers_json, '[0.5,0.25]', "round floating point numbers");

#my $code = sub {print "She's often inclined to borrow somebody's dreams till tomorrow"};
#print $code;
#my $json_code = create_json ($code);
#print $json_code;

# Undefined should give us the bare value "null".
run (undef, 'null');
run ({'a' => undef},'{"a":null}');

# The following tests the SVt_PVMG code path

# When UTF-8 validation is added, this will change to use utf8, but at
# the moment the module doesn't validate Unicode inputs so it cannot
# be so. Switching the UTF-8 flags on and off within a module requires
# the module author to independently do full-blown UTF-8 validation on
# everything (!).

no utf8;

package Ba::Bi::Bu::Be::Bo;

sub new
{
    my $lion = 'ライオン';
    return bless \$lion;
}

package main;

my $babibubebo = Ba::Bi::Bu::Be::Bo->new ();
my $zoffixznet = {"babibubebo" => $babibubebo};
run ($zoffixznet, qr/\"ライオン\"/);

done_testing ();
exit;
# Local variables:
# mode: perl
# End:

sub run
{
    my ($input, $test) = @_;
    my $output;
    eval {
	$output = create_json ($input);
    };
#    print "$output\n";
    ok (! $@, "no errors on input");
    ok (valid_json ($output), "output is valid JSON");
    if (ref $test eq 'CODE') {
	&{$test} ($input, $output);
    }
    elsif (ref $test eq 'Regexp') {
	like ($output, $test, "input looks as expected");
    }
    elsif (! defined $test) {
	# skip this test
    }
    else {
	# Assume string
	is ($output, $test, "input is as expected");
    }
    return;
}

