#=====================================================================
#
# Tax support module for LedgerSMB
# LedgerSMB::Tax
#  Default simple tax application
#
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License
# Version 2 or, at your option, any later version.  See COPYRIGHT file for
# details.
#
#
#======================================================================
# This package contains tax related functions:
#
# apply_taxes - applies taxes to the given subtotal
# extract_taxes - extracts taxes from the given total
# initialize_taxes - loads taxes from the database
# calculate_taxes - calculates taxes
#
#====================================================================
package Tax;

use Math::BigFloat;
use Log::Log4perl;

my $logger = Log::Log4perl->get_logger('Tax');

sub init_taxes {
    my ( $form, $taxaccounts, $taxaccounts2 ) = @_;
    my $dbh = $form->{dbh};
    @taxes = ();
    my @accounts = split / /, $taxaccounts;
    if ( defined $taxaccounts2 ) {
        #my @tmpaccounts = @accounts;#unused var
        $#accounts = -1;# empty @accounts,@accounts=();
        for my $acct ( split / /, $taxaccounts2 ) {
            if ( $taxaccounts =~ /\b$acct\b/ ) {
                push @accounts, $acct;
            }
        }
    }
    else{
     $logger->trace("taxaccounts2 undefined");
    }
    my $query = qq|
		SELECT t.taxnumber, c.description,
			t.rate, t.chart_id, t.pass, m.taxmodulename, t.minvalue
			FROM tax t INNER JOIN chart c ON (t.chart_id = c.id)
			INNER JOIN taxmodule m 
				ON (t.taxmodule_id = m.taxmodule_id)
			WHERE c.accno = ? 
		              AND coalesce(validto::timestamp, 'infinity') 
		                  >= coalesce(?::timestamp, now())
			ORDER BY validto ASC
			LIMIT 1
		|;
    my $sth = $dbh->prepare($query);
    foreach $taxaccount (@accounts) {
        next if ( !defined $taxaccount );
        if ( defined $taxaccounts2 ) {
            next if $taxaccounts2 !~ /\b$taxaccount\b/;
        }
        $sth->execute($taxaccount, $form->{transdate}) || $form->dberror($query);
        my $ref = $sth->fetchrow_hashref;

        my $module = $ref->{'taxmodulename'};
        require "LedgerSMB/Taxes/${module}.pm";
        $module =~ s/\//::/g;
        my $tax = ( eval 'Taxes::' . $module )->new();

        $tax->pass( $ref->{'pass'} );
        $tax->account($taxaccount);
        $tax->rate( Math::BigFloat->new( $ref->{'rate'} ) );
        $tax->taxnumber( $ref->{'taxnumber'} );
        $tax->chart( $ref->{'chart'} );
        $tax->description( $ref->{'description'} );
        $tax->value( Math::BigFloat->bzero() );
        $tax->minvalue(Math::BigFloat->new($ref->{'minvalue'} || 0));
        $tax->maxvalue(Math::BigFloat->new($ref->{'maxvalue'} || 0));

        push @taxes, $tax;
        $sth->finish;#should this not be out of foreach loop?, to examine
    }
    return @taxes;
}

sub calculate_taxes {
    my ( $taxes, $form, $subtotal, $extract ) = @_;
    my $total = Math::BigFloat->bzero();
    my %passes;
    foreach my $tax (@taxes) {
        push @{ $passes{ $tax->pass } }, $tax;
    }
    my @passkeys = sort keys %passes;
    @passkeys = reverse @passkeys if $extract;
    foreach my $pass (@passkeys) {
        my $passrate  = Math::BigFloat->bzero();
        my $passtotal = Math::BigFloat->bzero();
        foreach my $tax ( @{ $passes{$pass} } ) {
            $passrate += $tax->rate;
        }
        foreach my $tax ( @{ $passes{$pass} } ) {
            $passtotal += $tax->apply_tax( $form, $subtotal + $total )
              if not $extract;
            $passtotal +=
              $tax->extract_tax( $form, $subtotal - $total, $passrate )
              if $extract;
        }
        $total += $passtotal;
    }
    return $total;
}

sub apply_taxes {
    my ( $taxes, $form, $subtotal ) = @_;
    return $subtotal + calculate_taxes( $taxes, $form, $subtotal, 0 );
}

sub extract_taxes {
    my ( $taxes, $form, $subtotal ) = @_;
    return $subtotal - calculate_taxes( $taxes, $form, $subtotal, 1 );
}

1;
