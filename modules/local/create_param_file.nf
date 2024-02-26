process CREATE_PARAM_FILE {

    label 'process_single'

    conda "conda-forge::coreutils"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    path(inputdir)
    path(metadata)
    val(design)
    val(condition)
    val(treatment)
    val(control)
    val(pval)
    val(fc)


    output:
    path "deseq2.conf"        , emit: deseq2_conf
    path "versions.yml"       , emit: versions

    when:
    task.ext.when == null || task.ext.when


    script:
    def args = task.ext.args ?: ''
    """
    cat <<-EOF > deseq2.conf
    [deseq2]

    INPUTDIR = $inputdir
    METADATA = $metadata
    DESIGN = $design
    CONDITION = $condition
    TREATMENT = $treatment
    CONTROL = $control
    PVAL = $pval
    FC = $fc
    EOF

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}

