#!/usr/bin/env perl

#
# via: Automating Gorilla And/Or Revigo Analysis
#
# Downloads the figures and the Excel file
# If the Excel download fails it downloads the txt file instead
# https://www.biostars.org/p/70064/
#
# Make GOrilla perl virtual env.
#/home/joppelt/tools/perl-virtualenv/virtualenv.pl gorilla
#source gorilla/bin/activate
#which cpanm
#cpanm File::Path
#cpanm WWW::Mechanize
#cpanm Getopt::Long
#

use strict;
use warnings;

use File::Path;
use WWW::Mechanize;
use Getopt::Long;

my $GOrillaURL = "http://cbl-gorilla.cs.technion.ac.il/";

my @organisms = qw(ARABIDOPSIS_THALIANA
           SACCHAROMYCES_CEREVISIAE
           CAENORHABDITIS_ELEGANS
           DROSOPHILA_MELANOGASTER
           DANIO_RERIO
           HOMO_SAPIENS
           MUS_MUSCULUS
           RATTUS_NORVEGICUS
         );
my %organisms; @organisms{@organisms} = (1) x @organisms;
my $organism = "HOMO_SAPIENS";

my @runmodes = qw(mhg hg);
my %runmodes; @runmodes{@runmodes} = (1) x @runmodes;
my $runmode = "mhg";

my @ontologies = qw(proc func comp all);
my %ontologies; @ontologies{@ontologies} = (1) x @ontologies;
my $ontology = "all";

my $pvalue = "0.001";
my $name = "";
my $email = "";
my $includedups = 0;
my $revigo = 1;
my $fast = 1;
my ($targets, $background, $outputDir);

my $result = GetOptions("organism=s" => \$organism,
                "runmode=s" => \$runmode,
                "targets=s" => \$targets,
                "background=s" => \$background,
                "ontology=s" => \$ontology,
                "pvalue=f" => \$pvalue,
                "name=s" => \$name,
                "email=s" => \$email,
                "includedups!" => \$includedups,
                "fast!" => \$fast,
                "outputdir=s" => \$outputDir,
               );

die "No such organism $organism\n" unless $organisms{$organism};
die "No such runmode $runmode\n" unless $runmodes{$runmode};
die "No such ontology $ontology\n" unless $ontologies{$ontology};

die "Must supply both target and background files with runmode hg\n"
	unless ($runmode eq "mhg" || ($targets && $background));

die "Must supply target file with runmode mhg\n"
	unless ($runmode eq "hg" || $targets);

die "No output directory specified\n" unless $outputDir;
if (! -d $outputDir) { mkpath $outputDir; }

my $mech = WWW::Mechanize->new();

$mech->get($GOrillaURL);

$mech->form_name("gorilla");

$mech->select("species" => $organism);
$mech->set_fields("run_mode" => $runmode);
$mech->set_fields("target_file_name" => $targets);
if ($runmode eq "hg") {
#    $mech->set_file("background_file_name" => $background);
    $mech->set_fields("background_file_name" => $background);
}
$mech->set_fields("db" => $ontology);
$mech->select("pvalue_thresh" => $pvalue);
$mech->set_fields("analysis_name" => $name);
$mech->set_fields("user_email" => $email);
$mech->set_fields("output_excel" => 1);
$mech->set_fields("output_unresolved" => $includedups);
$mech->set_fields("output_revigo" => $revigo);
$mech->set_fields("fast_mode" => $fast);

$mech->click("run_gogo_button");

my $res = $mech->response();
my $base =  $res->base();
my ($id) = $base =~ m/id=(.*)/;

print STDERR "Results can be found at: http://cbl-gorilla.cs.technion.ac.il/GOrilla/${id}/GOResults.html\n";

do $mech->get($base)
    until $mech->response->base() ne $base;

my %pages = (proc => "PROCESS",
         func => "FUNCTION",
         comp => "COMPONENT");

my @pages = $ontology eq "all" ? values(%pages) : $pages{$ontology};

for my $page (@pages) {
    print STDERR "trying to retrieve ${page} records...\n";
    my $excelUri = "${GOrillaURL}/GOrilla/${id}/GO${page}.xls";
    my $excelFn = "$outputDir/GO${page}.xls";
    my $connected = eval {
#        $mech->get($excel);
		$mech->get($excelUri, ':content_file' => $excelFn);
        1
    };
    if ($mech->success()) {
        my $content = $mech->content();
        my $outputFn = "$outputDir/GO${page}.txt";
        open my $outputFh, ">", $outputFn or die "could not open handle to GO output: $outputFn\n";
        print $outputFh $content;
        close $outputFh;
        my $pngUri = "${GOrillaURL}/GOrilla/${id}/GO${page}.png";
        my $pngFn = "$outputDir/GO${page}.png";
        $mech->get($pngUri, ':content_file' => $pngFn);
    }

    my $resUri = "${GOrillaURL}/GOrilla/${id}/GOResults${page}.html";
    my $resFn = "$outputDir/GOResults${page}.html";
    $mech->get($resUri, ':content_file' => $resFn);
}

print STDERR "trying to retrieve root results record...\n";
my $rootResUri = "${GOrillaURL}/GOrilla/${id}/GOResults.html";
my $rootResFn = "$outputDir/GOResults.html";
$mech->get($rootResUri, ':content_file' => $rootResFn);

print STDERR "trying to retrieve top bar record...\n";
my $topUri = "${GOrillaURL}/GOrilla/${id}/top.html";
my $topFn = "$outputDir/top.html";
$mech->get($topUri, ':content_file' => $topFn);
