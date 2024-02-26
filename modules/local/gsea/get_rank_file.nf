
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process GET_RANK_FILE {
    tag { meta.id}
    label 'process_single'

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
        'biocontainers/YOUR-TOOL-HERE' }"

    input:
    tuple val (meta), path (resnorm)

    output:
    tuple val(meta), path("*.rnk")   , emit: rank
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    #!/usr/bin/env perl

    use strict;

    #- READ IN THE FILE AND CALCULATE THE STATISTIC
    my %stats=();
    open(INF, "$resnorm");
    while(<INF>){
        chomp \$_;
        my @a=split("\t",\$_);
        (\$a[0] eq '') && next;

        my \$fc=\$a[2];
        my \$gene=\$a[0];
        my \$pval=\$a[4];

        #- REMOVE P-VALS THAT ARE NA!!! OTHERWISE THEY BECOME -308!!!
        (\$pval eq 'NA') && next;

        if(\$pval == 0 ){
            print \$_."\\n";
            \$pval=10e-308;
        }

        my \$stat;
        if (\$fc>0){
            \$stat = -log(\$pval);
        }else{
            \$stat=(-1) * -log(\$pval);
        }
        \$stats{\$gene}=\$stat;

    }
    close(INF);

    open(OUTF, ">${meta.id}.rnk");
    foreach my \$gene(sort_numerically_by_values(\\%stats)){
        print OUTF \$gene."\\t".\$stats{\$gene}."\\n";
    }
    close(OUTF);

    #---------------
    #- Save versions
    #---------------
    # print to yml file
    open (OUTF, ">versions.yml");
    print OUTF "GET_RANK_FILE:\\n";
    print OUTF "  Perl version: \$^V\\n";
    close(OUTF);


    sub sort_numerically_by_values {
        my \$hs = shift;
        return sort {\$hs->{\$b} <=> \$hs->{\$a}} keys %\$hs;
    }

    """

}
