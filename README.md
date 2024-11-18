# Salmonella_Typhi_JINA
 Scripts for the Jaccard Index Network Analysis (JINA) of Salmonella Typhi

## How to install

### Dependencies
This pipeline consists of a collection of scripts written in bash, python, and perl. Additionally, it utilizes several external programs to perform its tasks. The specific versions used during its development are listed below:

- Bindash 1.0
- Jellyfish 2.2.6

### Installation
Firstly, we need to download the proyect from GitHub:

~~~bash
# Change PROJECT_ROOT_DIRECTORY value to suit your preferences
PROJECT_ROOT_DIRECTORY='Salmonella_Typhi_JINA'
git clone https://github.com/PenilCelis/Salmonella_Typhi_JINA ${PROJECT_ROOT_DIRECTORY}
cd ${PROJECT_ROOT_DIRECTORY}
~~~

Create a conda environment for the dependencies:

~~~bash
conda env create -n typhi_JINA -f typhi_JINA.environment.yml
~~~

### Verify installation
Extract the test sequences and run the pipeline. The pipeline uses 16 threads and computes the JI distances in batches of 32 genomes. The parameters needed are:

#### download test sequences
~~~bash
wget -O test_seqs/test_seqs.tar.xz https://castillo.dicom.unican.es/zaguan/Salmonella_Typhi_JINA/test_seqs.tar.xz
tar -Jxf test_seqs/test_seqs.tar.xz -C test_seqs/
~~~

#### run pipeline
~~~bash
conda activate typhi_JINA
./typhi_JINA_pipeline.sh test_seqs/genome_list.txt test_seqs test_out 16 32
~~~

Explanation of parameters:
- test_seqs/genome_list.txt: Path to the file containing the list of genomes to process.
- test_seqs: Directory where the test sequences are stored.
- test_out: Directory where the output will be saved.
- 16: The number of threads to use for parallel processing.
- 32: The batch size, i.e., the number of genomes to process in each batch.

   
Use Gephi to import the output files required for building the network (```test_out/nodes.tsv``` and ```test_out/edges.tsv```) and filter the edges (```JI >= 0.983``` and ```GLD <= 0.05```). A Gephi file of the test network (```test_network.gephi```) colored by the JI-groups defined in the manuscript is provided. A Gephi file of the Typhi JI network shown in Figure 1 of the manuscript is also supplied (```typhi_network.gephi```).

![Example network](test_network.png)
