#!/usr/bin/perl

use strict;
use warnings;

$ENV{TMPDIR} = 't/var';

#use Test::More 'no_plan';
use Test::More tests => 1172;
use Test::Trap qw(trap $trap);
use Math::BigFloat;

use LedgerSMB;
use LedgerSMB::Form;

my $lsmb_nan_message = "Content-Type: text/html; charset=utf-8\n\n<head><link rel='stylesheet' href='css/' type='text/css'></head><body><h2 class=\"error\">Error!</h2> <p><b>Invalid number detected during parsing</b></body>";
my $form_nan_message = '<body><h2 class="error">Error!</h2> <p><b>Invalid number detected during parsing</b></body>';
my @r;
my $form = new Form;
my %myconfig;
ok(defined $form);
isa_ok($form, 'Form');
my $lsmb = new LedgerSMB;
ok(defined $lsmb);
isa_ok($lsmb, 'LedgerSMB');

my $expected;
foreach my $value ('0.01', '0.05', '0.015', '0.025', '1.1', '1.5', '1.9', 
		'10.01', '4', '5', '5.1', '5.4', '5.5', '5.6', '6', '0', 
		'0.000', '10.155', '55', '0.001', '14.5', '15.5', '4.5') {
	foreach my $places ('3', '2', '1', '0') {
		Math::BigFloat->round_mode('+inf');
		$expected = Math::BigFloat->new($value)->ffround(-$places);
		$expected->precision(undef);
		is($form->round_amount($value, $places), $expected,
			"form: $value to $places decimal places - $expected");
		is($lsmb->round_amount($value, $places), $expected,
			"lsmb: $value to $places decimal places - $expected");

		Math::BigFloat->round_mode('-inf');
		$expected = Math::BigFloat->new(-$value)->ffround(-$places);
		$expected->precision(undef);
		is($form->round_amount(-$value, $places), $expected,
			"form: -$value to $places decimal places - $expected");
		is($lsmb->round_amount(-$value, $places), $expected,
			"lsmb: -$value to $places decimal places - $expected");
	}
	foreach my $places ('-1', '-2') {
		Math::BigFloat->round_mode('+inf');
		$expected = Math::BigFloat->new($value)->ffround(-($places-1));
		is($form->round_amount($value, $places), $expected,
			"form: $value to $places decimal places - $expected");
		is($lsmb->round_amount($value, $places), $expected,
			"lsmb: $value to $places decimal places - $expected");

		Math::BigFloat->round_mode('-inf');
		$expected = Math::BigFloat->new(-$value)->ffround(-($places-1));
		is($form->round_amount(-$value, $places), $expected,
			"form: -$value to $places decimal places - $expected");
		is($lsmb->round_amount(-$value, $places), $expected,
			"lsmb: -$value to $places decimal places - $expected");
	}
}

# TODO Number formatting still needs work for l10n
my @formats = (['1,000.00', ',', '.'], ["1'000.00", "'", '.'], 
		['1.000,00', '.', ','], ['1000,00', '', ','], 
		['1000.00', '', '.'], ['1 000.00', ' ', '.']);
my %myfooconfig = (numberformat => '1000.00');
foreach my $format (0 .. $#formats) {
	%myconfig = (numberformat => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34', '0d00') {
		$expected = $rawValue;
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
		##$value = Math::BigFloat->new($value);
		$value = $form->parse_amount(\%myfooconfig,$value);
		is($form->format_amount(\%myconfig, $value, 2, '0'), $expected,
			"form: $value formatted as $formats[$format][0] - $expected");
		is($lsmb->format_amount('user' => \%myconfig, 
			'amount' => $value, 'precision' => 2, 
			'neg_format' => '0'), $expected,
			"lsmb: $value formatted as $formats[$format][0] - $expected");
	}
}

foreach my $format (0 .. $#formats) {
	%myconfig = (numberformat => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34', '0d00', '0') {
		$expected = $rawValue;
		if ($expected eq '0'){
			$expected = '0d00';
                }
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
		##$value = Math::BigFloat->new($value);
		$LedgerSMB::Sysconfig::decimal_places = 2;
		$value = $lsmb->parse_amount(user =>\%myfooconfig, 
			amount =>$value);
		is($form->format_amount(\%myconfig, $value, 2, '0'), $expected,
			"form: $value formatted as $formats[$format][0] - $expected");
		is($lsmb->format_amount('user' => \%myconfig, 
			'amount' => $value, 'money' => 1, 
			'neg_format' => '0'), $expected,
			"lsmb(money): $value formatted as $formats[$format][0] - $expected");
	}
}

foreach my $format (0 .. $#formats) {
	%myconfig = (numberformat => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34', '0d00') {
		$expected = $rawValue;
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
                my $val2 = $value;
		##$value = Math::BigFloat->new($value);
		$value = $form->parse_amount(\%myfooconfig,$value);
		my $value2 = $lsmb->parse_amount(user => \%myfooconfig, amount => $val2);
		is($form->format_amount(\%myconfig, $value, 2, '0'), $expected,
			"form: $value formatted as $formats[$format][0] - $expected");
		is($lsmb->format_amount('user' => \%myconfig, 
			'amount' => $value2, 'precision' => 2, 
			'neg_format' => '0'), $expected,
			"lsmb: $value formatted as $formats[$format][0] - $expected");
	}
}

foreach my $format (0 .. $#formats) {
	%myconfig = (numberformat => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	my $rawValue = '6d00';
	$expected = $rawValue;
	$expected =~ s/d/$dec/gx;
	my $value = $form->parse_amount(\%myfooconfig, '6');
	is($form->format_amount(\%myconfig, $value, 2, '0'), $expected,
		"form: $value formatted as $formats[$format][0] - $expected");
	is($lsmb->format_amount('user' => \%myconfig, 
		'amount' => $value, 'precision' => 2, 
		'neg_format' => '0'), $expected,
		"lsmb: $value formatted as $formats[$format][0] - $expected");
}

$expected = $form->parse_amount({'numberformat' => '1000.00'}, '0.00');
is($form->format_amount({'numberformat' => '1000.00'} , $expected, 2, 'x'), 'x',
	"form: 0.00 with dash x");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => $expected, 'precision' => 2, 
	'neg_format' => 'x'), '0.00',
	"lsmb: 0.00 with dash x");
is($form->format_amount({'numberformat' => '1000.00'} , $expected, 2, ''), '',
	"form: 0.00 with dash ''");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => $expected, 'precision' => 2, 
	'neg_format' => ''), '0.00',
	"lsmb: 0.00 with dash ''");
is($form->format_amount({'numberformat' => '1000.00'} , $expected, 2), '',
	"form: 0.00 with undef dash");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => $expected, 'precision' => 2), '0.00',
	"lsmb: 0.00 with undef dash");
$ENV{GATEWAY_INTERFACE} = 'yes';
$form->{pre} = 'Blah';
$form->{header} = 'Blah';
@r = trap{$form->format_amount({'apples' => '1000.00'}, 'foo', 2)};
is($trap->exit, undef,
	'form: No numberformat set, invalid amount (NaN check)');
is($trap->stdout, $form_nan_message,
	'form: No numberformat set, invalid amount message (NaN check)');
@r = trap{$lsmb->format_amount('user' => {'apples' => '1000.00'},
	'amount' => 'foo', 'precision' => 2)};
is($trap->exit, 0,
	'lsmb: No numberformat set, invalid amount (NaN check)');
is($trap->stdout, $lsmb_nan_message,
	'lsmb: No numberformat set, invalid amount message (NaN check)');
cmp_ok($form->format_amount({'apples' => '1000.00'} , '1.00', 2), '==', 1,
	"form: No numberformat set, valid amount");
cmp_ok($lsmb->format_amount('user' => {'apples' => '1000.00'}, 
	'amount' => '1.00', 'precision' => 2), '==', 1,
	"lsmb: No numberformat set, valid amount");
is($form->format_amount({'numberformat' => '1000.00'} , '-1.00', 2, '-'), '(1.00)',
	"form: -1.00 with dash '-'");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => '-1.00', 'precision' => 2, 'neg_format' => '-'), '(1.00)',
	"lsmb: -1.00 with dash '-'");
is($form->format_amount({'numberformat' => '1000.00'} , '1.00', 2, '-'), '1.00',
	"form: 1.00 with dash '-'");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => '1.00', 'precision' => 2, 'neg_format' => '-'), '1.00',
	"lsmb: 1.00 with dash '-'");
is($form->format_amount({'numberformat' => '1000.00'} , '-1.00', 2, 'DRCR'), 
	'1.00 DR', "form: -1.00 with dash DRCR");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => '-1.00', 'precision' => 2, 'neg_format' => 'DRCR'), 
	'1.00 DR', "lsmb: -1.00 with dash DRCR");
is($form->format_amount({'numberformat' => '1000.00'} , '1.00', 2, 'DRCR'), 
	'1.00 CR', "form: 1.00 with dash DRCR");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => '1.00', 'precision' => 2, 'neg_format' => 'DRCR'), 
	'1.00 CR', "lsmb: 1.00 with dash DRCR");
is($form->format_amount({'numberformat' => '1000.00'} , '-1.00', 2, 'x'), '-1.00',
	"form: -1.00 with dash 'x'");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => '-1.00', 'precision' => 2, 'neg_format' => 'x'), '-1.00',
	"lsmb: -1.00 with dash 'x'");
is($form->format_amount({'numberformat' => '1000.00'} , '1.00', 2, 'x'), '1.00',
	"form: 1.00 with dash 'x'");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => '1.00', 'precision' => 2, 'neg_format' => 'x'), '1.00',
	"lsmb: 1.00 with dash 'x'");

# Triggers the $amount .= "\.$dec" if ($dec ne ""); check to false
is($form->format_amount({'numberformat' => '1000.00'} , '1.00'), '1',
	"form: 1.00 with no precision or dash (1000.00)");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => '1.00'), '1',
	"lsmb: 1.00 with no precision or dash (1000.00)");
is($form->format_amount({'numberformat' => '1,000.00'} , '1.00'), '1',
	"form: 1.00 with no precision or dash (1,000.00)");
is($lsmb->format_amount('user' => {'numberformat' => '1,000.00'}, 
	'amount' => '1.00'), '1',
	"lsmb: 1.00 with no precision or dash (1,000.00)");
is($form->format_amount({'numberformat' => '1 000.00'} , '1.00'), '1',
	"form: 1.00 with no precision or dash (1 000.00)");
is($lsmb->format_amount('user' => {'numberformat' => '1 000.00'}, 
	'amount' => '1.00'), '1',
	"lsmb: 1.00 with no precision or dash (1 000.00)");
is($form->format_amount({'numberformat' => '1\'000.00'} , '1.00'), '1',
	"form: 1.00 with no precision or dash (1'000.00)");
is($lsmb->format_amount('user' => {'numberformat' => '1\'000.00'}, 
	'amount' => '1.00'), '1',
	"lsmb: 1.00 with no precision or dash (1'000.00)");
is($form->format_amount({'numberformat' => '1.000,00'} , '1,00'), '1',
	"form: 1,00 with no precision or dash (1.000,00)");
is($lsmb->format_amount('user' => {'numberformat' => '1.000,00'}, 
	'amount' => '1,00'), '1',
	"lsmb: 1,00 with no precision or dash (1.000,00)");
is($form->format_amount({'numberformat' => '1000,00'} , '1,00'), '1',
	"form: 1,00 with no precision or dash (1000,00)");
is($lsmb->format_amount('user' => {'numberformat' => '1000,00'}, 
	'amount' => '1,00'), '1',
	"lsmb: 1,00 with no precision or dash (1000,00)");
is($form->format_amount({'numberformat' => '1000.00'} , '1.50'), '1.5',
	"form: 1.50 with no precision or dash");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => '1.50'), '1.5',
	"lsmb: 1.50 with no precision or dash");
is($form->format_amount({'numberformat' => '1000.00'} , '0.0', undef, '0'), '0',
	"form: 0.0 with no precision, dash '0'");
is($lsmb->format_amount('user' => {'numberformat' => '1000.00'}, 
	'amount' => '0.0', 'neg_format' => '0'), '0',
	"lsmb: 0.0 with no precision, dash '0'");

foreach my $format (0 .. $#formats) {
	%myconfig = (numberformat => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34') {
		$expected = $rawValue;
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
		#my $ovalue = $value;
		$value = $form->parse_amount(\%myfooconfig,$value);
		#$value = $form->parse_amount(\%myconfig,$value);
		is($form->format_amount(\%myconfig, 
			$form->format_amount(\%myconfig, $value, 2, 'x'), 
			2, 'x'), $expected, 
			"form: Double formatting of $value as $formats[$format][0] - $expected");
		is($lsmb->format_amount('user' => \%myconfig, 
			'amount' => 
				$lsmb->format_amount('user' => \%myconfig, 
				'amount' => $value, 
				'precision' => 2, 
				'neg_format' => 'x'), 
			'precision' => 2, 'neg_format' => 'x'), $expected, 
			"lsmb: Double formatting of $value as $formats[$format][0] - $expected");
	}
}

foreach my $format (0 .. $#formats) {
	%myconfig = ('numberformat' => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34', '(76t543d21)') {
		$expected = $rawValue;
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
		if ($value =~ m/^\(/gx) {
			$value = Math::BigFloat->new('-'.substr($value, 1, -1));
		} else {
			$value = Math::BigFloat->new($value);
		}
		cmp_ok($form->parse_amount(\%myconfig, $expected), '==',  $value,
			"form: $expected parsed as $formats[$format][0] - $value");
		cmp_ok($lsmb->parse_amount('user' => \%myconfig, 
			'amount' => $expected), '==',  $value,
			"lsmb: $expected parsed as $formats[$format][0] - $value");
	}
	$expected = '12 CR';
	my $value = Math::BigFloat->new('12');
	cmp_ok($form->parse_amount(\%myconfig, $expected), '==',  $value,
		"form: $expected parsed as $formats[$format][0] - $value");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => $expected),
		'==',  $value,
		"lsmb: $expected parsed as $formats[$format][0] - $value");
	$expected = '21 DR';
	$value = Math::BigFloat->new('-21');
	cmp_ok($form->parse_amount(\%myconfig, $expected), '==',  $value,
		"form: $expected parsed as $formats[$format][0] - $value");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => $expected),
		'==',  $value,
		"lsmb: $expected parsed as $formats[$format][0] - $value");
	
	cmp_ok($form->parse_amount(\%myconfig, ''), '==', 0,
		"form: Empty string returns 0");
	@r = trap{$form->parse_amount(\%myconfig, 'foo')};
	is($trap->exit, undef,
		'form: Invalid string does not exit');
	is($trap->stdout, $form_nan_message,
		'form: Invalid string gives NaN message');
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => ''), '==', 0,
		"lsmb: Empty string returns 0");
	@r = trap{$lsmb->parse_amount('user' => \%myconfig, 'amount' => 'foo')};
	is($trap->exit, 0,
		'lsmb: Invalid string gives NaN exit');
	is($trap->stdout, $lsmb_nan_message,
		'lsmb: Invalid string gives NaN message');
}

foreach my $format (0 .. $#formats) {
	%myconfig = ('numberformat' => $formats[$format][0]);
	my $thou = $formats[$format][1];
	my $dec = $formats[$format][2];
	foreach my $rawValue ('10t000d00', '9t999d99', '333d33', 
			'7t777t777d77', '-12d34', '(76t543d21)') {
		$expected = $rawValue;
		$expected =~ s/t/$thou/gx;
		$expected =~ s/d/$dec/gx;
		my $value = $rawValue;
		$value =~ s/t//gx;
		$value =~ s/d/\./gx;
		if ($value =~ m/^\(/gx) {
			$value = Math::BigFloat->new('-'.substr($value, 1, -1));
		} else {
			$value = Math::BigFloat->new($value);
		}
		cmp_ok($form->parse_amount(\%myconfig, 
			$form->parse_amount(\%myconfig, $expected)),
			'==',  $value,
			"form: $expected parsed as $formats[$format][0] - $value");
		cmp_ok($lsmb->parse_amount('user' => \%myconfig, 
			'amount' => $lsmb->parse_amount('user' => \%myconfig, 
				'amount' => $expected)),
			'==',  $value,
			"lsmb: $expected parsed as $formats[$format][0] - $value");
	}
	$expected = '12 CR';
	my $value = Math::BigFloat->new('12');
	cmp_ok($form->parse_amount(\%myconfig, 
		$form->parse_amount(\%myconfig, $expected)),
		'==',  $value,
		"form: $expected parsed as $formats[$format][0] - $value");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 
		'amount' => $lsmb->parse_amount('user' => \%myconfig, 
			'amount' => $expected)),
		'==',  $value,
		"lsmb: $expected parsed as $formats[$format][0] - $value");
	$expected = '21 DR';
	$value = Math::BigFloat->new('-21');
	cmp_ok($form->parse_amount(\%myconfig, 
		$form->parse_amount(\%myconfig, $expected)),
		'==',  $value,
		"form: $expected parsed as $formats[$format][0] - $value");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 
		'amount' => $lsmb->parse_amount('user' => \%myconfig, 
			'amount' => $expected)),
		'==',  $value,
		"lsmb: $expected parsed as $formats[$format][0] - $value");

	cmp_ok($form->parse_amount(\%myconfig, ''), '==', 0,
		"form: Empty string returns 0");
	cmp_ok($form->parse_amount(\%myconfig), '==', 0,
		"form: undef string returns 0");
	@r = trap{$form->parse_amount(\%myconfig, 'foo')};
	is($trap->exit, undef,
		'form: Invalid string gives NaN exit');
	is($trap->stdout, $form_nan_message,
		'form: Invalid string gives NaN message');
	cmp_ok($lsmb->parse_amount('user' => \%myconfig), '==', 0,
		"lsmb: undef string returns 0");
	cmp_ok($lsmb->parse_amount('user' => \%myconfig, 'amount' => ''), '==', 0,
		"lsmb: Empty string returns 0");
	@r = trap{$lsmb->parse_amount('user' => \%myconfig, 'amount' => 'foo')};
	is($trap->exit, 0,
		'lsmb: Invalid string gives NaN exit');
	is($trap->stdout, $lsmb_nan_message,
		'lsmb: Invalid string gives NaN message');
}
