#!/usr/bin/env perl


use strict;


my \$outdir = "gsea_results";

#- GSEA default parameters listed in \$outdir/gsea.GseaPreranked.XXX/YYY.rpt
my \$gsea = "/Users/lconde/Downloads/GSEA_4.3.3";
my \$runstr="\$gsea/gsea-cli.sh GSEAPreranked";
\$runstr.=" -rnk $RNK -gmx $GMT";
\$runstr.=" -set_max $MAXSET -set_min $MINSET -nperm $PERM";
\$runstr.=" -out \$outdir";
`\$runstr`;

my @results = glob ("\$outdir/*GseaPreranked*");

my \$runstr2="\$gsea/gsea-cli.sh LeadingEdgeTool";
\$runstr2.=" -enrichment_zip \$results[0]"; #- enrichment_zip does not do anything, but it is required
\$runstr2.=" -dir \$results[0]";
\$runstr2.=" -out \$outdir";
\$runstr2.=" -extraPlots TRUE";
`\$runstr2`;

open(OUTF, ">gsea_table.txt");
print OUTF "RANK\\tGENESET\\tGENESET_ORIGINAL_SIZE\\tGENESET_SIZE_IN_DATA\\tLEADING_EDGE_GENES\\tRATIO\\tRATIO_ORIGINAL_SIZE\\tFDR_p\\tNES\\n";

#- orioginal geneset sizes
my %originalsize=();
open(INF, "\$results[0]/gene_set_sizes.tsv") || die "\\n\\nERROR: \$! \$results[0]/gene_set_sizes.tsv\\n";
while(<INF>){
	chomp \$_;
	my @a=split("\t",\$_);
	(\$a[0] eq 'NAME') && next;
	\$originalsize{\$a[0]}=\$a[1];
}
close(INF);
opendir(D, "\$results[0]");
my @files2= grep { /.tsv\$/ && /^gsea_report_for_na/} readdir (D);
foreach my \$file(@files2){
	open(INF, "\$results[0]/\$file") || die "\\n\\nERROR: \$! \$results[0]/\$file\\n";
	while(<INF>){
		chomp \$_;
		my @a=split("\t",\$_);
		(\$a[0] eq 'NAME') && next;

		(!-e "\$results[0]/\$a[0].tsv") && next;

		my \$count=0;
		open(INF2, "\$results[0]/\$a[0].tsv") || die "\\n\\nERROR: \$! \$results[0]/\$a[0].tsv\\n";
		while(<INF2>){
			chomp \$_;
			my @a=split("\t",\$_);
			(\$a[0] eq 'NAME') && next;

			if(\$a[7] eq 'Yes'){
				\$count++;
			}
		}
		close(INF2);
		my \$ratio=sprintf("%.2f", \$count/\$a[3]);
		my \$ratiooriginal=sprintf("%.2f", \$count/\$originalsize{\$a[0]});
		print OUTF "${meta.id}"."\\t".\$a[0]."\\t".\$originalsize{\$a[0]}."\\t".\$a[3]."\\t".\$count."\\t".\$ratio."\\t".\$ratiooriginal."\\t".\$a[7]."\\t".\$a[5]."\\n";
	}
	close(INF);
}
closedir(D);


#---------------
#- Save versions
#---------------
# print to yml file
open (OUTF, ">versions.yml");
print OUTF "GSEA:\\n";
print OUTF "  GSEA version: $VERSION\\n";
close(OUTF);

