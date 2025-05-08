version 1.0

import "../../../tasks/task_versioning.wdl" as versioning


task cat_lanes {
  input {
    String samplename
    
    File read1_lane1
    File read1_lane2
    File? read1_lane3
    File? read1_lane4

    File? read2_lane1
    File? read2_lane2
    File? read2_lane3
    File? read2_lane4

    Int cpu = 2
    Int disk_size = 50
    String docker = "us-docker.pkg.dev/general-theiagen/theiagen/utility:1.2"
    Int memory = 4
  }
  meta {
    volatile: true
  }
  command <<<
    # exit task if anything throws an error (important for proper gzip format)
    set -euo pipefail
    
    exists() { [[ -f $1 ]]; }

    cat ~{read1_lane1} ~{read1_lane2} ~{read1_lane3} ~{read1_lane4} > "~{samplename}_merged_R1.fastq.gz"

    if exists "~{read2_lane1}" ; then
      cat ~{read2_lane1} ~{read2_lane2} ~{read2_lane3} ~{read2_lane4} > "~{samplename}_merged_R2.fastq.gz"
    fi

    # ensure newly merged FASTQs are valid gzipped format
    gzip -t *merged*.gz
  >>>
  output {
    File read1_concatenated = "~{samplename}_merged_R1.fastq.gz"
    File? read2_concatenated = "~{samplename}_merged_R2.fastq.gz"
  }
  runtime {
    docker: "~{docker}"
    memory: memory + " GB"
    cpu: cpu
    disks: "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    preemptible: 1
  }
}

workflow concatenate_illumina_lanes {
  input {
    String samplename
    
    File read1_lane1
    File read1_lane2
    File? read1_lane3
    File? read1_lane4
    
    File? read2_lane1
    File? read2_lane2
    File? read2_lane3
    File? read2_lane4
  }

  call concatenate_lanes.cat_lanes {
    input:
      samplename = samplename,
      read1_lane1 = read1_lane1,
      read2_lane1 = read2_lane1,
      read1_lane2 = read1_lane2,
      read2_lane2 = read2_lane2,
      read1_lane3 = read1_lane3,
      read2_lane3 = read2_lane3,
      read1_lane4 = read1_lane4,
      read2_lane4 = read2_lane4
  }
  
  
  output {
    File read1_concatenated = cat_lanes.read1_concatenated
    File? read2_concatenated = cat_lanes.read2_concatenated
  }
}