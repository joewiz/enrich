# enrich

REST services for eXist that OpenRefine can call to enrich hsg-bound data

See https://github.com/HistoryAtState/hsg-project/wiki/Preparing-Travels-and-Visits.

To install:

1. Clone this repository onto your computer, e.g., `~/workspace/enrich`
2. Open Terminal, and change into the directory where you cloned the repository, e.g., `cd ~/workspace/enrich`
3. Build the EXPath application package by typing `ant`. This builds the `enrich.xar` file and deposits it into the `build` subdirectory of the cloned repository.
4. Install this app into eXist via the Dashboard > Package Manager (http://localhost:8080/exist/apps/dashboard/index.html).

Once installed, you'll be able to use the OpenRefine services described in the "Preparing Travels and Visits" directions above.
